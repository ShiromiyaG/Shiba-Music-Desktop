#include "SubsonicClient.h"
#include <set>
#include <QCryptographicHash>
#include <QRandomGenerator>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QSettings>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

static constexpr auto API_VERSION = "1.16.1";   // Navidrome alvo
static constexpr auto CLIENT_NAME = "ShibaMusicQt";
static constexpr int ALBUM_LIST_PAGE_SIZE = 200;
static inline QString ensureNoTrailingSlash(QString s) {
    if (s.endsWith('/')) s.chop(1);
    return s;
}

SubsonicClient::SubsonicClient(QObject *parent) : QObject(parent) { loadRecentlyPlayed(); }

void SubsonicClient::setServerUrl(const QString& url) {
    auto norm = ensureNoTrailingSlash(url.trimmed());
    if (norm == m_server) return;
    m_server = norm;
    emit serverUrlChanged();
}

void SubsonicClient::setUsername(const QString& u) {
    if (u == m_user) return;
    m_user = u;
    emit usernameChanged();
}

QString SubsonicClient::md5(const QString& s) const {
    return QString::fromLatin1(QCryptographicHash::hash(s.toUtf8(), QCryptographicHash::Md5).toHex());
}
QString SubsonicClient::randomSalt() const {
    QByteArray bytes(8, Qt::Uninitialized);
    for (char &c : bytes) c = char(QRandomGenerator::global()->bounded(33, 127));
    return QString::fromLatin1(bytes);
}

QUrl SubsonicClient::buildUrl(const QString& method, const QUrlQuery& extra, bool isJson) const {
    QUrl url(m_server + "/rest/" + method + ".view");
    QUrlQuery q;
    q.addQueryItem("u", m_user);
    q.addQueryItem("v", API_VERSION);
    q.addQueryItem("c", CLIENT_NAME);
    if (isJson) {
        q.addQueryItem("f", "json");
    }
    // auth via token (t/s)
    q.addQueryItem("t", m_token);
    q.addQueryItem("s", m_salt);
    // add extras
    for (auto &item : extra.queryItems())
        q.addQueryItem(item.first, item.second);
    url.setQuery(q);
    return url;
}

bool SubsonicClient::checkOk(const QJsonDocument& doc, QString *err) const {
    auto root = doc.object().value("subsonic-response").toObject();
    if (root.value("status").toString() == "ok") return true;
    if (err) {
        auto e = root.value("error").toObject();
        *err = QString("%1 (code %2)")
                 .arg(e.value("message").toString())
                 .arg(e.value("code").toInt());
    }
    return false;
}

void SubsonicClient::setAuthenticated(bool ok) {
    if (m_authenticated == ok) return;
    m_authenticated = ok;
    emit authenticatedChanged();
}

void SubsonicClient::login(const QString& url, const QString& user, const QString& password) {
    setServerUrl(url);
    setUsername(user);
    m_salt = randomSalt();
    m_token = md5(password + m_salt);

    // ping
    QNetworkRequest req(buildUrl("ping", {}, true));
    auto *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        if (reply->error() != QNetworkReply::NoError) {
            const QString message = reply->errorString();
            reply->deleteLater();
            setAuthenticated(false);
            emit loginFailed(message);
            emit errorOccurred(message);
            return;
        }
        const auto all = reply->readAll();
        reply->deleteLater();
    const auto doc = QJsonDocument::fromJson(all);
    QString err;
    const bool ok = checkOk(doc, &err);
    setAuthenticated(ok);
    if (!ok) {
        const QString message = "Falha no login: " + err;
        emit loginFailed(message);
        emit errorOccurred(message);
        return;
    }
    fetchArtists();
});
}

void SubsonicClient::logout() {
    saveCredentials("", "", "");
    setAuthenticated(false);
    if (!m_artistCover.isEmpty()) {
        m_artistCover.clear();
        emit artistCoverChanged();
    }
}

void SubsonicClient::fetchArtists() {
    if (!m_authenticated) return;
    QNetworkRequest req(buildUrl("getArtists", {}, true));
    auto *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]{
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            reply->deleteLater();
            return;
        }
        const auto doc = QJsonDocument::fromJson(reply->readAll());
        reply->deleteLater();
        QString err;
        if (!checkOk(doc, &err)) { emit errorOccurred(err); return; }

        m_artists.clear();
        auto root = doc.object().value("subsonic-response").toObject();
        auto artists = root.value("artists").toObject().value("index").toArray();
        for (const auto &idxVal : artists) {
            auto idx = idxVal.toObject();
            for (const auto &aVal : idx.value("artist").toArray()) {
                auto a = aVal.toObject();
                QVariantMap m {
                    {"id", a.value("id").toString()},
                    {"name", a.value("name").toString()},
                    {"coverArt", a.value("coverArt").toString()}
                };
                m_artists.push_back(m);
            }
        }
        emit artistsChanged();
    });
}

void SubsonicClient::fetchArtist(const QString& artistId) {
    if (!m_authenticated) return;

    if (m_artistReply) {
        m_artistReply->abort();
    }

    m_albums.clear();
    emit albumsChanged();
    if (!m_tracks.isEmpty()) {
        m_tracks.clear();
        emit tracksChanged();
    }
    if (!m_artistCover.isEmpty()) {
        m_artistCover.clear();
        emit artistCoverChanged();
    }

    QUrlQuery ex; ex.addQueryItem("id", artistId);
    QNetworkRequest req(buildUrl("getArtist", ex, true));
    auto *reply = m_nam.get(req);
    m_artistReply = reply;

    connect(reply, &QNetworkReply::finished, this, [this, reply]{
        if (reply != m_artistReply) {
            reply->deleteLater();
            return;
        }
        m_artistReply = nullptr;

        if (reply->error() != QNetworkReply::NoError) {
            if (reply->error() != QNetworkReply::OperationCanceledError) {
                emit errorOccurred(reply->errorString());
            }
            reply->deleteLater();
            return;
        }

        const auto doc = QJsonDocument::fromJson(reply->readAll());
        reply->deleteLater();
        QString err;
        if (!checkOk(doc, &err)) { emit errorOccurred(err); return; }

        auto root = doc.object().value("subsonic-response").toObject();
        auto artistObj = root.value("artist").toObject();
        const QString newCover = artistObj.value("coverArt").toString();
        if (m_artistCover != newCover) {
            m_artistCover = newCover;
            emit artistCoverChanged();
        }
        auto albums = artistObj.value("album").toArray();
        for (const auto &av : albums) {
            auto a = av.toObject();
            m_albums.push_back(QVariantMap{
                {"id", a.value("id").toString()},
                {"name", a.value("name").toString()},
                {"artistId", a.value("artistId").toString()},
                {"year", a.value("year").toInt()},
                {"coverArt", a.value("coverArt").toString()}
            });
        }
        emit albumsChanged();
    });
}

void SubsonicClient::fetchAlbum(const QString& albumId) {
    if (!m_authenticated) return;

    if (m_albumReply) {
        m_albumReply->abort();
    }

    m_tracks.clear();
    emit tracksChanged();

    QUrlQuery ex; ex.addQueryItem("id", albumId);
    QNetworkRequest req(buildUrl("getAlbum", ex, true));
    auto *reply = m_nam.get(req);
    m_albumReply = reply;

    connect(reply, &QNetworkReply::finished, this, [this, reply]{
        if (reply != m_albumReply) {
            reply->deleteLater();
            return;
        }
        m_albumReply = nullptr;

        if (reply->error() != QNetworkReply::NoError) {
            if (reply->error() != QNetworkReply::OperationCanceledError) {
                emit errorOccurred(reply->errorString());
            }
            reply->deleteLater();
            return;
        }

        const auto doc = QJsonDocument::fromJson(reply->readAll());
        reply->deleteLater();
        QString err;
        if (!checkOk(doc, &err)) { emit errorOccurred(err); return; }

        auto root = doc.object().value("subsonic-response").toObject();
        auto songs = root.value("album").toObject().value("song").toArray();
        for (const auto &sv : songs) {
            auto s = sv.toObject();
            auto rg = s.value("replayGain").toObject();
            m_tracks.push_back(QVariantMap{
                {"id", s.value("id").toString()},
                {"title", s.value("title").toString()},
                {"artist", s.value("artist").toString()},
                {"artistId", s.value("artistId").toString()},
                {"album", s.value("album").toString()},
                {"albumId", s.value("albumId").toString()},
                {"track", s.value("track").toInt()},
                {"duration", s.value("duration").toInt()},
                {"coverArt", s.value("coverArt").toString()},
                {"replayGainTrackGain", rg.value("trackGain").toDouble()},
                {"replayGainAlbumGain", rg.value("albumGain").toDouble()}
            });
        }
        emit tracksChanged();
    });
}

void SubsonicClient::fetchAlbumList(const QString& type) {
    if (!m_authenticated) return;

    if (m_albumListReply) {
        m_albumListReply->abort();
        m_albumListReply->deleteLater();
        m_albumListReply = nullptr;
    }

    m_albumList.clear();
    emit albumListChanged();

    m_pendingAlbumListType = type;
    m_pendingAlbumListOffset = 0;
    m_albumListPaging = true;
    fetchAlbumListPage(type, 0);
}

void SubsonicClient::fetchRandomSongs() {
    if (!m_authenticated) return;

    if (m_randomSongsReply) {
        m_randomSongsReply->abort();
    }

    m_randomSongs.clear();
    emit randomSongsChanged();

    QUrlQuery ex;
    ex.addQueryItem("size", "10");
    QNetworkRequest req(buildUrl("getRandomSongs", ex, true));
    auto *reply = m_nam.get(req);
    m_randomSongsReply = reply;

    connect(reply, &QNetworkReply::finished, this, [this, reply]{
        if (reply != m_randomSongsReply) {
            reply->deleteLater();
            return;
        }
        m_randomSongsReply = nullptr;

        if (reply->error() != QNetworkReply::NoError) {
            if (reply->error() != QNetworkReply::OperationCanceledError) {
                emit errorOccurred(reply->errorString());
            }
            reply->deleteLater();
            return;
        }

        const auto doc = QJsonDocument::fromJson(reply->readAll());
        reply->deleteLater();
        QString err;
        if (!checkOk(doc, &err)) { emit errorOccurred(err); return; }

        auto root = doc.object().value("subsonic-response").toObject();
        auto songs = root.value("randomSongs").toObject().value("song").toArray();
        for (const auto &sv : songs) {
            auto s = sv.toObject();
            auto rg = s.value("replayGain").toObject();
            m_randomSongs.push_back(QVariantMap{
                {"id", s.value("id").toString()},
                {"title", s.value("title").toString()},
                {"artist", s.value("artist").toString()},
                {"artistId", s.value("artistId").toString()},
                {"album", s.value("album").toString()},
                {"albumId", s.value("albumId").toString()},
                {"duration", s.value("duration").toInt()},
                {"coverArt", s.value("coverArt").toString()},
                {"replayGainTrackGain", rg.value("trackGain").toDouble()},
                {"replayGainAlbumGain", rg.value("albumGain").toDouble()}
            });
        }
        emit randomSongsChanged();
    });
}

void SubsonicClient::fetchPlaylists() {
    if (!m_authenticated) return;

    if (m_playlistsReply) {
        m_playlistsReply->abort();
    }

    m_playlists.clear();
    emit playlistsChanged();

    QNetworkRequest req(buildUrl("getPlaylists", {}, true));
    auto *reply = m_nam.get(req);
    m_playlistsReply = reply;

    connect(reply, &QNetworkReply::finished, this, [this, reply]{
        if (reply != m_playlistsReply) {
            reply->deleteLater();
            return;
        }
        m_playlistsReply = nullptr;

        if (reply->error() != QNetworkReply::NoError) {
            if (reply->error() != QNetworkReply::OperationCanceledError) {
                emit errorOccurred(reply->errorString());
            }
            reply->deleteLater();
            return;
        }

        const auto doc = QJsonDocument::fromJson(reply->readAll());
        reply->deleteLater();
        QString err;
        if (!checkOk(doc, &err)) { emit errorOccurred(err); return; }

        auto root = doc.object().value("subsonic-response").toObject();
        auto playlists = root.value("playlists").toObject().value("playlist").toArray();
        for (const auto &pv : playlists) {
            auto p = pv.toObject();
            m_playlists.push_back(QVariantMap{
                {"id", p.value("id").toString()},
                {"name", p.value("name").toString()},
                {"songCount", p.value("songCount").toInt()},
                {"duration", p.value("duration").toInt()},
                {"coverArt", p.value("coverArt").toString()}
            });
        }
        emit playlistsChanged();
    });
}

void SubsonicClient::fetchPlaylist(const QString& playlistId) {
    if (!m_authenticated) return;

    if (m_playlistReply) {
        m_playlistReply->abort();
    }

    m_tracks.clear();
    emit tracksChanged();

    QUrlQuery ex; ex.addQueryItem("id", playlistId);
    QNetworkRequest req(buildUrl("getPlaylist", ex, true));
    auto *reply = m_nam.get(req);
    m_playlistReply = reply;

    connect(reply, &QNetworkReply::finished, this, [this, reply]{
        if (reply != m_playlistReply) {
            reply->deleteLater();
            return;
        }
        m_playlistReply = nullptr;

        if (reply->error() != QNetworkReply::NoError) {
            if (reply->error() != QNetworkReply::OperationCanceledError) {
                emit errorOccurred(reply->errorString());
            }
            reply->deleteLater();
            return;
        }

        const auto doc = QJsonDocument::fromJson(reply->readAll());
        reply->deleteLater();
        QString err;
        if (!checkOk(doc, &err)) { emit errorOccurred(err); return; }

        auto root = doc.object().value("subsonic-response").toObject();
        auto songs = root.value("playlist").toObject().value("entry").toArray();
        for (const auto &sv : songs) {
            auto s = sv.toObject();
            auto rg = s.value("replayGain").toObject();
            m_tracks.push_back(QVariantMap{
                {"id", s.value("id").toString()},
                {"title", s.value("title").toString()},
                {"artist", s.value("artist").toString()},
                {"artistId", s.value("artistId").toString()},
                {"album", s.value("album").toString()},
                {"albumId", s.value("albumId").toString()},
                {"duration", s.value("duration").toInt()},
                {"coverArt", s.value("coverArt").toString()},
                {"replayGainTrackGain", rg.value("trackGain").toDouble()},
                {"replayGainAlbumGain", rg.value("albumGain").toDouble()}
            });
        }
        emit tracksChanged();
    });
}

void SubsonicClient::fetchFavorites() {
    if (!m_authenticated) return;

    if (m_favoritesReply) {
        m_favoritesReply->abort();
    }

    m_favorites.clear();
    emit favoritesChanged();

    QNetworkRequest req(buildUrl("getStarred", {}, true));
    auto *reply = m_nam.get(req);
    m_favoritesReply = reply;

    connect(reply, &QNetworkReply::finished, this, [this, reply]{
        if (reply != m_favoritesReply) {
            reply->deleteLater();
            return;
        }
        m_favoritesReply = nullptr;

        if (reply->error() != QNetworkReply::NoError) {
            if (reply->error() != QNetworkReply::OperationCanceledError) {
                emit errorOccurred(reply->errorString());
            }
            reply->deleteLater();
            return;
        }

        const auto doc = QJsonDocument::fromJson(reply->readAll());
        reply->deleteLater();
        QString err;
        if (!checkOk(doc, &err)) { emit errorOccurred(err); return; }

        auto root = doc.object().value("subsonic-response").toObject();
        auto starred = root.value("starred").toObject();
        auto songs = starred.value("song").toArray();
        for (const auto &sv : songs) {
            auto s = sv.toObject();
            auto rg = s.value("replayGain").toObject();
            m_favorites.push_back(QVariantMap{
                {"id", s.value("id").toString()},
                {"title", s.value("title").toString()},
                {"artist", s.value("artist").toString()},
                {"artistId", s.value("artistId").toString()},
                {"album", s.value("album").toString()},
                {"albumId", s.value("albumId").toString()},
                {"duration", s.value("duration").toInt()},
                {"coverArt", s.value("coverArt").toString()},
                {"replayGainTrackGain", rg.value("trackGain").toDouble()},
                {"replayGainAlbumGain", rg.value("albumGain").toDouble()}
            });
        }
        emit favoritesChanged();
    });
}

void SubsonicClient::search(const QString& term) {
    if (!m_authenticated) return;
    QUrlQuery ex; ex.addQueryItem("query", term);
    ex.addQueryItem("artistCount", "20");
    ex.addQueryItem("albumCount", "40");
    ex.addQueryItem("songCount", "100");
    QNetworkRequest req(buildUrl("search3", ex, true));
    auto *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]{
        if (reply->error() != QNetworkReply::NoError) {
            emit errorOccurred(reply->errorString());
            reply->deleteLater();
            return;
        }
        const auto doc = QJsonDocument::fromJson(reply->readAll());
        reply->deleteLater();
        QString err;
        if (!checkOk(doc, &err)) { emit errorOccurred(err); return; }
        
        auto root = doc.object().value("subsonic-response").toObject();
        auto searchResult = root.value("searchResult3").toObject();
        
        // Parse artists
        m_searchArtists.clear();
        auto artists = searchResult.value("artist").toArray();
        for (const auto &av : artists) {
            auto a = av.toObject();
            m_searchArtists.push_back(QVariantMap{
                {"id", a.value("id").toString()},
                {"name", a.value("name").toString()},
                {"albumCount", a.value("albumCount").toInt()},
                {"coverArt", a.value("coverArt").toString()}
            });
        }
        
        // Parse albums
        m_searchAlbums.clear();
        auto albums = searchResult.value("album").toArray();
        for (const auto &av : albums) {
            auto a = av.toObject();
            m_searchAlbums.push_back(QVariantMap{
                {"id", a.value("id").toString()},
                {"name", a.value("name").toString()},
                {"artist", a.value("artist").toString()},
                {"artistId", a.value("artistId").toString()},
                {"coverArt", a.value("coverArt").toString()},
                {"songCount", a.value("songCount").toInt()},
                {"duration", a.value("duration").toInt()},
                {"year", a.value("year").toInt()}
            });
        }
        
        // Parse songs
        m_tracks.clear();
        auto songs = searchResult.value("song").toArray();
        for (const auto &sv : songs) {
            auto s = sv.toObject();
            auto rg = s.value("replayGain").toObject();
            m_tracks.push_back(QVariantMap{
                {"id", s.value("id").toString()},
                {"title", s.value("title").toString()},
                {"artist", s.value("artist").toString()},
                {"artistId", s.value("artistId").toString()},
                {"album", s.value("album").toString()},
                {"albumId", s.value("albumId").toString()},
                {"duration", s.value("duration").toInt()},
                {"coverArt", s.value("coverArt").toString()},
                {"replayGainTrackGain", rg.value("trackGain").toDouble()},
                {"replayGainAlbumGain", rg.value("albumGain").toDouble()}
            });
        }
        
        emit searchArtistsChanged();
        emit searchAlbumsChanged();
        emit tracksChanged();
    });
}

QUrl SubsonicClient::streamUrl(const QString& songId, int maxBitrateKbps) const {
    QUrlQuery ex; ex.addQueryItem("id", songId);
    if (maxBitrateKbps > 0) ex.addQueryItem("maxBitRate", QString::number(maxBitrateKbps));
    return buildUrl("stream", ex, false);
}

QUrl SubsonicClient::coverArtUrl(const QString& artId, int size) const {
    if (artId.isEmpty()) return {};
    QUrlQuery ex;
    ex.addQueryItem("id", artId);
    ex.addQueryItem("size", QString::number(size));
    ex.addQueryItem("format", "jpg");
    return buildUrl("getCoverArt", ex, false);
}

void SubsonicClient::scrobble(const QString& songId, bool submission, qint64 timeMs) {
    if (!m_authenticated || songId.isEmpty()) return;
    QUrlQuery ex;
    ex.addQueryItem("id", songId);
    ex.addQueryItem("submission", submission ? "true" : "false");
    if (timeMs > 0) {
        const qint64 secs = timeMs / 1000;
        ex.addQueryItem("time", QString::number(secs));
    }
    QNetworkRequest req(buildUrl("scrobble", ex, true));
    auto *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, reply, &QObject::deleteLater);
}

void SubsonicClient::star(const QString& id) {
    if (!m_authenticated || id.isEmpty()) return;
    QUrlQuery ex;
    ex.addQueryItem("id", id);
    QNetworkRequest req(buildUrl("star", ex, true));
    auto *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, reply, &QObject::deleteLater);
}

void SubsonicClient::unstar(const QString& id) {
    if (!m_authenticated || id.isEmpty()) return;
    QUrlQuery ex;
    ex.addQueryItem("id", id);
    QNetworkRequest req(buildUrl("unstar", ex, true));
    auto *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, reply, &QObject::deleteLater);
}

void SubsonicClient::saveCredentials(const QString& url, const QString& user, const QString& password) {
    QSettings settings;
    settings.setValue("serverUrl", url);
    settings.setValue("username", user);
    settings.setValue("password", password);
}

QVariantMap SubsonicClient::loadCredentials() {
    QSettings settings;
    QVariantMap credentials;
    credentials.insert("serverUrl", settings.value("serverUrl"));
    credentials.insert("username", settings.value("username"));
    credentials.insert("password", settings.value("password"));
    return credentials;
}

void SubsonicClient::addToRecentlyPlayed(const QVariantMap& track) {
    if (!track.contains("albumId")) return;

    QVariantMap album;
    album.insert("id", track.value("albumId"));
    album.insert("name", track.value("album"));
    album.insert("artist", track.value("artist"));
    album.insert("artistId", track.value("artistId"));
    album.insert("coverArt", track.value("coverArt"));

    // Remove if already present
    for (int i = 0; i < m_recentlyPlayedAlbums.size(); ++i) {
        if (m_recentlyPlayedAlbums[i].toMap().value("id") == album.value("id")) {
            m_recentlyPlayedAlbums.removeAt(i);
            break;
        }
    }
    // Add to the front
    m_recentlyPlayedAlbums.prepend(album);
    // Limit the list size
    if (m_recentlyPlayedAlbums.size() > 20) {
        m_recentlyPlayedAlbums.removeLast();
    }
    saveRecentlyPlayed();
    emit recentlyPlayedAlbumsChanged();
}

void SubsonicClient::saveRecentlyPlayed() {
    QSettings settings;
    settings.setValue("recentlyPlayedAlbums", m_recentlyPlayedAlbums);
}

void SubsonicClient::loadRecentlyPlayed() {
    QSettings settings;
    m_recentlyPlayedAlbums = settings.value("recentlyPlayedAlbums").toList();
    emit recentlyPlayedAlbumsChanged();
}

void SubsonicClient::fetchAlbumTracksAndAppend(const QString& albumId) {
    if (!m_authenticated) return;

    QUrlQuery ex; ex.addQueryItem("id", albumId);
    QNetworkRequest req(buildUrl("getAlbum", ex, true));
    auto *reply = m_nam.get(req);

    connect(reply, &QNetworkReply::finished, this, [this, reply]{
        if (reply->error() != QNetworkReply::NoError) {
            reply->deleteLater();
            return;
        }

        const auto doc = QJsonDocument::fromJson(reply->readAll());
        reply->deleteLater();
        QString err;
        if (!checkOk(doc, &err)) { return; }

        auto root = doc.object().value("subsonic-response").toObject();
        auto songs = root.value("album").toObject().value("song").toArray();
        bool tracksAdded = false;
        for (const auto &sv : songs) {
            auto s = sv.toObject();
            auto rg = s.value("replayGain").toObject();
            m_tracks.push_back(QVariantMap{
                {"id", s.value("id").toString()},
                {"title", s.value("title").toString()},
                {"artist", s.value("artist").toString()},
                {"artistId", s.value("artistId").toString()},
                {"album", s.value("album").toString()},
                {"albumId", s.value("albumId").toString()},
                {"track", s.value("track").toInt()},
                {"duration", s.value("duration").toInt()},
                {"coverArt", s.value("coverArt").toString()},
                {"replayGainTrackGain", rg.value("trackGain").toDouble()},
                {"replayGainAlbumGain", rg.value("albumGain").toDouble()}
            });
            tracksAdded = true;
        }
        if (tracksAdded) {
            emit tracksChanged();
        }
    });
}

void SubsonicClient::fetchAlbumListPage(const QString& type, int offset)
{
    if (!m_authenticated)
        return;

    QUrlQuery ex;
    ex.addQueryItem("type", type);
    ex.addQueryItem("size", QString::number(ALBUM_LIST_PAGE_SIZE));
    if (offset > 0)
        ex.addQueryItem("offset", QString::number(offset));

    QNetworkRequest req(buildUrl("getAlbumList2", ex, true));
    auto *reply = m_nam.get(req);
    m_albumListReply = reply;

    connect(reply, &QNetworkReply::finished, this, [this, reply, type, offset] {
        if (reply != m_albumListReply) {
            reply->deleteLater();
            return;
        }
        m_albumListReply = nullptr;

        if (reply->error() != QNetworkReply::NoError) {
            if (reply->error() != QNetworkReply::OperationCanceledError) {
                emit errorOccurred(reply->errorString());
            }
            m_albumListPaging = false;
            reply->deleteLater();
            return;
        }

        const auto doc = QJsonDocument::fromJson(reply->readAll());
        QString err;
        if (!checkOk(doc, &err)) {
            emit errorOccurred(err);
            m_albumListPaging = false;
            reply->deleteLater();
            return;
        }

        auto root = doc.object().value("subsonic-response").toObject();
        auto albums = root.value("albumList2").toObject().value("album").toArray();
        for (const auto &av : albums) {
            auto a = av.toObject();
            m_albumList.push_back(QVariantMap{
                {"id", a.value("id").toString()},
                {"name", a.value("name").toString()},
                {"artistId", a.value("artistId").toString()},
                {"artist", a.value("artist").toString()},
                {"year", a.value("year").toInt()},
                {"coverArt", a.value("coverArt").toString()}
            });
        }

        emit albumListChanged();

        if (albums.size() == ALBUM_LIST_PAGE_SIZE) {
            m_pendingAlbumListOffset = offset + albums.size();
            reply->deleteLater();
            fetchAlbumListPage(type, m_pendingAlbumListOffset);
            return;
        }

        m_albumListPaging = false;
        std::sort(m_albumList.begin(), m_albumList.end(), [](const QVariant& v1, const QVariant& v2) {
            return v1.toMap().value("name").toString().localeAwareCompare(v2.toMap().value("name").toString()) < 0;
        });
        emit albumListChanged();
        reply->deleteLater();
    });
}

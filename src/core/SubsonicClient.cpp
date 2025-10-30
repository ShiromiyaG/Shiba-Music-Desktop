#include "SubsonicClient.h"
#include <QCryptographicHash>
#include <QRandomGenerator>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonObject>
#include <QJsonArray>

static constexpr auto API_VERSION = "1.16.1";   // Navidrome alvo
static constexpr auto CLIENT_NAME = "ShibaMusicQt";
static inline QString ensureNoTrailingSlash(QString s) {
    if (s.endsWith('/')) s.chop(1);
    return s;
}

SubsonicClient::SubsonicClient(QObject *parent) : QObject(parent) {}

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
            emit errorOccurred(reply->errorString());
            reply->deleteLater();
            return;
        }
        const auto all = reply->readAll();
        reply->deleteLater();
        const auto doc = QJsonDocument::fromJson(all);
        QString err;
        const bool ok = checkOk(doc, &err);
        setAuthenticated(ok);
        if (!ok) { emit errorOccurred("Falha no login: " + err); return; }
        fetchArtists();
    });
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
        auto albums = root.value("artist").toObject().value("album").toArray();
        for (const auto &av : albums) {
            auto a = av.toObject();
            m_albums.push_back(QVariantMap{
                {"id", a.value("id").toString()},
                {"name", a.value("name").toString()},
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
            m_tracks.push_back(QVariantMap{
                {"id", s.value("id").toString()},
                {"title", s.value("title").toString()},
                {"artist", s.value("artist").toString()},
                {"album", s.value("album").toString()},
                {"track", s.value("track").toInt()},
                {"duration", s.value("duration").toInt()},
                {"coverArt", s.value("coverArt").toString()}
            });
        }
        emit tracksChanged();
    });
}

void SubsonicClient::fetchAlbumList(const QString& type) {
    if (!m_authenticated) return;

    if (m_albumListReply) {
        m_albumListReply->abort();
    }

    m_albumList.clear();
    emit albumListChanged();

    QUrlQuery ex;
    ex.addQueryItem("type", type);
    ex.addQueryItem("size", "500");
    QNetworkRequest req(buildUrl("getAlbumList2", ex, true));
    auto *reply = m_nam.get(req);
    m_albumListReply = reply;

    connect(reply, &QNetworkReply::finished, this, [this, reply]{
        if (reply != m_albumListReply) {
            reply->deleteLater();
            return;
        }
        m_albumListReply = nullptr;

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
        auto albums = root.value("albumList2").toObject().value("album").toArray();
        for (const auto &av : albums) {
            auto a = av.toObject();
            m_albumList.push_back(QVariantMap{
                {"id", a.value("id").toString()},
                {"name", a.value("name").toString()},
                {"artist", a.value("artist").toString()},
                {"year", a.value("year").toInt()},
                {"coverArt", a.value("coverArt").toString()}
            });
        }

        std::sort(m_albumList.begin(), m_albumList.end(), [](const QVariant& v1, const QVariant& v2) {
            return v1.toMap().value("name").toString().localeAwareCompare(v2.toMap().value("name").toString()) < 0;
        });

        emit albumListChanged();
    });
}

void SubsonicClient::search(const QString& term) {
    if (!m_authenticated) return;
    QUrlQuery ex; ex.addQueryItem("query", term);
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
        m_tracks.clear();
        auto root = doc.object().value("subsonic-response").toObject();
        auto songs = root.value("searchResult3").toObject().value("song").toArray();
        for (const auto &sv : songs) {
            auto s = sv.toObject();
            m_tracks.push_back(QVariantMap{
                {"id", s.value("id").toString()},
                {"title", s.value("title").toString()},
                {"artist", s.value("artist").toString()},
                {"album", s.value("album").toString()},
                {"duration", s.value("duration").toInt()},
                {"coverArt", s.value("coverArt").toString()}
            });
        }
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

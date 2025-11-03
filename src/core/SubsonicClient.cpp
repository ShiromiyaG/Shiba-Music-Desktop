#include "SubsonicClient.h"
#include "CacheManager.h"
#include <set>
#include <QCryptographicHash>
#include <QRandomGenerator>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QNetworkDiskCache>
#include <QSettings>
#include <QJsonObject>
#include <QJsonArray>
#include <QStandardPaths>
#include <QDateTime>
#include <QUrl>
#include <QDir>
#include <QDebug>
#include <QTimer>
#include <functional>
#include <memory>
#include <algorithm>

static constexpr auto API_VERSION = "1.16.1";
static constexpr auto CLIENT_NAME = "ShibaMusicQt";
static constexpr int ALBUM_LIST_PAGE_SIZE = 50;

static QHash<QString, QString> g_stringPool;
static QString internString(const QString &str) {
    if (str.isEmpty()) return str;
    auto it = g_stringPool.constFind(str);
    if (it != g_stringPool.constEnd()) return *it;
    g_stringPool.insert(str, str);
    return str;
}

static inline QString ensureNoTrailingSlash(QString s)
{
    if (s.endsWith('/'))
        s.chop(1);
    return s;
}

static QString normalizedCredentialUrl(const QString &url)
{
    return ensureNoTrailingSlash(url.trimmed());
}

static QString normalizedCredentialUsername(const QString &user)
{
    return user.trimmed();
}

template <typename List>
static void clearAndShrink(List &list)
{
    if (!list.isEmpty())
        list.clear();
    list.squeeze();
}

QVariantList SubsonicClient::tracksToVariantList(const TrackList &list)
{
    QVariantList result;
    result.reserve(list.size());
    for (const auto &entry : list)
        result.append(trackEntryToVariant(entry));
    return result;
}

SubsonicClient::TrackList SubsonicClient::tracksFromVariantList(const QVariantList &list)
{
    TrackList result;
    result.reserve(list.size());
    for (const QVariant &value : list)
        result.append(trackEntryFromVariant(value.toMap()));
    return result;
}

QVariantMap SubsonicClient::trackEntryToVariant(const TrackEntry &entry)
{
    QVariantMap map;
    map.insert(QStringLiteral("id"), entry.id);
    map.insert(QStringLiteral("title"), entry.title);
    map.insert(QStringLiteral("artist"), entry.artist);
    map.insert(QStringLiteral("artistId"), entry.artistId);
    map.insert(QStringLiteral("album"), entry.album);
    map.insert(QStringLiteral("albumId"), entry.albumId);
    map.insert(QStringLiteral("duration"), entry.duration);
    if (entry.track > 0)
        map.insert(QStringLiteral("track"), entry.track);
    if (entry.year > 0)
        map.insert(QStringLiteral("year"), entry.year);
    if (!entry.coverArt.isEmpty())
        map.insert(QStringLiteral("coverArt"), entry.coverArt);
    map.insert(QStringLiteral("replayGainTrackGain"), entry.replayGainTrackGain);
    map.insert(QStringLiteral("replayGainAlbumGain"), entry.replayGainAlbumGain);
    return map;
}

SubsonicClient::TrackEntry SubsonicClient::trackEntryFromVariant(const QVariantMap &map)
{
    TrackEntry entry;
    entry.id = internString(map.value(QStringLiteral("id")).toString());
    entry.title = internString(map.value(QStringLiteral("title")).toString());
    entry.artist = internString(map.value(QStringLiteral("artist")).toString());
    entry.artistId = internString(map.value(QStringLiteral("artistId")).toString());
    entry.album = internString(map.value(QStringLiteral("album")).toString());
    entry.albumId = internString(map.value(QStringLiteral("albumId")).toString());
    entry.coverArt = internString(map.value(QStringLiteral("coverArt")).toString());
    entry.duration = map.value(QStringLiteral("duration")).toInt();
    entry.track = static_cast<qint16>(map.value(QStringLiteral("track")).toInt());
    entry.year = static_cast<qint16>(map.value(QStringLiteral("year")).toInt());
    entry.replayGainTrackGain = static_cast<float>(map.value(QStringLiteral("replayGainTrackGain")).toDouble());
    entry.replayGainAlbumGain = static_cast<float>(map.value(QStringLiteral("replayGainAlbumGain")).toDouble());
    return entry;
}

static QString credentialKeyFor(const QString &serverUrl, const QString &username)
{
    const QString normalizedUrl = normalizedCredentialUrl(serverUrl);
    const QString normalizedUser = normalizedCredentialUsername(username);
    if (normalizedUrl.isEmpty() || normalizedUser.isEmpty())
    {
        return {};
    }
    return normalizedUrl.toLower() + '|' + normalizedUser.toLower();
}

static QString credentialDisplayName(const QString &serverUrl, const QString &username)
{
    const QString trimmedUser = normalizedCredentialUsername(username);
    QUrl parsed = QUrl::fromUserInput(serverUrl);
    QString location = parsed.host();
    if (parsed.port() != -1)
    {
        location += ':' + QString::number(parsed.port());
    }
    const QString path = parsed.path();
    if (!path.isEmpty() && path != "/")
    {
        if (!location.isEmpty())
        {
            location += path;
        }
        else
        {
            location = path;
        }
    }
    if (location.isEmpty())
    {
        location = normalizedCredentialUrl(serverUrl);
    }
    if (trimmedUser.isEmpty())
    {
        return location;
    }
    return QStringLiteral("%1 @ %2").arg(trimmedUser, location);
}

static bool isTransientNetworkError(QNetworkReply::NetworkError error)
{
    switch (error)
    {
    case QNetworkReply::ConnectionRefusedError:
    case QNetworkReply::RemoteHostClosedError:
    case QNetworkReply::HostNotFoundError:
    case QNetworkReply::TimeoutError:
    case QNetworkReply::TemporaryNetworkFailureError:
    case QNetworkReply::ProxyTimeoutError:
    case QNetworkReply::ProxyConnectionRefusedError:
    case QNetworkReply::ProxyNotFoundError:
    case QNetworkReply::UnknownNetworkError:
    case QNetworkReply::NetworkSessionFailedError:
        return true;
    default:
        return false;
    }
}

static bool shouldFallbackForError(int code)
{
    return code == 0 || code == 10;
}

static QVariantMap sanitizeCredentialEntry(const QVariantMap &entry)
{
    QVariantMap sanitized = entry;
    const QString url = normalizedCredentialUrl(sanitized.value("serverUrl").toString());
    const QString user = normalizedCredentialUsername(sanitized.value("username").toString());
    sanitized.insert("serverUrl", url);
    sanitized.insert("username", user);

    QString key = sanitized.value("key").toString();
    if (key.isEmpty())
    {
        key = credentialKeyFor(url, user);
        sanitized.insert("key", key);
    }

    if (sanitized.value("displayName").toString().isEmpty())
    {
        sanitized.insert("displayName", credentialDisplayName(url, user));
    }

    return sanitized;
}

static bool sanitizeCredentialList(QVariantList &list)
{
    bool changed = false;
    for (int i = list.size() - 1; i >= 0; --i)
    {
        QVariantMap rawEntry = list.at(i).toMap();
        QVariantMap sanitized = sanitizeCredentialEntry(rawEntry);
        const QString url = sanitized.value("serverUrl").toString();
        const QString user = sanitized.value("username").toString();
        if (url.isEmpty() || user.isEmpty())
        {
            list.removeAt(i);
            changed = true;
            continue;
        }
        if (sanitized != rawEntry)
        {
            list[i] = sanitized;
            changed = true;
        }
        else
        {
            list[i] = sanitized;
        }
    }
    return changed;
}

static void sortCredentialList(QVariantList &list)
{
    std::sort(list.begin(), list.end(), [](const QVariant &first, const QVariant &second)
              {
        const QVariantMap a = first.toMap();
        const QVariantMap b = second.toMap();
        const QString aTime = a.value("lastUsed").toString();
        const QString bTime = b.value("lastUsed").toString();
        if (aTime == bTime) {
            const QString aName = a.value("displayName").toString();
            const QString bName = b.value("displayName").toString();
            return aName.compare(bName, Qt::CaseInsensitive) < 0;
        }
        return aTime > bTime; });
}

static void migrateLegacyCredentials(QSettings &settings)
{
    const QString legacyUrl = settings.value("serverUrl").toString();
    const QString legacyUsername = settings.value("username").toString();
    const QString legacyPassword = settings.value("password").toString();

    if (legacyUrl.isEmpty() && legacyUsername.isEmpty() && legacyPassword.isEmpty())
    {
        return;
    }

    const QString url = normalizedCredentialUrl(legacyUrl);
    const QString user = normalizedCredentialUsername(legacyUsername);
    const QString key = credentialKeyFor(url, user);

    if (url.isEmpty() || user.isEmpty() || key.isEmpty())
    {
        settings.remove("serverUrl");
        settings.remove("username");
        settings.remove("password");
        return;
    }

    settings.beginGroup("credentials");
    QVariantList profiles = settings.value("profiles").toList();
    bool updated = false;
    const auto now = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);
    for (int i = 0; i < profiles.size(); ++i)
    {
        QVariantMap entry = profiles.at(i).toMap();
        if (entry.value("key").toString() == key)
        {
            entry.insert("serverUrl", url);
            entry.insert("username", user);
            if (!legacyPassword.isEmpty())
            {
                entry.insert("password", legacyPassword);
            }
            entry.insert("displayName", credentialDisplayName(url, user));
            if (entry.value("lastUsed").toString().isEmpty())
            {
                entry.insert("lastUsed", now);
            }
            profiles[i] = entry;
            updated = true;
            break;
        }
    }

    if (!updated)
    {
        QVariantMap entry;
        entry.insert("serverUrl", url);
        entry.insert("username", user);
        entry.insert("password", legacyPassword);
        entry.insert("key", key);
        entry.insert("displayName", credentialDisplayName(url, user));
        entry.insert("lastUsed", now);
        profiles.prepend(entry);
    }

    sanitizeCredentialList(profiles);
    sortCredentialList(profiles);

    settings.setValue("profiles", profiles);
    settings.setValue("lastUsedKey", key);
    settings.endGroup();

    settings.remove("serverUrl");
    settings.remove("username");
    settings.remove("password");
}

SubsonicClient::SubsonicClient(QObject *parent) : QObject(parent)
{
    loadRecentlyPlayed();

    auto *diskCache = new QNetworkDiskCache(this);
    const QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/network";
    QDir().mkpath(cacheDir);
    diskCache->setCacheDirectory(cacheDir);
    diskCache->setMaximumCacheSize(30 * 1024 * 1024);
    m_nam.setCache(diskCache);
    m_nam.setRedirectPolicy(QNetworkRequest::NoLessSafeRedirectPolicy);
}

void SubsonicClient::setServerUrl(const QString &url)
{
    auto norm = ensureNoTrailingSlash(url.trimmed());
    if (norm == m_server)
        return;
    m_server = norm;
    emit serverUrlChanged();
}

void SubsonicClient::setUsername(const QString &u)
{
    if (u == m_user)
        return;
    m_user = u;
    emit usernameChanged();
}

void SubsonicClient::setCacheManager(CacheManager *cache)
{
    if (m_cacheManager == cache)
        return;
    m_cacheManager = cache;
}

QString SubsonicClient::md5(const QString &s) const
{
    return QString::fromLatin1(QCryptographicHash::hash(s.toUtf8(), QCryptographicHash::Md5).toHex());
}
QString SubsonicClient::randomSalt() const
{
    static constexpr char charset[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    constexpr int charsetSize = static_cast<int>(sizeof(charset) - 1);
    QByteArray bytes(12, Qt::Uninitialized);
    for (int i = 0; i < bytes.size(); ++i)
    {
        bytes[i] = charset[QRandomGenerator::global()->bounded(charsetSize)];
    }
    return QString::fromLatin1(bytes);
}

QUrl SubsonicClient::buildUrl(const QString &method, const QUrlQuery &extra, bool isJson) const
{
    QUrl url(m_server + "/rest/" + method + ".view");
    QUrlQuery q;
    q.addQueryItem("u", m_user);
    q.addQueryItem("v", API_VERSION);
    q.addQueryItem("c", CLIENT_NAME);
    if (isJson)
    {
        q.addQueryItem("f", "json");
    }
    if (m_authMode == AuthMode::Legacy)
    {
        if (!m_passwordHex.isEmpty())
        {
            q.addQueryItem("p", QStringLiteral("enc:%1").arg(m_passwordHex));
        }
        else
        {
            q.addQueryItem("p", QString());
        }
    }
    else
    {
        q.addQueryItem("t", m_token);
        q.addQueryItem("s", m_salt);
    }
    // add extras
    for (auto &item : extra.queryItems())
        q.addQueryItem(item.first, item.second);
    url.setQuery(q);
    return url;
}

bool SubsonicClient::checkOk(const QJsonDocument &doc, QString *err, int *code) const
{
    if (doc.isNull())
    {
        if (code)
            *code = -1;
        if (err)
            *err = tr("Resposta inválida do servidor");
        return false;
    }

    const QJsonObject root = doc.object().value(QStringLiteral("subsonic-response")).toObject();
    if (root.value(QStringLiteral("status")).toString() == QLatin1String("ok"))
    {
        if (code)
            *code = 0;
        if (err)
            err->clear();
        return true;
    }

    const QJsonObject errorObj = root.value(QStringLiteral("error")).toObject();
    const int errorCode = errorObj.value(QStringLiteral("code")).toInt();
    if (code)
        *code = errorCode;

    if (err)
    {
        const QString message = errorObj.value(QStringLiteral("message")).toString();
        if (!message.isEmpty())
        {
            *err = QStringLiteral("%1 (code %2)").arg(message, QString::number(errorCode));
        }
        else
        {
            *err = QStringLiteral("code %1").arg(errorCode);
        }
    }

    return false;
}

void SubsonicClient::setAuthenticated(bool ok)
{
    if (m_authenticated == ok)
        return;
    m_authenticated = ok;
    emit authenticatedChanged();
}

void SubsonicClient::login(const QString &url, const QString &user, const QString &password)
{
    const QString normalizedUrl = normalizedCredentialUrl(url);
    const QString normalizedUser = normalizedCredentialUsername(user);

    if (normalizedUrl.isEmpty() || normalizedUser.isEmpty())
    {
        const QString message = tr("Falha no login: servidor ou usuário inválido.");
        setAuthenticated(false);
        emit loginFailed(message);
        emit errorOccurred(message);
        return;
    }
    if (password.isEmpty())
    {
        const QString message = tr("Falha no login: senha vazia.");
        setAuthenticated(false);
        emit loginFailed(message);
        emit errorOccurred(message);
        return;
    }

    setServerUrl(normalizedUrl);
    setUsername(normalizedUser);
    setAuthenticated(false);

    struct LoginContext
    {
        QString password;
        int retries = 0;
        bool legacyFallbackAttempted = false;
    };

    auto context = std::make_shared<LoginContext>();
    context->password = password;

    using AuthMode = SubsonicClient::AuthMode;

    auto attempt = std::make_shared<std::function<void(AuthMode)>>();

    *attempt = [this, context, attempt](AuthMode mode)
    {
        auto issueRequest = [this, context, attempt, mode]()
        {
            if (mode == AuthMode::Legacy)
            {
                m_authMode = AuthMode::Legacy;
                m_salt.clear();
                m_token.clear();
                m_passwordHex = QString::fromLatin1(context->password.toUtf8().toHex());
            }
            else
            {
                m_authMode = AuthMode::Token;
                m_salt = randomSalt();
                m_token = md5(context->password + m_salt);
                m_passwordHex.clear();
            }

            QNetworkRequest req(buildUrl("ping", {}, true));
            auto *reply = m_nam.get(req);
            connect(reply, &QNetworkReply::finished, this, [this, reply, context, attempt, mode]()
                    {
                const auto networkError = reply->error();
                if (networkError != QNetworkReply::NoError) {
                    const QString message = reply->errorString();
                    reply->deleteLater();

                    if (isTransientNetworkError(networkError) && context->retries < 2) {
                        ++context->retries;
                        const int backoffMs = 250 * context->retries;
                        QTimer::singleShot(backoffMs, this, [attempt, mode]() { (*attempt)(mode); });
                        return;
                    }

                    context->password.clear();
                    m_token.clear();
                    m_salt.clear();
                    if (mode == AuthMode::Legacy)
                        m_passwordHex.clear();
                    m_authMode = AuthMode::Token;
                    setAuthenticated(false);
                    emit loginFailed(message);
                    emit errorOccurred(message);
                    return;
                }

                const QByteArray payload = reply->readAll();
                reply->deleteLater();

                const QJsonDocument doc = QJsonDocument::fromJson(payload);
                QString err;
                int errCode = 0;
                const bool ok = checkOk(doc, &err, &errCode);
                if (!ok) {
                    if (mode == AuthMode::Token && !context->legacyFallbackAttempted && shouldFallbackForError(errCode)) {
                        context->legacyFallbackAttempted = true;
                        context->retries = 0;
                        QTimer::singleShot(0, this, [attempt]() { (*attempt)(AuthMode::Legacy); });
                        return;
                    }

                    context->password.clear();
                    m_token.clear();
                    m_salt.clear();
                    if (mode == AuthMode::Legacy)
                        m_passwordHex.clear();
                    m_authMode = AuthMode::Token;
                    setAuthenticated(false);
                    const QString message = err.isEmpty()
                        ? tr("Falha no login: resposta inválida do servidor")
                        : tr("Falha no login: %1").arg(err);
                    emit loginFailed(message);
                    emit errorOccurred(message);
                    return;
                }

                context->password.clear();
                context->retries = 0;
                setAuthenticated(true);
                fetchArtists(); });
        };

        issueRequest();
    };

    (*attempt)(AuthMode::Token);
}

void SubsonicClient::logout()
{
    setAuthenticated(false);
    m_token.clear();
    m_salt.clear();
    m_passwordHex.clear();
    m_authMode = AuthMode::Token;

    auto abortReply = [](QNetworkReply *&reply)
    {
        if (!reply)
            return;
        reply->abort();
        reply->deleteLater();
        reply = nullptr;
    };

    abortReply(m_artistReply);
    abortReply(m_albumListReply);
    abortReply(m_albumReply);
    abortReply(m_randomSongsReply);
    abortReply(m_favoritesReply);
    abortReply(m_playlistsReply);
    abortReply(m_playlistReply);

    if (!m_artistCover.isEmpty())
    {
        m_artistCover.clear();
        emit artistCoverChanged();
    }

    const bool hadArtists = !m_artists.isEmpty();
    const bool hadAlbums = !m_albums.isEmpty();
    const bool hadAlbumList = !m_albumList.isEmpty();
    const bool hadTracks = !m_tracks.isEmpty();
    const bool hadSearchArtists = !m_searchArtists.isEmpty();
    const bool hadSearchAlbums = !m_searchAlbums.isEmpty();
    const bool hadRecentlyPlayed = !m_recentlyPlayedAlbums.isEmpty();
    const bool hadRandomSongs = !m_randomSongs.isEmpty();
    const bool hadFavorites = !m_favorites.isEmpty();
    const bool hadPlaylists = !m_playlists.isEmpty();

    clearAndShrink(m_artists);
    clearAndShrink(m_albums);
    clearAndShrink(m_albumList);
    clearAndShrink(m_tracks);
    clearAndShrink(m_searchArtists);
    clearAndShrink(m_searchAlbums);
    clearAndShrink(m_recentlyPlayedAlbums);
    clearAndShrink(m_randomSongs);
    clearAndShrink(m_favorites);
    clearAndShrink(m_playlists);
    
    // Clear string pool on logout to free memory
    g_stringPool.clear();
    g_stringPool.squeeze();

    if (hadArtists)
        emit artistsChanged();
    if (hadAlbums)
        emit albumsChanged();
    if (hadAlbumList)
        emit albumListChanged();
    if (hadTracks)
        emit tracksChanged();
    if (hadSearchArtists)
        emit searchArtistsChanged();
    if (hadSearchAlbums)
        emit searchAlbumsChanged();
    if (hadRecentlyPlayed)
        emit recentlyPlayedAlbumsChanged();
    if (hadRandomSongs)
        emit randomSongsChanged();
    if (hadFavorites)
        emit favoritesChanged();
    if (hadPlaylists)
        emit playlistsChanged();

    setAlbumListLoading(false);
    setHasMoreAlbumList(false);
    m_pendingAlbumListType.clear();
    m_pendingAlbumListOffset = 0;
}

void SubsonicClient::fetchArtists()
{
    if (!m_authenticated)
        return;

    if (m_cacheManager && m_artists.isEmpty())
    {
        const auto cached = m_cacheManager->getList(cacheKey("artists"));
        if (!cached.isEmpty())
        {
            m_artists = cached;
            emit artistsChanged();
        }
    }

    QNetworkRequest req(buildUrl("getArtists", {}, true));
    auto *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]
            {
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
        auto artists = root.value("artists").toObject().value("index").toArray();

        qsizetype totalArtists = 0;
        for (const auto &idxVal : artists)
            totalArtists += idxVal.toObject().value("artist").toArray().size();

        clearAndShrink(m_artists);
        if (totalArtists > 0)
            m_artists.reserve(totalArtists);

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
        if (m_cacheManager) {
            m_cacheManager->saveList(cacheKey("artists"), m_artists);
        } });
}

void SubsonicClient::fetchArtist(const QString &artistId)
{
    if (!m_authenticated)
        return;

    if (m_artistReply)
    {
        m_artistReply->abort();
    }

    clearAndShrink(m_albums);
    emit albumsChanged();
    clearTracks();
    if (!m_artistCover.isEmpty())
    {
        m_artistCover.clear();
        emit artistCoverChanged();
    }

    QUrlQuery ex;
    ex.addQueryItem("id", artistId);
    QNetworkRequest req(buildUrl("getArtist", ex, true));
    auto *reply = m_nam.get(req);
    m_artistReply = reply;

    connect(reply, &QNetworkReply::finished, this, [this, reply]
            {
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
        if (!albums.isEmpty())
            m_albums.reserve(albums.size());
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
        emit albumsChanged(); });
}

void SubsonicClient::fetchAlbum(const QString &albumId)
{
    if (!m_authenticated)
        return;

    if (m_albumReply)
    {
        m_albumReply->abort();
    }

    clearTracks();

    QUrlQuery ex;
    ex.addQueryItem("id", albumId);
    QNetworkRequest req(buildUrl("getAlbum", ex, true));
    auto *reply = m_nam.get(req);
    m_albumReply = reply;

    connect(reply, &QNetworkReply::finished, this, [this, reply]
            {
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
        if (!songs.isEmpty())
            m_tracks.reserve(songs.size());
        for (const auto &sv : songs) {
            auto s = sv.toObject();
            auto rg = s.value("replayGain").toObject();
            TrackEntry entry;
            entry.id = internString(s.value("id").toString());
            entry.title = internString(s.value("title").toString());
            entry.artist = internString(s.value("artist").toString());
            entry.artistId = internString(s.value("artistId").toString());
            entry.album = internString(s.value("album").toString());
            entry.albumId = internString(s.value("albumId").toString());
            entry.track = static_cast<qint16>(s.value("track").toInt());
            entry.duration = s.value("duration").toInt();
            entry.coverArt = internString(s.value("coverArt").toString());
            entry.replayGainTrackGain = static_cast<float>(rg.value("trackGain").toDouble());
            entry.replayGainAlbumGain = static_cast<float>(rg.value("albumGain").toDouble());
            entry.year = static_cast<qint16>(s.value("year").toInt());
            m_tracks.push_back(entry);
        }
        emit tracksChanged(); });
}

void SubsonicClient::fetchAlbumList(const QString &type)
{
    if (!m_authenticated)
        return;

    if (m_pendingAlbumListType != type && !m_albumList.isEmpty())
    {
        clearAndShrink(m_albumList);
        emit albumListChanged();
    }

    setHasMoreAlbumList(false);

    if (m_cacheManager && m_albumList.isEmpty())
    {
        const auto cached = m_cacheManager->getList(cacheKey(QStringLiteral("albumList:%1").arg(type)));
        if (!cached.isEmpty())
        {
            const int initialCount = std::min(static_cast<qsizetype>(ALBUM_LIST_PAGE_SIZE), cached.size());
            m_albumList = cached.mid(0, initialCount);
            emit albumListChanged();
            if (cached.size() > initialCount)
            {
                setHasMoreAlbumList(true);
            }
        }
    }

    if (m_albumListReply)
    {
        m_albumListReply->abort();
        m_albumListReply->deleteLater();
        m_albumListReply = nullptr;
        setAlbumListLoading(false);
    }

    m_pendingAlbumListType = type;
    m_pendingAlbumListOffset = 0;
    fetchAlbumListPage(type, 0);
}

void SubsonicClient::fetchMoreAlbums()
{
    if (!m_authenticated)
        return;
    if (!m_hasMoreAlbumList || m_albumListPaging)
        return;
    if (m_pendingAlbumListType.isEmpty())
        return;

    fetchAlbumListPage(m_pendingAlbumListType, m_pendingAlbumListOffset);
}

void SubsonicClient::fetchRandomSongs()
{
    if (!m_authenticated)
        return;

    if (m_cacheManager && m_randomSongs.isEmpty())
    {
        const auto cached = m_cacheManager->getList(cacheKey("randomSongs"));
        if (!cached.isEmpty())
        {
            m_randomSongs = tracksFromVariantList(cached);
            emit randomSongsChanged();
        }
    }

    if (m_randomSongsReply)
    {
        m_randomSongsReply->abort();
    }

    QUrlQuery ex;
    ex.addQueryItem("size", "10");
    QNetworkRequest req(buildUrl("getRandomSongs", ex, true));
    auto *reply = m_nam.get(req);
    m_randomSongsReply = reply;

    connect(reply, &QNetworkReply::finished, this, [this, reply]
            {
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

        clearAndShrink(m_randomSongs);
        auto root = doc.object().value("subsonic-response").toObject();
        auto songs = root.value("randomSongs").toObject().value("song").toArray();
        if (!songs.isEmpty())
            m_randomSongs.reserve(songs.size());
        for (const auto &sv : songs) {
            auto s = sv.toObject();
            auto rg = s.value("replayGain").toObject();
            TrackEntry entry;
            entry.id = internString(s.value("id").toString());
            entry.title = internString(s.value("title").toString());
            entry.artist = internString(s.value("artist").toString());
            entry.artistId = internString(s.value("artistId").toString());
            entry.album = internString(s.value("album").toString());
            entry.albumId = internString(s.value("albumId").toString());
            entry.duration = s.value("duration").toInt();
            entry.coverArt = internString(s.value("coverArt").toString());
            entry.track = static_cast<qint16>(s.value("track").toInt());
            entry.year = static_cast<qint16>(s.value("year").toInt());
            entry.replayGainTrackGain = static_cast<float>(rg.value("trackGain").toDouble());
            entry.replayGainAlbumGain = static_cast<float>(rg.value("albumGain").toDouble());
            m_randomSongs.push_back(entry);
        }
        emit randomSongsChanged();
        if (m_cacheManager) {
            m_cacheManager->saveList(cacheKey("randomSongs"), tracksToVariantList(m_randomSongs));
        } });
}

void SubsonicClient::fetchPlaylists()
{
    if (!m_authenticated)
        return;

    if (m_cacheManager && m_playlists.isEmpty())
    {
        const auto cached = m_cacheManager->getList(cacheKey("playlists"));
        if (!cached.isEmpty())
        {
            m_playlists = cached;
            emit playlistsChanged();
        }
    }

    if (m_playlistsReply)
    {
        m_playlistsReply->abort();
    }

    QNetworkRequest req(buildUrl("getPlaylists", {}, true));
    auto *reply = m_nam.get(req);
    m_playlistsReply = reply;

    connect(reply, &QNetworkReply::finished, this, [this, reply]
            {
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

        clearAndShrink(m_playlists);
        auto root = doc.object().value("subsonic-response").toObject();
        auto playlists = root.value("playlists").toObject().value("playlist").toArray();
        if (!playlists.isEmpty())
            m_playlists.reserve(playlists.size());
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
        if (m_cacheManager) {
            m_cacheManager->saveList(cacheKey("playlists"), m_playlists);
        } });
}

void SubsonicClient::fetchPlaylist(const QString &playlistId)
{
    if (!m_authenticated)
        return;

    if (m_playlistReply)
    {
        m_playlistReply->abort();
    }

    clearTracks();

    QUrlQuery ex;
    ex.addQueryItem("id", playlistId);
    QNetworkRequest req(buildUrl("getPlaylist", ex, true));
    auto *reply = m_nam.get(req);
    m_playlistReply = reply;

    connect(reply, &QNetworkReply::finished, this, [this, reply]
            {
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
        if (!songs.isEmpty())
            m_tracks.reserve(songs.size());
        for (const auto &sv : songs) {
            auto s = sv.toObject();
            auto rg = s.value("replayGain").toObject();
            TrackEntry entry;
            entry.id = internString(s.value("id").toString());
            entry.title = internString(s.value("title").toString());
            entry.artist = internString(s.value("artist").toString());
            entry.artistId = internString(s.value("artistId").toString());
            entry.album = internString(s.value("album").toString());
            entry.albumId = internString(s.value("albumId").toString());
            entry.duration = s.value("duration").toInt();
            entry.coverArt = internString(s.value("coverArt").toString());
            entry.track = static_cast<qint16>(s.value("track").toInt());
            entry.year = static_cast<qint16>(s.value("year").toInt());
            entry.replayGainTrackGain = static_cast<float>(rg.value("trackGain").toDouble());
            entry.replayGainAlbumGain = static_cast<float>(rg.value("albumGain").toDouble());
            m_tracks.push_back(entry);
        }
        emit tracksChanged(); });
}

void SubsonicClient::fetchFavorites()
{
    if (!m_authenticated)
        return;

    if (m_cacheManager && m_favorites.isEmpty())
    {
        const auto cached = m_cacheManager->getList(cacheKey("favorites"));
        if (!cached.isEmpty())
        {
            m_favorites = tracksFromVariantList(cached);
            emit favoritesChanged();
        }
    }

    if (m_favoritesReply)
    {
        m_favoritesReply->abort();
    }

    QNetworkRequest req(buildUrl("getStarred", {}, true));
    auto *reply = m_nam.get(req);
    m_favoritesReply = reply;

    connect(reply, &QNetworkReply::finished, this, [this, reply]
            {
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

        clearAndShrink(m_favorites);
        auto root = doc.object().value("subsonic-response").toObject();
        auto starred = root.value("starred").toObject();
        auto songs = starred.value("song").toArray();
        if (!songs.isEmpty())
            m_favorites.reserve(songs.size());
        for (const auto &sv : songs) {
            auto s = sv.toObject();
            auto rg = s.value("replayGain").toObject();
            TrackEntry entry;
            entry.id = internString(s.value("id").toString());
            entry.title = internString(s.value("title").toString());
            entry.artist = internString(s.value("artist").toString());
            entry.artistId = internString(s.value("artistId").toString());
            entry.album = internString(s.value("album").toString());
            entry.albumId = internString(s.value("albumId").toString());
            entry.duration = s.value("duration").toInt();
            entry.coverArt = internString(s.value("coverArt").toString());
            entry.track = static_cast<qint16>(s.value("track").toInt());
            entry.year = static_cast<qint16>(s.value("year").toInt());
            entry.replayGainTrackGain = static_cast<float>(rg.value("trackGain").toDouble());
            entry.replayGainAlbumGain = static_cast<float>(rg.value("albumGain").toDouble());
            m_favorites.push_back(entry);
        }
        emit favoritesChanged();
        if (m_cacheManager) {
            m_cacheManager->saveList(cacheKey("favorites"), tracksToVariantList(m_favorites));
        } });
}

void SubsonicClient::search(const QString &term)
{
    if (!m_authenticated)
        return;
    QUrlQuery ex;
    ex.addQueryItem("query", term);
    ex.addQueryItem("artistCount", "20");
    ex.addQueryItem("albumCount", "40");
    ex.addQueryItem("songCount", "100");
    QNetworkRequest req(buildUrl("search3", ex, true));
    auto *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]
            {
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
        clearAndShrink(m_searchArtists);
        auto artists = searchResult.value("artist").toArray();
        if (!artists.isEmpty())
            m_searchArtists.reserve(artists.size());
        for (const auto &av : artists) {
            auto a = av.toObject();
            m_searchArtists.push_back(QVariantMap{
                {"id", internString(a.value("id").toString())},
                {"name", internString(a.value("name").toString())},
                {"albumCount", a.value("albumCount").toInt()},
                {"coverArt", internString(a.value("coverArt").toString())}
            });
        }
        
        // Parse albums
        clearAndShrink(m_searchAlbums);
        auto albums = searchResult.value("album").toArray();
        if (!albums.isEmpty())
            m_searchAlbums.reserve(albums.size());
        for (const auto &av : albums) {
            auto a = av.toObject();
            m_searchAlbums.push_back(QVariantMap{
                {"id", internString(a.value("id").toString())},
                {"name", internString(a.value("name").toString())},
                {"artist", internString(a.value("artist").toString())},
                {"artistId", internString(a.value("artistId").toString())},
                {"coverArt", internString(a.value("coverArt").toString())},
                {"songCount", a.value("songCount").toInt()},
                {"duration", a.value("duration").toInt()},
                {"year", a.value("year").toInt()}
            });
        }
        
        // Parse songs
        clearAndShrink(m_tracks);
        auto songs = searchResult.value("song").toArray();
        if (!songs.isEmpty())
            m_tracks.reserve(songs.size());
        for (const auto &sv : songs) {
            auto s = sv.toObject();
            auto rg = s.value("replayGain").toObject();
            TrackEntry entry;
            entry.id = internString(s.value("id").toString());
            entry.title = internString(s.value("title").toString());
            entry.artist = internString(s.value("artist").toString());
            entry.artistId = internString(s.value("artistId").toString());
            entry.album = internString(s.value("album").toString());
            entry.albumId = internString(s.value("albumId").toString());
            entry.duration = s.value("duration").toInt();
            entry.coverArt = internString(s.value("coverArt").toString());
            entry.track = static_cast<qint16>(s.value("track").toInt());
            entry.year = static_cast<qint16>(s.value("year").toInt());
            entry.replayGainTrackGain = static_cast<float>(rg.value("trackGain").toDouble());
            entry.replayGainAlbumGain = static_cast<float>(rg.value("albumGain").toDouble());
            m_tracks.push_back(entry);
        }
        emit searchArtistsChanged();
        emit searchAlbumsChanged();
        emit tracksChanged(); });
}

QUrl SubsonicClient::streamUrl(const QString &songId, int maxBitrateKbps) const
{
    QUrlQuery ex;
    ex.addQueryItem("id", songId);
    if (maxBitrateKbps > 0)
        ex.addQueryItem("maxBitRate", QString::number(maxBitrateKbps));
    return buildUrl("stream", ex, false);
}

QUrl SubsonicClient::coverArtUrl(const QString &artId, int size) const
{
    if (artId.isEmpty())
        return {};
    QUrlQuery ex;
    ex.addQueryItem("id", artId);
    ex.addQueryItem("size", QString::number(size));
    ex.addQueryItem("format", "jpg");
    return buildUrl("getCoverArt", ex, false);
}

void SubsonicClient::scrobble(const QString &songId, bool submission, qint64 timeMs)
{
    if (!m_authenticated || songId.isEmpty())
        return;
    QUrlQuery ex;
    ex.addQueryItem("id", songId);
    ex.addQueryItem("submission", submission ? "true" : "false");
    if (timeMs > 0)
    {
        const qint64 secs = timeMs / 1000;
        ex.addQueryItem("time", QString::number(secs));
    }
    QNetworkRequest req(buildUrl("scrobble", ex, true));
    auto *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, reply, &QObject::deleteLater);
}

void SubsonicClient::star(const QString &id)
{
    if (!m_authenticated || id.isEmpty())
        return;
    QUrlQuery ex;
    ex.addQueryItem("id", id);
    QNetworkRequest req(buildUrl("star", ex, true));
    auto *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, reply, &QObject::deleteLater);
}

void SubsonicClient::unstar(const QString &id)
{
    if (!m_authenticated || id.isEmpty())
        return;
    QUrlQuery ex;
    ex.addQueryItem("id", id);
    QNetworkRequest req(buildUrl("unstar", ex, true));
    auto *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, reply, &QObject::deleteLater);
}

void SubsonicClient::saveCredentials(const QString &url, const QString &user, const QString &password, bool remember)
{
    QSettings settings;
    migrateLegacyCredentials(settings);

    const QString normalizedUrl = normalizedCredentialUrl(url);
    const QString normalizedUser = normalizedCredentialUsername(user);

    if (normalizedUrl.isEmpty() || normalizedUser.isEmpty())
    {
        if (!remember)
        {
            settings.beginGroup("credentials");
            settings.remove("lastUsedKey");
            settings.endGroup();
        }
        return;
    }

    const QString key = credentialKeyFor(normalizedUrl, normalizedUser);
    if (key.isEmpty())
    {
        return;
    }

    settings.beginGroup("credentials");
    QVariantList originalProfiles = settings.value("profiles").toList();
    QVariantList profiles = originalProfiles;
    bool sanitized = sanitizeCredentialList(profiles);
    const QString now = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);

    if (remember)
    {
        bool updated = false;
        for (int i = 0; i < profiles.size(); ++i)
        {
            QVariantMap entry = profiles.at(i).toMap();
            if (entry.value("key").toString() == key)
            {
                entry.insert("serverUrl", normalizedUrl);
                entry.insert("username", normalizedUser);
                entry.insert("password", password);
                entry.insert("lastUsed", now);
                entry.insert("displayName", credentialDisplayName(normalizedUrl, normalizedUser));
                profiles[i] = entry;
                updated = true;
                break;
            }
        }
        if (!updated)
        {
            QVariantMap entry;
            entry.insert("serverUrl", normalizedUrl);
            entry.insert("username", normalizedUser);
            entry.insert("password", password);
            entry.insert("key", key);
            entry.insert("displayName", credentialDisplayName(normalizedUrl, normalizedUser));
            entry.insert("lastUsed", now);
            profiles.append(entry);
        }
        sortCredentialList(profiles);
        if (sanitized || profiles != originalProfiles)
        {
            settings.setValue("profiles", profiles);
        }
        settings.setValue("lastUsedKey", key);
    }
    else
    {
        bool removed = false;
        for (int i = profiles.size() - 1; i >= 0; --i)
        {
            if (profiles.at(i).toMap().value("key").toString() == key)
            {
                profiles.removeAt(i);
                removed = true;
            }
        }
        if (removed || sanitized)
        {
            sortCredentialList(profiles);
            settings.setValue("profiles", profiles);
        }
        else if (profiles != originalProfiles)
        {
            sortCredentialList(profiles);
            settings.setValue("profiles", profiles);
        }
        if (settings.value("lastUsedKey").toString() == key)
        {
            settings.remove("lastUsedKey");
        }
    }
    settings.endGroup();
}

QVariantMap SubsonicClient::loadCredentials()
{
    QSettings settings;
    migrateLegacyCredentials(settings);

    settings.beginGroup("credentials");
    QVariantList originalProfiles = settings.value("profiles").toList();
    QVariantList profiles = originalProfiles;
    bool sanitized = sanitizeCredentialList(profiles);
    sortCredentialList(profiles);
    if (sanitized || profiles != originalProfiles)
    {
        settings.setValue("profiles", profiles);
    }
    const QString lastUsedKey = settings.value("lastUsedKey").toString();
    settings.endGroup();

    QVariantMap credentials;
    if (!lastUsedKey.isEmpty())
    {
        for (const QVariant &variant : profiles)
        {
            const QVariantMap entry = variant.toMap();
            if (entry.value("key").toString() == lastUsedKey)
            {
                credentials = entry;
                break;
            }
        }
    }

    if (credentials.isEmpty() && !profiles.isEmpty())
    {
        credentials = profiles.first().toMap();
        const QString key = credentials.value("key").toString();
        if (!key.isEmpty() && key != lastUsedKey)
        {
            settings.beginGroup("credentials");
            settings.setValue("lastUsedKey", key);
            settings.endGroup();
        }
    }

    return credentials;
}

QVariantList SubsonicClient::savedCredentials()
{
    QSettings settings;
    migrateLegacyCredentials(settings);

    settings.beginGroup("credentials");
    QVariantList originalProfiles = settings.value("profiles").toList();
    QVariantList profiles = originalProfiles;
    bool sanitized = sanitizeCredentialList(profiles);
    sortCredentialList(profiles);
    if (sanitized || profiles != originalProfiles)
    {
        settings.setValue("profiles", profiles);
    }
    settings.endGroup();

    return profiles;
}

void SubsonicClient::removeCredentials(const QString &credentialKey)
{
    if (credentialKey.isEmpty())
    {
        return;
    }

    QSettings settings;
    migrateLegacyCredentials(settings);

    settings.beginGroup("credentials");
    QVariantList originalProfiles = settings.value("profiles").toList();
    QVariantList profiles = originalProfiles;
    bool sanitized = sanitizeCredentialList(profiles);

    bool removed = false;
    for (int i = profiles.size() - 1; i >= 0; --i)
    {
        if (profiles.at(i).toMap().value("key").toString() == credentialKey)
        {
            profiles.removeAt(i);
            removed = true;
        }
    }

    if (sanitized || removed)
    {
        sortCredentialList(profiles);
        settings.setValue("profiles", profiles);
    }
    else if (profiles != originalProfiles)
    {
        sortCredentialList(profiles);
        settings.setValue("profiles", profiles);
    }

    if (settings.value("lastUsedKey").toString() == credentialKey)
    {
        settings.remove("lastUsedKey");
    }
    settings.endGroup();
}

void SubsonicClient::addToRecentlyPlayed(const QVariantMap &track)
{
    if (!track.contains("albumId"))
        return;

    QVariantMap album;
    album.insert("id", track.value("albumId"));
    album.insert("name", track.value("album"));
    album.insert("artist", track.value("artist"));
    album.insert("artistId", track.value("artistId"));
    album.insert("coverArt", track.value("coverArt"));

    // Remove if already present
    for (int i = 0; i < m_recentlyPlayedAlbums.size(); ++i)
    {
        if (m_recentlyPlayedAlbums[i].toMap().value("id") == album.value("id"))
        {
            m_recentlyPlayedAlbums.removeAt(i);
            break;
        }
    }
    // Add to the front
    m_recentlyPlayedAlbums.prepend(album);
    if (m_recentlyPlayedAlbums.size() > 10)
    {
        m_recentlyPlayedAlbums.removeLast();
    }
    saveRecentlyPlayed();
    emit recentlyPlayedAlbumsChanged();
}

void SubsonicClient::saveRecentlyPlayed()
{
    QSettings settings;
    settings.setValue("recentlyPlayedAlbums", m_recentlyPlayedAlbums);
}

void SubsonicClient::loadRecentlyPlayed()
{
    QSettings settings;
    m_recentlyPlayedAlbums = settings.value("recentlyPlayedAlbums").toList();
    emit recentlyPlayedAlbumsChanged();
}

QString SubsonicClient::cacheKey(const QString &base) const
{
    return QStringLiteral("%1|%2|%3").arg(base, m_server, m_user);
}

QVariantList SubsonicClient::tracks() const
{
    return tracksToVariantList(m_tracks);
}

QVariantList SubsonicClient::randomSongs() const
{
    return tracksToVariantList(m_randomSongs);
}

QVariantList SubsonicClient::favorites() const
{
    return tracksToVariantList(m_favorites);
}

void SubsonicClient::setAlbumListLoading(bool loading)
{
    if (m_albumListPaging == loading)
        return;
    m_albumListPaging = loading;
    emit albumListLoadingChanged();
}

void SubsonicClient::setHasMoreAlbumList(bool hasMore)
{
    if (m_hasMoreAlbumList == hasMore)
        return;
    m_hasMoreAlbumList = hasMore;
    emit albumListHasMoreChanged();
}

void SubsonicClient::fetchAlbumTracksAndAppend(const QString &albumId)
{
    if (!m_authenticated)
        return;

    QUrlQuery ex;
    ex.addQueryItem("id", albumId);
    QNetworkRequest req(buildUrl("getAlbum", ex, true));
    auto *reply = m_nam.get(req);

    connect(reply, &QNetworkReply::finished, this, [this, reply]
            {
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
            TrackEntry entry;
            entry.id = s.value("id").toString();
            entry.title = s.value("title").toString();
            entry.artist = s.value("artist").toString();
            entry.artistId = s.value("artistId").toString();
            entry.album = s.value("album").toString();
            entry.albumId = s.value("albumId").toString();
            entry.track = s.value("track").toInt();
            entry.duration = s.value("duration").toInt();
            entry.coverArt = s.value("coverArt").toString();
            entry.replayGainTrackGain = rg.value("trackGain").toDouble();
            entry.replayGainAlbumGain = rg.value("albumGain").toDouble();
            entry.year = s.value("year").toInt();
            m_tracks.push_back(entry);
            tracksAdded = true;
        }
        if (tracksAdded) {
            emit tracksChanged();
        } });
}

void SubsonicClient::fetchAlbumListPage(const QString &type, int offset)
{
    if (!m_authenticated)
        return;

    setAlbumListLoading(true);

    QUrlQuery ex;
    ex.addQueryItem("type", type);
    ex.addQueryItem("size", QString::number(ALBUM_LIST_PAGE_SIZE));
    if (offset > 0)
        ex.addQueryItem("offset", QString::number(offset));

    QNetworkRequest req(buildUrl("getAlbumList2", ex, true));
    auto *reply = m_nam.get(req);
    m_albumListReply = reply;

    connect(reply, &QNetworkReply::finished, this, [this, reply, type, offset]
            {
        if (reply != m_albumListReply) {
            reply->deleteLater();
            return;
        }
        m_albumListReply = nullptr;

        const auto error = reply->error();
        const QString errorString = reply->errorString();
        const QByteArray payload = (error == QNetworkReply::NoError) ? reply->readAll() : QByteArray();
        reply->deleteLater();

        if (error != QNetworkReply::NoError) {
            if (error != QNetworkReply::OperationCanceledError) {
                emit errorOccurred(errorString);
            }
            setAlbumListLoading(false);
            return;
        }

        const auto doc = QJsonDocument::fromJson(payload);
        QString err;
        if (!checkOk(doc, &err)) {
            emit errorOccurred(err);
            setAlbumListLoading(false);
            return;
        }

        auto root = doc.object().value("subsonic-response").toObject();
        auto albums = root.value("albumList2").toObject().value("album").toArray();

        if (offset == 0) {
            clearAndShrink(m_albumList);
        }

        if (!albums.isEmpty()) {
            m_albumList.reserve(m_albumList.size() + albums.size());
            for (const auto &av : albums) {
                auto a = av.toObject();
                m_albumList.push_back(QVariantMap{
                    {"id", internString(a.value("id").toString())},
                    {"name", internString(a.value("name").toString())},
                    {"artistId", internString(a.value("artistId").toString())},
                    {"artist", internString(a.value("artist").toString())},
                    {"year", a.value("year").toInt()},
                    {"coverArt", internString(a.value("coverArt").toString())}
                });
            }
        }

        std::sort(m_albumList.begin(), m_albumList.end(), [](const QVariant &v1, const QVariant &v2) {
            return v1.toMap().value("name").toString().localeAwareCompare(v2.toMap().value("name").toString()) < 0;
        });
        emit albumListChanged();

        const bool hasMore = albums.size() == ALBUM_LIST_PAGE_SIZE;
        setHasMoreAlbumList(hasMore);
        m_pendingAlbumListOffset = offset + albums.size();

        if (m_cacheManager) {
            m_cacheManager->saveList(cacheKey(QStringLiteral("albumList:%1").arg(type)), m_albumList);
        }

        setAlbumListLoading(false); });
}

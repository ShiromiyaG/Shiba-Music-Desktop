#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QJsonDocument>
#include <QUrlQuery>

class CacheManager;

class SubsonicClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString serverUrl READ serverUrl WRITE setServerUrl NOTIFY serverUrlChanged)
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY usernameChanged)
    Q_PROPERTY(bool authenticated READ isAuthenticated NOTIFY authenticatedChanged)
    Q_PROPERTY(QVariantList artists READ artists NOTIFY artistsChanged)
    Q_PROPERTY(QVariantList albums READ albums NOTIFY albumsChanged)
    Q_PROPERTY(QVariantList albumList READ albumList NOTIFY albumListChanged)
    Q_PROPERTY(QVariantList tracks READ tracks NOTIFY tracksChanged)
    Q_PROPERTY(QVariantList searchArtists READ searchArtists NOTIFY searchArtistsChanged)
    Q_PROPERTY(QVariantList searchAlbums READ searchAlbums NOTIFY searchAlbumsChanged)
    Q_PROPERTY(QVariantList recentlyPlayedAlbums READ recentlyPlayedAlbums NOTIFY recentlyPlayedAlbumsChanged)
    Q_PROPERTY(QVariantList randomSongs READ randomSongs NOTIFY randomSongsChanged)
    Q_PROPERTY(QVariantList favorites READ favorites NOTIFY favoritesChanged)
    Q_PROPERTY(QVariantList playlists READ playlists NOTIFY playlistsChanged)
    Q_PROPERTY(QString artistCover READ artistCover NOTIFY artistCoverChanged)
public:
    explicit SubsonicClient(QObject *parent = nullptr);

    void addToRecentlyPlayed(const QVariantMap &track);

    QString serverUrl() const { return m_server; }
    QString username() const { return m_user; }
    bool isAuthenticated() const { return m_authenticated; }

    void setServerUrl(const QString &url);
    void setUsername(const QString &u);
    void setCacheManager(CacheManager *cache);

    Q_INVOKABLE void login(const QString &url, const QString &user, const QString &password);
    Q_INVOKABLE void logout();
    Q_INVOKABLE void fetchArtists();
    Q_INVOKABLE void fetchArtist(const QString &artistId);
    Q_INVOKABLE void fetchAlbum(const QString &albumId);
    Q_INVOKABLE void fetchAlbumList(const QString &type = "random");
    Q_INVOKABLE void fetchRandomSongs();
    Q_INVOKABLE void fetchFavorites();
    Q_INVOKABLE void fetchPlaylists();
    Q_INVOKABLE void fetchPlaylist(const QString &playlistId);
    Q_INVOKABLE void search(const QString &term);
    Q_INVOKABLE void star(const QString &id);
    Q_INVOKABLE void unstar(const QString &id);

    Q_INVOKABLE void saveCredentials(const QString &url, const QString &user, const QString &password, bool remember = true);
    Q_INVOKABLE QVariantMap loadCredentials();
    Q_INVOKABLE QVariantList savedCredentials();
    Q_INVOKABLE void removeCredentials(const QString &credentialKey);

    Q_INVOKABLE QUrl streamUrl(const QString &songId, int maxBitrateKbps = 0) const;
    Q_INVOKABLE QUrl coverArtUrl(const QString &artId, int size = 300) const;
    Q_INVOKABLE void scrobble(const QString &songId, bool submission, qint64 timeMs = 0);
    Q_INVOKABLE QVariantList artists() const { return m_artists; }
    Q_INVOKABLE QVariantList albums() const { return m_albums; }
    Q_INVOKABLE QVariantList albumList() const { return m_albumList; }
    Q_INVOKABLE QVariantList tracks() const { return m_tracks; }
    Q_INVOKABLE QVariantList searchArtists() const { return m_searchArtists; }
    Q_INVOKABLE QVariantList searchAlbums() const { return m_searchAlbums; }
    Q_INVOKABLE QVariantList recentlyPlayedAlbums() const { return m_recentlyPlayedAlbums; }
    Q_INVOKABLE QVariantList randomSongs() const { return m_randomSongs; }
    Q_INVOKABLE QVariantList favorites() const { return m_favorites; }
    Q_INVOKABLE QVariantList playlists() const { return m_playlists; }
    QString artistCover() const { return m_artistCover; }
    Q_INVOKABLE void clearTracks()
    {
        if (!m_tracks.isEmpty())
        {
            m_tracks.clear();
            emit tracksChanged();
        }
    }

signals:
    void serverUrlChanged();
    void usernameChanged();
    void authenticatedChanged();
    void errorOccurred(const QString &message);
    void loginFailed(const QString &message);
    void artistsChanged();
    void albumsChanged();
    void albumListChanged();
    void tracksChanged();
    void searchArtistsChanged();
    void searchAlbumsChanged();
    void recentlyPlayedAlbumsChanged();
    void randomSongsChanged();
    void favoritesChanged();
    void playlistsChanged();
    void artistCoverChanged();

private:
    enum class AuthMode
    {
        Token,
        Legacy
    };
    QUrl buildUrl(const QString &method, const QUrlQuery &extra = {}, bool isJson = true) const;
    QString randomSalt() const;
    QString md5(const QString &s) const;
    bool checkOk(const QJsonDocument &doc, QString *err = nullptr, int *code = nullptr) const;

    void loadRecentlyPlayed();
    void saveRecentlyPlayed();
    void fetchAlbumTracksAndAppend(const QString &albumId);

    void setAuthenticated(bool ok);
    void fetchAlbumListPage(const QString &type, int offset);
    QString cacheKey(const QString &base) const;

    QString m_server, m_user, m_token, m_salt;
    bool m_authenticated = false;
    QString m_passwordHex;
    AuthMode m_authMode = AuthMode::Token;
    QNetworkAccessManager m_nam;
    QNetworkReply *m_artistReply = nullptr;
    QNetworkReply *m_albumListReply = nullptr;
    QNetworkReply *m_albumReply = nullptr;
    QNetworkReply *m_randomSongsReply = nullptr;
    QNetworkReply *m_favoritesReply = nullptr;
    QNetworkReply *m_playlistsReply = nullptr;
    QNetworkReply *m_playlistReply = nullptr;

    QVariantList m_artists, m_albums, m_albumList, m_tracks, m_searchArtists, m_searchAlbums, m_recentlyPlayedAlbums, m_randomSongs, m_favorites, m_playlists;
    QString m_artistCover;
    QString m_pendingAlbumListType;
    int m_pendingAlbumListOffset = 0;
    bool m_albumListPaging = false;
    CacheManager *m_cacheManager = nullptr;
};

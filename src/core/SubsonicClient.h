#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QJsonDocument>
#include <QUrlQuery>

class SubsonicClient : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString serverUrl READ serverUrl WRITE setServerUrl NOTIFY serverUrlChanged)
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY usernameChanged)
    Q_PROPERTY(bool authenticated READ isAuthenticated NOTIFY authenticatedChanged)
    Q_PROPERTY(QVariantList artists READ artists NOTIFY artistsChanged)
    Q_PROPERTY(QVariantList albums READ albums NOTIFY albumsChanged)
    Q_PROPERTY(QVariantList albumList READ albumList NOTIFY albumListChanged)
    Q_PROPERTY(QVariantList tracks READ tracks NOTIFY tracksChanged)
public:
    explicit SubsonicClient(QObject *parent=nullptr);

    QString serverUrl() const { return m_server; }
    QString username()  const { return m_user; }
    bool isAuthenticated() const { return m_authenticated; }

    void setServerUrl(const QString& url);
    void setUsername(const QString& u);

    Q_INVOKABLE void login(const QString& url, const QString& user, const QString& password);
    Q_INVOKABLE void fetchArtists();
    Q_INVOKABLE void fetchArtist(const QString& artistId);
    Q_INVOKABLE void fetchAlbum(const QString& albumId);
    Q_INVOKABLE void fetchAlbumList(const QString& type = "random");
    Q_INVOKABLE void search(const QString& term);

    Q_INVOKABLE QUrl streamUrl(const QString& songId, int maxBitrateKbps = 0) const;
    Q_INVOKABLE QUrl coverArtUrl(const QString& artId, int size = 300) const;
    Q_INVOKABLE void scrobble(const QString& songId, bool submission, qint64 timeMs = 0);
    Q_INVOKABLE QVariantList artists() const { return m_artists; }
    Q_INVOKABLE QVariantList albums()  const { return m_albums; }
    Q_INVOKABLE QVariantList albumList() const { return m_albumList; }
    Q_INVOKABLE QVariantList tracks()  const { return m_tracks; }
    Q_INVOKABLE void clearTracks() { if (!m_tracks.isEmpty()) { m_tracks.clear(); emit tracksChanged(); } }

signals:
    void serverUrlChanged();
    void usernameChanged();
    void authenticatedChanged();
    void errorOccurred(const QString& message);
    void artistsChanged();
    void albumsChanged();
    void albumListChanged();
    void tracksChanged();

private:
    QUrl buildUrl(const QString& method, const QUrlQuery& extra = {}, bool isJson = true) const;
    QString randomSalt() const;
    QString md5(const QString& s) const;
    bool checkOk(const QJsonDocument& doc, QString *err = nullptr) const;

    void setAuthenticated(bool ok);

    QString m_server, m_user, m_token, m_salt;
    bool m_authenticated = false;
    QNetworkAccessManager m_nam;
    QNetworkReply* m_artistReply = nullptr;
    QNetworkReply* m_albumListReply = nullptr;
    QNetworkReply* m_albumReply = nullptr;

    QVariantList m_artists, m_albums, m_albumList, m_tracks;
};

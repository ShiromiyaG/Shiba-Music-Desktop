#pragma once

#include <QObject>
#include <QString>

class QByteArray;
class QJsonObject;
class QTimer;

class DiscordRPC : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool showPaused READ showPaused WRITE setShowPaused NOTIFY showPausedChanged)
    Q_PROPERTY(QString clientId READ clientId WRITE setClientId NOTIFY clientIdChanged)
public:
    explicit DiscordRPC(QObject *parent = nullptr);
    ~DiscordRPC();

    bool enabled() const { return m_enabled; }
    void setEnabled(bool enabled);
    bool showPaused() const { return m_showPaused; }
    void setShowPaused(bool show);
    QString clientId() const { return m_clientId; }
    void setClientId(const QString &id);

    Q_INVOKABLE void updatePresence(const QString &title, const QString &artist,
                                    const QString &album, bool playing,
                                    qint64 position, qint64 duration,
                                    const QString &coverArtUrl = QString(),
                                    const QString &trackId = QString());
    Q_INVOKABLE void clearPresence();

signals:
    void enabledChanged();
    void showPausedChanged();
    void clientIdChanged();
    void ready();
    void disconnected(int errorCode, const QString &message);

private:
    void initialize();
    void shutdown();
    void resetLastPresence();
    bool ensureConnection();
    bool openIpcConnection();
    bool sendHandshake();
    bool sendCommand(const QJsonObject &payload);
    bool sendActivityPayload(const QJsonObject &activity);
    bool writeFrame(quint32 opcode, const QByteArray &payload);
    bool readFrame(quint32 &opcode, QByteArray &payload);
    QByteArray readExact(qint64 size);
    void closeConnection();
    bool writeAll(const QByteArray &data);
    void processIncomingFrames();
    bool hasPendingFrame() const;

    bool m_enabled = true;
    bool m_initialized = false;
    bool m_showPaused = false;
    QString m_clientId;

    QString m_lastTitle;
    QString m_lastArtist;
    QString m_lastAlbum;
    QString m_lastCoverUrl;
    QString m_lastTrackId;
    bool m_lastPlaying = false;
    qint64 m_lastPosition = 0;
    qint64 m_lastDuration = 0;
    qintptr m_ipcHandle = -1;
    bool m_connectionReady = false;
    QTimer *m_pollTimer = nullptr;
};

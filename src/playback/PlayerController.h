#pragma once
#include <QObject>
#include <QVariant>
#include <QSettings>
#include "MpvPlayer.h"

class SubsonicClient;
class DiscordRPC;
class MediaControls;

class PlayerController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap currentTrack READ currentTrack NOTIFY currentTrackChanged)
    Q_PROPERTY(QVariantList queue READ queue NOTIFY queueChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool muted READ muted WRITE setMuted NOTIFY mutedChanged)
    Q_PROPERTY(bool replayGainEnabled READ replayGainEnabled WRITE setReplayGainEnabled NOTIFY replayGainEnabledChanged)
    Q_PROPERTY(int replayGainMode READ replayGainMode WRITE setReplayGainMode NOTIFY replayGainModeChanged)
    Q_PROPERTY(bool shuffleEnabled READ shuffleEnabled WRITE setShuffleEnabled NOTIFY shuffleEnabledChanged)
    Q_PROPERTY(int repeatMode READ repeatMode WRITE setRepeatMode NOTIFY repeatModeChanged)
public:
    explicit PlayerController(SubsonicClient *api, DiscordRPC *discord, QObject *parent=nullptr);

    QVariantMap currentTrack() const { return m_current; }
    QVariantList queue() const { return m_queue; }
    bool playing() const { return !m_mpv->isPaused(); }
    qint64 position() const { return m_mpv->position(); }
    qint64 duration() const { return m_mpv->duration(); }
    qreal volume() const { return m_volume; }
    void setVolume(qreal v);
    bool muted() const { return m_muted; }
    void setMuted(bool m);
    bool replayGainEnabled() const { return m_replayGainEnabled; }
    void setReplayGainEnabled(bool enabled);
    int replayGainMode() const { return m_replayGainMode; }
    void setReplayGainMode(int mode);
    bool shuffleEnabled() const { return m_shuffleEnabled; }
    void setShuffleEnabled(bool enabled);
    int repeatMode() const { return m_repeatMode; }
    void setRepeatMode(int mode);

    Q_INVOKABLE void playAlbum(const QVariantList& tracks, int index = 0);
    Q_INVOKABLE void addToQueue(const QVariantMap& track);
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void toggle();
    Q_INVOKABLE void seek(qint64 ms);
    Q_INVOKABLE void playFromQueue(int index);
    Q_INVOKABLE void removeFromQueue(int index);
    Q_INVOKABLE void clearQueue();
    Q_INVOKABLE void playCurrentTracks(int index = 0);
    Q_INVOKABLE void playTrack(const QVariantMap &track, int indexHint = -1);
    Q_INVOKABLE void toggleShuffle();
    Q_INVOKABLE void cycleRepeatMode();

    enum RepeatMode {
        RepeatOff = 0,
        RepeatAll = 1,
        RepeatOne = 2
    };
    Q_ENUM(RepeatMode)

signals:
    void currentTrackChanged();
    void queueChanged();
    void playingChanged();
    void positionChanged();
    void durationChanged();
    void volumeChanged();
    void mutedChanged();
    void replayGainEnabledChanged();
    void replayGainModeChanged();
    void shuffleEnabledChanged();
    void repeatModeChanged();

private slots:
    void onEndOfFile();
    void onPlaylistPosChanged(int pos);

private:
    void rebuildPlaylist();
    void updateVolume();
    void updateDiscordPresence();
    void applyShuffleOrder();
    void applyQueueOrder(const QVariantList &newOrder, int newCurrentIndex);
    void syncMpvPlaylistOrder(const QVector<QString> &oldOrderIds, const QVector<QString> &newOrderIds);

    SubsonicClient *m_api;
    MpvPlayer *m_mpv;
    DiscordRPC *m_discord;
    MediaControls *m_mediaControls;
    
    int m_index = -1;
    QVariantList m_queue;
    QVariantMap m_current;
    qreal m_volume = 1.0;
    bool m_muted = false;
    bool m_replayGainEnabled = true;
    int m_replayGainMode = 1;
    int m_lastPlaylistPos = -1;
    bool m_shuffleEnabled = false;
    int m_repeatMode = RepeatOff;
    QVariantList m_originalQueue;
};

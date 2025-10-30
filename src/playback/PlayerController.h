#pragma once
#include <QObject>
#include <QVariant>
#include <QMediaPlayer>
#include <QAudioOutput>

class SubsonicClient;

class PlayerController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap currentTrack READ currentTrack NOTIFY currentTrackChanged)
    Q_PROPERTY(QVariantList queue READ queue NOTIFY queueChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(bool crossfade READ crossfade WRITE setCrossfade NOTIFY crossfadeChanged)
    Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool muted READ muted WRITE setMuted NOTIFY mutedChanged)
    Q_PROPERTY(bool replayGainEnabled READ replayGainEnabled WRITE setReplayGainEnabled NOTIFY replayGainEnabledChanged)
    Q_PROPERTY(int replayGainMode READ replayGainMode WRITE setReplayGainMode NOTIFY replayGainModeChanged)
public:
    explicit PlayerController(SubsonicClient *api, QObject *parent=nullptr);

    QVariantMap currentTrack() const { return m_current; }
    QVariantList queue() const { return m_queue; }
    bool playing() const { return m_active->playbackState() == QMediaPlayer::PlayingState; }
    qint64 position() const { return m_active->position(); }
    qint64 duration() const { return m_active->duration(); }
    bool crossfade() const { return m_crossfade; }
    void setCrossfade(bool on) { if (m_crossfade != on) { m_crossfade = on; emit crossfadeChanged(); } }
    qreal volume() const { return m_volume; }
    void setVolume(qreal v);
    bool muted() const { return m_muted; }
    void setMuted(bool m);
    bool replayGainEnabled() const { return m_replayGainEnabled; }
    void setReplayGainEnabled(bool enabled);
    int replayGainMode() const { return m_replayGainMode; }
    void setReplayGainMode(int mode);

    Q_INVOKABLE void playTrack(const QVariantMap& track, int maxBitrateKbps = 0);
    Q_INVOKABLE void addToQueue(const QVariantMap& track);
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void toggle();
    Q_INVOKABLE void seek(qint64 ms);
    Q_INVOKABLE void playFromQueue(int index);
    Q_INVOKABLE void removeFromQueue(int index);
    Q_INVOKABLE void clearQueue();

signals:
    void currentTrackChanged();
    void queueChanged();
    void playingChanged();
    void positionChanged();
    void durationChanged();
    void crossfadeChanged();
    void volumeChanged();
    void mutedChanged();
    void replayGainEnabledChanged();
    void replayGainModeChanged();

private:
    void playInternal(int index);
    void setupPlayerConnections(QMediaPlayer *p);
    void applySource(QMediaPlayer *p, const QUrl& url);

    SubsonicClient *m_api;

    QMediaPlayer m_playerA;
    QMediaPlayer m_playerB;
    QAudioOutput m_outA;
    QAudioOutput m_outB;
    QMediaPlayer *m_active = &m_playerA;
    QMediaPlayer *m_inactive = &m_playerB;

    bool m_crossfade = true;
    int m_index = -1;
    QVariantList m_queue;
    QVariantMap m_current;
    qreal m_volume = 0.5;
    bool m_muted = false;
    bool m_replayGainEnabled = true;
    int m_replayGainMode = 1; // 0 = track, 1 = album
};

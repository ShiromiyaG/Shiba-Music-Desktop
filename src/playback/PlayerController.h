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
public:
    explicit PlayerController(SubsonicClient *api, QObject *parent=nullptr);

    QVariantMap currentTrack() const { return m_current; }
    QVariantList queue() const { return m_queue; }
    bool playing() const { return m_active->playbackState() == QMediaPlayer::PlayingState; }
    qint64 position() const { return m_active->position(); }
    qint64 duration() const { return m_active->duration(); }
    bool crossfade() const { return m_crossfade; }
    void setCrossfade(bool on) { if (m_crossfade != on) { m_crossfade = on; emit crossfadeChanged(); } }

    Q_INVOKABLE void playTrack(const QVariantMap& track, int maxBitrateKbps = 0);
    Q_INVOKABLE void addToQueue(const QVariantMap& track);
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void toggle();
    Q_INVOKABLE void seek(qint64 ms);

signals:
    void currentTrackChanged();
    void queueChanged();
    void playingChanged();
    void positionChanged();
    void durationChanged();
    void crossfadeChanged();

private:
    void playFromQueue(int index);
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
};

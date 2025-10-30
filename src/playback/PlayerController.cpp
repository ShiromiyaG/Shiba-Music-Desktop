#include "PlayerController.h"
#include "../core/SubsonicClient.h"
#include <QPropertyAnimation>
#include <QDebug>

PlayerController::PlayerController(SubsonicClient *api, QObject *parent)
    : QObject(parent), m_api(api)
{
    m_playerA.setAudioOutput(&m_outA);
    m_playerB.setAudioOutput(&m_outB);

    m_outA.setVolume(m_volume);
    m_outB.setVolume(m_volume);

    setupPlayerConnections(&m_playerA);
    setupPlayerConnections(&m_playerB);
}

void PlayerController::setupPlayerConnections(QMediaPlayer *p) {
    connect(p, &QMediaPlayer::positionChanged, this, &PlayerController::positionChanged);
    connect(p, &QMediaPlayer::durationChanged, this, &PlayerController::durationChanged);
    connect(p, &QMediaPlayer::playbackStateChanged, this, &PlayerController::playingChanged);
    connect(p, &QMediaPlayer::mediaStatusChanged, this, [this, p](QMediaPlayer::MediaStatus s){
        if (p == m_active && s == QMediaPlayer::EndOfMedia) next();
    });
}

void PlayerController::applySource(QMediaPlayer *p, const QUrl& url) {
    p->setSource(url);
}

void PlayerController::playTrack(const QVariantMap& track, int maxBitrateKbps) {
    Q_UNUSED(maxBitrateKbps);
    m_queue.clear();
    m_queue.push_back(track);
    emit queueChanged();
    m_index = 0;
    playInternal(m_index);
}

void PlayerController::addToQueue(const QVariantMap& track) {
    m_queue.push_back(track);
    emit queueChanged();
    if (m_index < 0) { m_index = 0; playInternal(m_index); }
}

void PlayerController::playInternal(int index) {
    if (index < 0 || index >= m_queue.size()) return;
    m_index = index;
    m_current = m_queue[m_index].toMap();
    emit currentTrackChanged();

    m_api->addToRecentlyPlayed(m_current);

    const auto id = m_current.value("id").toString();
    const QUrl src = m_api->streamUrl(id);
    m_api->scrobble(id, /*submission*/true, 0);

    qreal targetVolume = 1.0;
    if (m_replayGainEnabled) {
        const QString gainKey = (m_replayGainMode == 1) ? "replayGainAlbumGain" : "replayGainTrackGain";
        if (m_current.contains(gainKey)) {
            const qreal gainDb = m_current.value(gainKey).toDouble();
            if (qAbs(gainDb) > 0.01) {
                targetVolume = qPow(10.0, gainDb / 20.0);
                targetVolume = qBound(0.1, targetVolume, 2.0);
            }
        }
    }


    const qreal finalVolume = targetVolume * m_volume;
    
    if (m_crossfade && m_active->playbackState() == QMediaPlayer::PlayingState) {
        applySource(m_inactive, src);
        m_inactive->play();
        QPropertyAnimation *aOut = new QPropertyAnimation(m_active->audioOutput(), "volume", this);
        aOut->setDuration(1200);
        aOut->setStartValue(m_active->audioOutput()->volume());
        aOut->setEndValue(0.0);
        QPropertyAnimation *aIn = new QPropertyAnimation(m_inactive->audioOutput(), "volume", this);
        aIn->setDuration(1200);
        aIn->setStartValue(0.0);
        aIn->setEndValue(finalVolume);
        connect(aOut, &QPropertyAnimation::finished, this, [this]{
            m_active->stop();
            std::swap(m_active, m_inactive);
            emit playingChanged();
        });
        aOut->start(QAbstractAnimation::DeleteWhenStopped);
        aIn->start(QAbstractAnimation::DeleteWhenStopped);
    } else {
        applySource(m_active, src);
        m_active->play();
        m_active->audioOutput()->setVolume(finalVolume);
        m_inactive->audioOutput()->setVolume(0.0);
    }
}

void PlayerController::next() {
    if (m_index+1 < m_queue.size()) {
        const auto id = m_current.value("id").toString();
        if (!id.isEmpty()) m_api->scrobble(id, /*submission*/true, m_active->position());
        playInternal(m_index+1);
    } else {
        m_active->stop();
        emit playingChanged();
    }
}

void PlayerController::previous() {
    if (m_active->position() > 5000) {
        m_active->setPosition(0);
        return;
    }
    if (m_index-1 >= 0) playInternal(m_index-1);
}

void PlayerController::toggle() {
    if (m_active->playbackState() == QMediaPlayer::PlayingState) m_active->pause();
    else m_active->play();
    emit playingChanged();
}

void PlayerController::seek(qint64 ms) {
    m_active->setPosition(ms);
}

void PlayerController::playFromQueue(int index) {
    playInternal(index);
}

void PlayerController::removeFromQueue(int index) {
    if (index < 0 || index >= m_queue.size()) return;

    const bool wasCurrent = (index == m_index);
    const bool beforeCurrent = (index < m_index);
    m_queue.removeAt(index);
    emit queueChanged();

    if (m_queue.isEmpty()) {
        m_index = -1;
        m_current.clear();
        m_active->stop();
        emit currentTrackChanged();
        emit playingChanged();
        return;
    }

    if (beforeCurrent) {
        --m_index;
    } else if (wasCurrent) {
        if (m_index >= m_queue.size())
            m_index = m_queue.size() - 1;
        playInternal(m_index);
        return;
    }

    m_current = m_queue[m_index].toMap();
    emit currentTrackChanged();
}

void PlayerController::clearQueue() {
    if (m_queue.isEmpty()) return;
    m_queue.clear();
    m_index = -1;
    m_current.clear();
    m_active->stop();
    emit queueChanged();
    emit currentTrackChanged();
    emit playingChanged();
}

void PlayerController::setVolume(qreal v) {
    if (v < 0.0) v = 0.0;
    if (v > 1.0) v = 1.0;
    if (qAbs(m_volume - v) < 0.001) return;
    m_volume = v;
    if (!m_muted) {
        qreal targetVolume = 1.0;
        if (m_replayGainEnabled && !m_current.isEmpty()) {
            const QString gainKey = (m_replayGainMode == 1) ? "replayGainAlbumGain" : "replayGainTrackGain";
            if (m_current.contains(gainKey)) {
                const qreal gainDb = m_current.value(gainKey).toDouble();
                if (qAbs(gainDb) > 0.01) {
                    targetVolume = qPow(10.0, gainDb / 20.0);
                    targetVolume = qBound(0.1, targetVolume, 2.0);
                }
            }
        }
        const qreal finalVolume = targetVolume * m_volume;
        m_outA.setVolume(finalVolume);
        m_outB.setVolume(finalVolume);
    }
    emit volumeChanged();
}

void PlayerController::setMuted(bool m) {
    if (m_muted == m) return;
    m_muted = m;
    m_outA.setVolume(m_muted ? 0.0 : m_volume);
    m_outB.setVolume(m_muted ? 0.0 : m_volume);
    emit mutedChanged();
}

void PlayerController::setReplayGainEnabled(bool enabled) {
    if (m_replayGainEnabled == enabled) return;
    m_replayGainEnabled = enabled;
    emit replayGainEnabledChanged();
    if (!m_muted && !m_current.isEmpty()) {
        qreal targetVolume = 1.0;
        if (m_replayGainEnabled) {
            const QString gainKey = (m_replayGainMode == 1) ? "replayGainAlbumGain" : "replayGainTrackGain";
            if (m_current.contains(gainKey)) {
                const qreal gainDb = m_current.value(gainKey).toDouble();
                if (qAbs(gainDb) > 0.01) {
                    targetVolume = qPow(10.0, gainDb / 20.0);
                    targetVolume = qBound(0.1, targetVolume, 2.0);
                }
            }
        }
        m_outA.setVolume(targetVolume * m_volume);
        m_outB.setVolume(targetVolume * m_volume);
    }
}

void PlayerController::setReplayGainMode(int mode) {
    if (m_replayGainMode == mode) return;
    m_replayGainMode = mode;
    emit replayGainModeChanged();
    if (!m_muted && m_replayGainEnabled && !m_current.isEmpty()) {
        qreal targetVolume = 1.0;
        const QString gainKey = (m_replayGainMode == 1) ? "replayGainAlbumGain" : "replayGainTrackGain";
        if (m_current.contains(gainKey)) {
            const qreal gainDb = m_current.value(gainKey).toDouble();
            if (qAbs(gainDb) > 0.01) {
                targetVolume = qPow(10.0, gainDb / 20.0);
                targetVolume = qBound(0.1, targetVolume, 2.0);
            }
        }
        m_outA.setVolume(targetVolume * m_volume);
        m_outB.setVolume(targetVolume * m_volume);
    }
}

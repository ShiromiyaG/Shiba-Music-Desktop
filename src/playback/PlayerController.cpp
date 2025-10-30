#include "PlayerController.h"
#include "../core/SubsonicClient.h"
#include <QPropertyAnimation>

PlayerController::PlayerController(SubsonicClient *api, QObject *parent)
    : QObject(parent), m_api(api)
{
    m_playerA.setAudioOutput(&m_outA);
    m_playerB.setAudioOutput(&m_outB);

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
    // scrobble start
    m_api->scrobble(id, /*submission*/true, 0);

    if (m_crossfade && m_active->playbackState() == QMediaPlayer::PlayingState) {
        applySource(m_inactive, src);
        m_inactive->play();
        // fade in/out
        QPropertyAnimation *aOut = new QPropertyAnimation(m_active->audioOutput(), "volume", this);
        aOut->setDuration(1200);
        aOut->setStartValue(1.0);
        aOut->setEndValue(0.0);
        QPropertyAnimation *aIn = new QPropertyAnimation(m_inactive->audioOutput(), "volume", this);
        aIn->setDuration(1200);
        aIn->setStartValue(0.0);
        aIn->setEndValue(1.0);
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
        m_active->audioOutput()->setVolume(1.0);
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

#include "PlayerController.h"
#include "../core/SubsonicClient.h"
#include "../discord/DiscordRPC.h"
#include <QDebug>
#include <QtMath>

PlayerController::PlayerController(SubsonicClient *api, QObject *parent)
    : QObject(parent), m_api(api), m_mpv(new MpvPlayer(this)), m_discord(new DiscordRPC(this))
{
    connect(m_mpv, &MpvPlayer::positionChanged, this, &PlayerController::positionChanged);
    connect(m_mpv, &MpvPlayer::durationChanged, this, &PlayerController::durationChanged);
    connect(m_mpv, &MpvPlayer::playbackStateChanged, this, [this]() {
        emit playingChanged();
        updateDiscordPresence();
    });
    connect(m_mpv, &MpvPlayer::endOfFile, this, &PlayerController::onEndOfFile);
    connect(m_mpv, &MpvPlayer::playlistPosChanged, this, &PlayerController::onPlaylistPosChanged);
    
    updateVolume();
}

void PlayerController::playAlbum(const QVariantList& tracks, int index) {
    if (tracks.isEmpty() || index < 0 || index >= tracks.size()) {
        return;
    }
    m_queue = tracks;
    emit queueChanged();
    m_index = index;
    m_current = tracks.at(index).toMap();
    emit currentTrackChanged();
    rebuildPlaylist();
    updateDiscordPresence();
}

void PlayerController::addToQueue(const QVariantMap& track) {
    m_queue.push_back(track);
    emit queueChanged();
    if (m_index < 0) {
        m_index = 0;
        m_current = track;
        emit currentTrackChanged();
        rebuildPlaylist();
    } else {
        const auto id = track.value("id").toString();
        const QString url = m_api->streamUrl(id).toString();
        m_mpv->command(QVariantList{"loadfile", url, "append"});
    }
}

void PlayerController::rebuildPlaylist() {
    m_lastPlaylistPos = -1;
    m_mpv->command(QVariantList{"stop"});
    m_mpv->command(QVariantList{"playlist-clear"});
    
    for (int i = 0; i < m_queue.size(); ++i) {
        const auto track = m_queue[i].toMap();
        const auto id = track.value("id").toString();
        const QString url = m_api->streamUrl(id).toString();
        m_mpv->command(QVariantList{"loadfile", url, "append"});
    }
    
    if (m_index >= 0 && m_index < m_queue.size()) {
        m_mpv->setProperty("playlist-pos", m_index);
        m_mpv->setProperty("pause", false);
        updateVolume();
        
        m_api->addToRecentlyPlayed(m_current);
        const auto id = m_current.value("id").toString();
        m_api->scrobble(id, true, 0);
    }
}

void PlayerController::next() {
    if (m_index + 1 < m_queue.size()) {
        const auto id = m_current.value("id").toString();
        if (!id.isEmpty()) m_api->scrobble(id, true, m_mpv->position());
        
        m_index++;
        m_current = m_queue[m_index].toMap();
        emit currentTrackChanged();
        m_mpv->command(QVariantList{"playlist-next"});
        
        m_api->addToRecentlyPlayed(m_current);
        m_api->scrobble(m_current.value("id").toString(), true, 0);
    }
}

void PlayerController::previous() {
    if (m_mpv->position() > 5000) {
        m_mpv->setProperty("time-pos", 0.0);
        return;
    }
    if (m_index > 0) {
        m_index--;
        m_current = m_queue[m_index].toMap();
        emit currentTrackChanged();
        m_mpv->command(QVariantList{"playlist-prev"});
        
        m_api->addToRecentlyPlayed(m_current);
        m_api->scrobble(m_current.value("id").toString(), true, 0);
    }
}

void PlayerController::toggle() {
    if (m_queue.isEmpty() || m_index < 0) return;
    bool paused = m_mpv->isPaused();
    m_mpv->setProperty("pause", !paused);
    updateDiscordPresence();
}

void PlayerController::seek(qint64 ms) {
    m_mpv->setProperty("time-pos", ms / 1000.0);
}

void PlayerController::playFromQueue(int index) {
    if (index < 0 || index >= m_queue.size()) return;
    m_index = index;
    m_current = m_queue[m_index].toMap();
    emit currentTrackChanged();
    m_mpv->setProperty("playlist-pos", index);
    
    m_api->addToRecentlyPlayed(m_current);
    m_api->scrobble(m_current.value("id").toString(), true, 0);
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
        m_mpv->command(QVariantList{"stop"});
        emit currentTrackChanged();
        emit playingChanged();
        return;
    }

    if (beforeCurrent) {
        --m_index;
    } else if (wasCurrent) {
        if (m_index >= m_queue.size())
            m_index = m_queue.size() - 1;
        m_current = m_queue[m_index].toMap();
        emit currentTrackChanged();
    }
    
    rebuildPlaylist();
}

void PlayerController::clearQueue() {
    if (m_queue.isEmpty()) return;
    m_queue.clear();
    m_index = -1;
    m_current.clear();
    m_mpv->command(QVariantList{"stop"});
    emit queueChanged();
    emit currentTrackChanged();
    emit playingChanged();
    m_discord->clearPresence();
}

void PlayerController::setVolume(qreal v) {
    v = qBound(0.0, v, 1.0);
    if (qAbs(m_volume - v) < 0.001) return;
    m_volume = v;
    updateVolume();
    emit volumeChanged();
}

void PlayerController::setMuted(bool m) {
    if (m_muted == m) return;
    m_muted = m;
    updateVolume();
    emit mutedChanged();
}

void PlayerController::setReplayGainEnabled(bool enabled) {
    if (m_replayGainEnabled == enabled) return;
    m_replayGainEnabled = enabled;
    updateVolume();
    emit replayGainEnabledChanged();
}

void PlayerController::setReplayGainMode(int mode) {
    if (m_replayGainMode == mode) return;
    m_replayGainMode = mode;
    updateVolume();
    emit replayGainModeChanged();
}

void PlayerController::updateVolume() {
    if (m_muted) {
        m_mpv->setVolume(0.0);
        return;
    }
    
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
    
    m_mpv->setVolume(targetVolume * m_volume * 200.0);
}

void PlayerController::onPlaylistPosChanged(int pos) {
    qDebug() << "[CTRL] onPlaylistPosChanged:" << pos << "current m_index:" << m_index;
    if (pos == -1) {
        qDebug() << "[CTRL] Playlist ended";
        return;
    }
    
    if (pos < 0 || pos >= m_queue.size()) {
        qDebug() << "[CTRL] Invalid pos, ignoring";
        return;
    }
    if (pos == m_index) {
        qDebug() << "[CTRL] Same pos, ignoring";
        return;
    }
    
    const auto oldId = m_current.value("id").toString();
    if (!oldId.isEmpty() && m_index >= 0) {
        m_api->scrobble(oldId, true, 0);
    }
    
    qDebug() << "[CTRL] Changing track from" << m_index << "to" << pos;
    m_index = pos;
    m_current = m_queue[m_index].toMap();
    emit currentTrackChanged();
    
    m_api->addToRecentlyPlayed(m_current);
    m_api->scrobble(m_current.value("id").toString(), true, 0);
    updateVolume();
}

void PlayerController::onEndOfFile() {
    // Não fazer nada aqui - deixar onPlaylistPosChanged gerenciar
}

void PlayerController::updateDiscordPresence() {
    if (m_current.isEmpty()) {
        m_discord->clearPresence();
        return;
    }
    
    QString title = m_current.value("title").toString();
    QString artist = m_current.value("artist").toString();
    QString album = m_current.value("album").toString();
    
    m_discord->updatePresence(title, artist, album, playing(), position(), duration());
}

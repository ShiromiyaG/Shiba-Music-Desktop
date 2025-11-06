#include "PlayerController.h"
#include "../core/SubsonicClient.h"
#include "../discord/DiscordRPC.h"
#include "MediaControls.h"
#include <QDebug>
#include <QtMath>
#include <QRandomGenerator>
#include <QVector>

namespace {
QString trackIdFromVariant(const QVariant &variant)
{
    return variant.toMap().value(QStringLiteral("id")).toString();
}
}

PlayerController::PlayerController(SubsonicClient *api, DiscordRPC *discord, QObject *parent)
    : QObject(parent), m_api(api), m_mpv(new MpvPlayer(this)), m_discord(discord), m_mediaControls(nullptr)
{
    Q_ASSERT(m_discord);
    
    m_mediaControls = new MediaControls(this, this);
    
    connect(m_mpv, &MpvPlayer::positionChanged, this, &PlayerController::positionChanged);
    connect(m_mpv, &MpvPlayer::durationChanged, this, [this](qint64) {
        emit durationChanged();
        updateDiscordPresence();
    });
    connect(m_mpv, &MpvPlayer::playbackStateChanged, this, [this]() {
        emit playingChanged();
        if (m_mediaControls) {
            m_mediaControls->updatePlaybackState(playing());
        }
        updateDiscordPresence();
    });
    connect(m_mpv, &MpvPlayer::endOfFile, this, &PlayerController::onEndOfFile);
    connect(m_mpv, &MpvPlayer::playlistPosChanged, this, &PlayerController::onPlaylistPosChanged);
    
    QSettings settings;
    m_volume = settings.value("player/volume", 1.0).toDouble();
    m_replayGainEnabled = settings.value("player/replayGainEnabled", true).toBool();
    m_replayGainMode = settings.value("player/replayGainMode", 1).toInt();
    m_shuffleEnabled = settings.value("player/shuffleEnabled", false).toBool();
    const int storedRepeat = settings.value("player/repeatMode", static_cast<int>(RepeatOff)).toInt();
    m_repeatMode = RepeatOff;
    setRepeatMode(storedRepeat);
    
    // Initialize ReplayGain in MPV
    if (m_replayGainEnabled) {
        const QString mode = (m_replayGainMode == 1) ? "album" : "track";
        m_mpv->setReplayGainMode(mode);
    } else {
        m_mpv->setReplayGainMode("no");
    }
    
    updateVolume();
}

void PlayerController::playAlbum(const QVariantList& tracks, int index) {
    if (tracks.isEmpty() || index < 0 || index >= tracks.size()) {
        return;
    }
    m_queue = tracks;
    m_originalQueue = m_queue;
    if (m_shuffleEnabled && m_queue.size() > 1) {
        m_index = index;
        m_current = m_queue[m_index].toMap();
        applyShuffleOrder();
        return;
    }
    emit queueChanged();
    m_index = index;
    m_current = tracks.at(index).toMap();
    emit currentTrackChanged();
    if (m_mediaControls) {
        m_mediaControls->updateMetadata(m_current);
    }
    rebuildPlaylist();
    updateDiscordPresence();
}

void PlayerController::addToQueue(const QVariantMap& track) {
    m_queue.push_back(track);
    if (m_shuffleEnabled) {
        m_originalQueue.push_back(track);
        if (m_queue.size() > 1) {
            if (!m_current.isEmpty()) {
                const QString currentId = m_current.value("id").toString();
                for (int i = 0; i < m_queue.size(); ++i) {
                    if (m_queue[i].toMap().value("id").toString() == currentId) {
                        m_index = i;
                        break;
                    }
                }
            }
            applyShuffleOrder();
            return;
        }
    } else {
        m_originalQueue = m_queue;
    }
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
        if (m_mediaControls) {
            m_mediaControls->updateMetadata(m_current);
        }
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
        if (m_mediaControls) {
            m_mediaControls->updateMetadata(m_current);
        }
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

    const QString removedId = m_queue[index].toMap().value("id").toString();
    const bool wasCurrent = (index == m_index);
    const bool beforeCurrent = (index < m_index);
    m_queue.removeAt(index);
    if (!removedId.isEmpty()) {
        for (int i = 0; i < m_originalQueue.size(); ++i) {
            if (m_originalQueue[i].toMap().value("id").toString() == removedId) {
                m_originalQueue.removeAt(i);
                break;
            }
        }
    }
    if (!m_shuffleEnabled) {
        m_originalQueue = m_queue;
    }
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
    m_originalQueue.clear();
    m_index = -1;
    m_current.clear();
    m_mpv->command(QVariantList{"stop"});
    if (m_mediaControls) {
        m_mediaControls->updatePlaybackState(false);
    }
    emit queueChanged();
    emit currentTrackChanged();
    emit playingChanged();
    m_discord->clearPresence();
}

void PlayerController::playCurrentTracks(int index)
{
    const QVariantList currentTracks = m_api->tracks();
    if (currentTracks.isEmpty()) {
        return;
    }
    if (index < 0 || index >= currentTracks.size()) {
        index = 0;
    }
    playAlbum(currentTracks, index);
}

void PlayerController::playTrack(const QVariantMap &track, int indexHint)
{
    Q_UNUSED(indexHint);
    if (track.isEmpty()) {
        return;
    }

    QVariantList singleTrackList;
    singleTrackList.append(track);
    playAlbum(singleTrackList, 0);
}

void PlayerController::toggleShuffle() {
    setShuffleEnabled(!m_shuffleEnabled);
}

void PlayerController::cycleRepeatMode() {
    int nextMode = m_repeatMode + 1;
    if (nextMode > RepeatOne)
        nextMode = RepeatOff;
    setRepeatMode(nextMode);
}

void PlayerController::setVolume(qreal v) {
    v = qBound(0.0, v, 1.0);
    if (qAbs(m_volume - v) < 0.001) return;
    m_volume = v;
    QSettings settings;
    settings.setValue("player/volume", m_volume);
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
    
    QSettings settings;
    settings.setValue("player/replayGainEnabled", enabled);
    
    if (enabled) {
        const QString mode = (m_replayGainMode == 1) ? "album" : "track";
        m_mpv->setReplayGainMode(mode);
    } else {
        m_mpv->setReplayGainMode("no");
    }
    
    updateVolume();
    emit replayGainEnabledChanged();
}

void PlayerController::setReplayGainMode(int mode) {
    if (m_replayGainMode == mode) return;
    m_replayGainMode = mode;
    
    QSettings settings;
    settings.setValue("player/replayGainMode", mode);
    
    if (m_replayGainEnabled) {
        const QString rgMode = (mode == 1) ? "album" : "track";
        m_mpv->setReplayGainMode(rgMode);
    }
    
    updateVolume();
    emit replayGainModeChanged();
}

void PlayerController::setShuffleEnabled(bool enabled) {
    if (m_shuffleEnabled == enabled)
        return;

    m_shuffleEnabled = enabled;
    QSettings settings;
    settings.setValue("player/shuffleEnabled", m_shuffleEnabled);

    if (m_shuffleEnabled) {
        if (m_originalQueue.isEmpty()) {
            m_originalQueue = m_queue;
        }
        applyShuffleOrder();
    } else {
        if (!m_originalQueue.isEmpty() && !m_queue.isEmpty()) {
            const QString currentId = m_current.value("id").toString();
            const QVariantList targetOrder = m_originalQueue;
            int targetIndex = 0;
            if (!currentId.isEmpty()) {
                for (int i = 0; i < targetOrder.size(); ++i) {
                    if (targetOrder[i].toMap().value("id").toString() == currentId) {
                        targetIndex = i;
                        break;
                    }
                }
            }
            applyQueueOrder(targetOrder, targetIndex);
        }
        m_originalQueue = m_queue;
    }

    emit shuffleEnabledChanged();
}

void PlayerController::setRepeatMode(int mode) {
    const int clamped = qBound(static_cast<int>(RepeatOff), mode, static_cast<int>(RepeatOne));
    const bool changed = (m_repeatMode != clamped);
    m_repeatMode = clamped;

    if (m_mpv) {
        switch (m_repeatMode) {
        case RepeatOff:
            m_mpv->setProperty("loop-file", "no");
            m_mpv->setProperty("loop-playlist", "no");
            break;
        case RepeatAll:
            m_mpv->setProperty("loop-file", "no");
            m_mpv->setProperty("loop-playlist", "inf");
            break;
        case RepeatOne:
            m_mpv->setProperty("loop-playlist", "no");
            m_mpv->setProperty("loop-file", "inf");
            break;
        }
    }

    if (changed) {
        QSettings settings;
        settings.setValue("player/repeatMode", m_repeatMode);
        emit repeatModeChanged();
    }
}

void PlayerController::updateVolume() {
    if (m_muted) {
        m_mpv->setVolume(0.0);
        return;
    }
    
    // MPV handles ReplayGain automatically from file tags
    // We just set the user volume
    m_mpv->setVolume(m_volume * 100.0);
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
    if (m_mediaControls) {
        m_mediaControls->updateMetadata(m_current);
    }
    
    m_api->addToRecentlyPlayed(m_current);
    m_api->scrobble(m_current.value("id").toString(), true, 0);
    updateVolume();
    updateDiscordPresence();
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
    const QString coverArtId = m_current.value("coverArt").toString();
    const QString coverUrl = m_api->coverArtUrl(coverArtId, 512).toString();
    const QString trackId = m_current.value("id").toString();
    
    m_discord->updatePresence(title, artist, album, playing(), position(), duration(), coverUrl, trackId);
}

void PlayerController::applyShuffleOrder() {
    if (!m_shuffleEnabled || m_queue.size() <= 1 || m_index < 0 || m_index >= m_queue.size()) {
        return;
    }

    const QVariant currentVariant = m_queue.at(m_index);
    QVariantList remaining;
    remaining.reserve(m_queue.size() - 1);
    for (int i = 0; i < m_queue.size(); ++i) {
        if (i == m_index) {
            continue;
        }
        remaining.append(m_queue.at(i));
    }

    for (int i = remaining.size() - 1; i > 0; --i) {
        const int j = QRandomGenerator::global()->bounded(i + 1);
        if (i != j) {
            remaining.swapItemsAt(i, j);
        }
    }

    QVariantList shuffled;
    shuffled.reserve(m_queue.size());
    shuffled.append(currentVariant);
    for (const QVariant &entry : remaining) {
        shuffled.append(entry);
    }

    applyQueueOrder(shuffled, 0);
}

void PlayerController::applyQueueOrder(const QVariantList &newOrder, int newCurrentIndex) {
    const int newSize = newOrder.size();

    QVector<QString> oldOrderIds;
    oldOrderIds.reserve(m_queue.size());
    for (const QVariant &entry : m_queue) {
        oldOrderIds.append(trackIdFromVariant(entry));
    }

    QVector<QString> newOrderIds;
    newOrderIds.reserve(newSize);
    for (const QVariant &entry : newOrder) {
        newOrderIds.append(trackIdFromVariant(entry));
    }

    if (!newOrderIds.isEmpty() && oldOrderIds.size() == newOrderIds.size()) {
        syncMpvPlaylistOrder(oldOrderIds, newOrderIds);
    }

    m_queue = newOrder;
    emit queueChanged();

    if (newSize == 0) {
        m_index = -1;
        m_current.clear();
        emit currentTrackChanged();
        updateDiscordPresence();
        return;
    }

    m_index = qBound(0, newCurrentIndex, newSize - 1);
    m_current = m_queue[m_index].toMap();
    emit currentTrackChanged();
    if (m_mediaControls) {
        m_mediaControls->updateMetadata(m_current);
    }
    updateDiscordPresence();
}

void PlayerController::syncMpvPlaylistOrder(const QVector<QString> &oldOrderIds, const QVector<QString> &newOrderIds) {
    if (!m_mpv)
        return;
    if (oldOrderIds.size() != newOrderIds.size())
        return;

    QVector<QString> workingOrder = oldOrderIds;

    for (int target = 0; target < newOrderIds.size(); ++target) {
        const QString &desiredId = newOrderIds.at(target);
        if (desiredId.isEmpty())
            continue;

        const int currentIndex = workingOrder.indexOf(desiredId);
        if (currentIndex < 0 || currentIndex == target)
            continue;

        m_mpv->command(QVariantList{
            QStringLiteral("playlist-move"),
            QString::number(currentIndex),
            QString::number(target)
        });

        const QString movedId = workingOrder.takeAt(currentIndex);
        workingOrder.insert(target, movedId);
    }
}

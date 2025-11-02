#include "MediaControls.h"
#include "PlayerController.h"
#include <QDebug>
#if defined(_WIN32) || defined(Q_OS_WIN)
#include "WindowsThumbnailToolbar.h"
#endif

MediaControls::MediaControls(PlayerController *player, QObject *parent)
    : QObject(parent)
    , m_player(player)
#if defined(_WIN32) || defined(Q_OS_WIN)
    , m_thumbnailToolbar(nullptr)
#endif
{
    setupMediaSession();
}

MediaControls::~MediaControls()
{
    qDebug() << "[MediaControls] Finalizando controles de mídia";
}

void MediaControls::setupMediaSession()
{
    qDebug() << "[MediaControls] Controles de mídia inicializados";
    qDebug() << "[MediaControls] Atalhos de teclado habilitados:";
    qDebug() << "  - Space: Play/Pause";
    qDebug() << "  - Shift+N: Próxima faixa";
    qDebug() << "  - Shift+P: Faixa anterior";
    qDebug() << "  - M: Mute/Unmute";
    qDebug() << "  - Up/Down: Ajustar volume";
    
    setupWindowsControls();
}

void MediaControls::setupWindowsControls()
{
#if defined(_WIN32) || defined(Q_OS_WIN)
    if (!m_thumbnailToolbar) {
        m_thumbnailToolbar = new WindowsThumbnailToolbar(m_player, this);
    }
    m_thumbnailToolbar->initialize();
#else
    qDebug() << "[MediaControls] Integrações específicas não disponíveis";
#endif
}

void MediaControls::updateMetadata(const QVariantMap &track)
{
    if (track.isEmpty()) {
        return;
    }
    
    QString title = track.value("title").toString();
    QString artist = track.value("artist").toString();
    QString album = track.value("album").toString();
    
    qDebug() << "[MediaControls] Tocando:" << title << "-" << artist;
}

void MediaControls::updatePlaybackState(bool playing)
{
    qDebug() << "[MediaControls] Estado:" << (playing ? "▶ Reproduzindo" : "⏸ Pausado");
#if defined(_WIN32) || defined(Q_OS_WIN)
    if (m_thumbnailToolbar) {
        m_thumbnailToolbar->setPlaying(playing);
    }
#endif
}

void MediaControls::updatePosition(qint64 position)
{
    Q_UNUSED(position);
    // Position updates can be added later if needed
}

void MediaControls::updateDuration(qint64 duration)
{
    Q_UNUSED(duration);
    // Duration updates can be added later if needed
}

void MediaControls::handlePlayPause()
{
    if (m_player) {
        m_player->toggle();
    }
}

void MediaControls::handleNext()
{
    if (m_player) {
        m_player->next();
    }
}

void MediaControls::handlePrevious()
{
    if (m_player) {
        m_player->previous();
    }
}

void MediaControls::handleSeek(qint64 position)
{
    if (m_player) {
        m_player->seek(position);
    }
}

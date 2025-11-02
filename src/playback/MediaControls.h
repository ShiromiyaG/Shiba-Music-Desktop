#pragma once
#include <QObject>

class PlayerController;
#if defined(_WIN32) || defined(Q_OS_WIN)
class WindowsThumbnailToolbar;
#endif

class MediaControls : public QObject {
    Q_OBJECT
public:
    explicit MediaControls(PlayerController *player, QObject *parent = nullptr);
    ~MediaControls();

    void updateMetadata(const QVariantMap &track);
    void updatePlaybackState(bool playing);
    void updatePosition(qint64 position);
    void updateDuration(qint64 duration);

private slots:
    void handlePlayPause();
    void handleNext();
    void handlePrevious();
    void handleSeek(qint64 position);

private:
    void setupMediaSession();
    void setupWindowsControls();

    PlayerController *m_player;
#if defined(_WIN32) || defined(Q_OS_WIN)
    WindowsThumbnailToolbar *m_thumbnailToolbar;
#endif
};

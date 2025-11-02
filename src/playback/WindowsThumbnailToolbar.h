#pragma once

#include <QObject>

#if defined(_WIN32) || defined(Q_OS_WIN)

#include <QAbstractNativeEventFilter>

#include <windows.h>
#include <shobjidl.h>

class PlayerController;

class WindowsThumbnailToolbar : public QObject, public QAbstractNativeEventFilter
{
    Q_OBJECT
public:
    explicit WindowsThumbnailToolbar(PlayerController *player, QObject *parent = nullptr);
    ~WindowsThumbnailToolbar() override;

    void initialize();
    void setPlaying(bool playing);

    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) override;

private:
    enum ButtonId {
        ButtonPrevious = 1001,
        ButtonPlayPause = 1002,
        ButtonNext = 1003
    };

    void ensureInitialized();
    void updateButtons();
    void releaseResources();
    void scheduleRetry();
    HWND resolveWindowHandle() const;
    HICON createIcon(const QString &iconPath) const;

    PlayerController *m_player;
    ITaskbarList3 *m_taskbar = nullptr;
    HWND m_hwnd = nullptr;
    bool m_buttonsAdded = false;
    bool m_registeredFilter = false;
    bool m_playing = false;
    bool m_comInitialized = false;
    bool m_uninitializeCom = false;
    bool m_retryPending = false;

    THUMBBUTTON m_buttons[3];
    HICON m_iconPrev = nullptr;
    HICON m_iconNext = nullptr;
    HICON m_iconPlay = nullptr;
    HICON m_iconPause = nullptr;
};

#endif // _WIN32 || defined(Q_OS_WIN)


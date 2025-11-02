#include "WindowsThumbnailToolbar.h"

#if defined(_WIN32) || defined(Q_OS_WIN)

#include "PlayerController.h"

#include <QCoreApplication>
#include <QGuiApplication>
#include <QIcon>
#include <QPixmap>
#include <QTimer>
#include <QWindow>

#include <cstring>

#ifndef THBN_CLICKED
#define THBN_CLICKED 0x1800
#endif

namespace {

void copyTooltip(wchar_t *dst, const wchar_t *src)
{
#ifdef _MSC_VER
    wcscpy_s(dst, 260, src);
#else
    wcsncpy(dst, src, 259);
    dst[259] = L'\0';
#endif
}

} // namespace

WindowsThumbnailToolbar::WindowsThumbnailToolbar(PlayerController *player, QObject *parent)
    : QObject(parent)
    , m_player(player)
{
    std::memset(m_buttons, 0, sizeof(m_buttons));
}

WindowsThumbnailToolbar::~WindowsThumbnailToolbar()
{
    if (m_registeredFilter && QCoreApplication::instance()) {
        QCoreApplication::instance()->removeNativeEventFilter(this);
    }
    releaseResources();
}

void WindowsThumbnailToolbar::initialize()
{
    auto *app = QCoreApplication::instance();
    if (!app)
        return;

    if (!m_registeredFilter) {
        app->installNativeEventFilter(this);
        m_registeredFilter = true;
    }

    ensureInitialized();
}

void WindowsThumbnailToolbar::setPlaying(bool playing)
{
    if (m_playing == playing)
        return;
    m_playing = playing;
    ensureInitialized();
    updateButtons();
}

bool WindowsThumbnailToolbar::nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result)
{
    if (eventType != "windows_generic_MSG" || !message)
        return false;

    MSG *msg = static_cast<MSG*>(message);
    if (msg->message == WM_COMMAND && HIWORD(msg->wParam) == THBN_CLICKED) {
        switch (LOWORD(msg->wParam)) {
        case ButtonPlayPause:
            if (m_player) m_player->toggle();
            break;
        case ButtonNext:
            if (m_player) m_player->next();
            break;
        case ButtonPrevious:
            if (m_player) m_player->previous();
            break;
        default:
            return false;
        }
        if (result) *result = 0;
        return true;
    }
    return false;
}

void WindowsThumbnailToolbar::ensureInitialized()
{
    if (!m_hwnd) {
        m_hwnd = resolveWindowHandle();
        if (!m_hwnd) {
            scheduleRetry();
            return;
        }
    }

    if (!m_comInitialized) {
        HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
        if (SUCCEEDED(hr)) {
            m_comInitialized = true;
            m_uninitializeCom = true;
        } else if (hr == RPC_E_CHANGED_MODE) {
            m_comInitialized = true;
            m_uninitializeCom = false;
        } else {
            return;
        }
    }

    if (!m_taskbar) {
        HRESULT hr = CoCreateInstance(CLSID_TaskbarList, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&m_taskbar));
        if (FAILED(hr)) {
            m_taskbar = nullptr;
            return;
        }
        if (FAILED(m_taskbar->HrInit())) {
            m_taskbar->Release();
            m_taskbar = nullptr;
            return;
        }
    }

    if (!m_iconPrev) m_iconPrev = createIcon(QStringLiteral(":/qml/icons/skip_previous.svg"));
    if (!m_iconNext) m_iconNext = createIcon(QStringLiteral(":/qml/icons/skip_next.svg"));
    if (!m_iconPlay) m_iconPlay = createIcon(QStringLiteral(":/qml/icons/play_arrow.svg"));
    if (!m_iconPause) m_iconPause = createIcon(QStringLiteral(":/qml/icons/pause.svg"));

    if (!m_buttonsAdded && m_taskbar && m_iconPrev && m_iconNext && m_iconPlay && m_iconPause) {
        std::memset(m_buttons, 0, sizeof(m_buttons));

        m_buttons[0].iId = ButtonPrevious;
        m_buttons[0].dwMask = THB_FLAGS | THB_ICON | THB_TOOLTIP;
        m_buttons[0].dwFlags = THBF_ENABLED;
        m_buttons[0].hIcon = m_iconPrev;
        copyTooltip(m_buttons[0].szTip, L"Previous");

        m_buttons[1].iId = ButtonPlayPause;
        m_buttons[1].dwMask = THB_FLAGS | THB_ICON | THB_TOOLTIP;
        m_buttons[1].dwFlags = THBF_ENABLED;
        m_buttons[1].hIcon = m_playing ? m_iconPause : m_iconPlay;
        copyTooltip(m_buttons[1].szTip, m_playing ? L"Pause" : L"Play");

        m_buttons[2].iId = ButtonNext;
        m_buttons[2].dwMask = THB_FLAGS | THB_ICON | THB_TOOLTIP;
        m_buttons[2].dwFlags = THBF_ENABLED;
        m_buttons[2].hIcon = m_iconNext;
        copyTooltip(m_buttons[2].szTip, L"Next");

        if (SUCCEEDED(m_taskbar->ThumbBarAddButtons(m_hwnd, 3, m_buttons))) {
            m_buttonsAdded = true;
        }
    }
}

void WindowsThumbnailToolbar::updateButtons()
{
    if (!m_taskbar || !m_buttonsAdded)
        return;

    m_buttons[1].hIcon = m_playing ? m_iconPause : m_iconPlay;
    copyTooltip(m_buttons[1].szTip, m_playing ? L"Pause" : L"Play");
    m_taskbar->ThumbBarUpdateButtons(m_hwnd, 3, m_buttons);
}

void WindowsThumbnailToolbar::releaseResources()
{
    if (m_taskbar) {
        m_taskbar->Release();
        m_taskbar = nullptr;
    }

    if (m_uninitializeCom) {
        CoUninitialize();
    }
    m_comInitialized = false;
    m_uninitializeCom = false;

    if (m_iconPrev) { DestroyIcon(m_iconPrev); m_iconPrev = nullptr; }
    if (m_iconNext) { DestroyIcon(m_iconNext); m_iconNext = nullptr; }
    if (m_iconPlay) { DestroyIcon(m_iconPlay); m_iconPlay = nullptr; }
    if (m_iconPause) { DestroyIcon(m_iconPause); m_iconPause = nullptr; }
}

void WindowsThumbnailToolbar::scheduleRetry()
{
    if (m_retryPending)
        return;
    m_retryPending = true;
    QTimer::singleShot(1000, this, [this]() {
        m_retryPending = false;
        ensureInitialized();
    });
}

HWND WindowsThumbnailToolbar::resolveWindowHandle() const
{
    const auto windows = QGuiApplication::topLevelWindows();
    for (QWindow *window : windows) {
        if (window && window->isVisible()) {
            return reinterpret_cast<HWND>(window->winId());
        }
    }
    return nullptr;
}

HICON WindowsThumbnailToolbar::createIcon(const QString &iconPath) const
{
    QIcon icon(iconPath);
    if (icon.isNull())
        return nullptr;

    QPixmap pixmap = icon.pixmap(32, 32);
    QImage image = pixmap.toImage().convertToFormat(QImage::Format_ARGB32);

    BITMAPV5HEADER header = {};
    header.bV5Size = sizeof(BITMAPV5HEADER);
    header.bV5Width = image.width();
    header.bV5Height = -image.height();
    header.bV5Planes = 1;
    header.bV5BitCount = 32;
    header.bV5Compression = BI_BITFIELDS;
    header.bV5RedMask   = 0x00FF0000;
    header.bV5GreenMask = 0x0000FF00;
    header.bV5BlueMask  = 0x000000FF;
    header.bV5AlphaMask = 0xFF000000;

    void *bits = nullptr;
    HDC hdc = GetDC(nullptr);
    HBITMAP color = CreateDIBSection(hdc, reinterpret_cast<BITMAPINFO*>(&header), DIB_RGB_COLORS, &bits, nullptr, 0);
    ReleaseDC(nullptr, hdc);

    if (!color || !bits) {
        if (color) DeleteObject(color);
        return nullptr;
    }

    std::memcpy(bits, image.bits(), image.sizeInBytes());

    HBITMAP mask = CreateBitmap(image.width(), image.height(), 1, 1, nullptr);

    ICONINFO info = {};
    info.fIcon = TRUE;
    info.hbmColor = color;
    info.hbmMask = mask;
    HICON hIcon = CreateIconIndirect(&info);

    DeleteObject(mask);
    DeleteObject(color);

    return hIcon;
}

#endif // _WIN32 || defined(Q_OS_WIN)

#include "WindowStateManager.h"

#include <QCoreApplication>
#include <QGuiApplication>
#include <QRect>
#include <QScreen>
#include <algorithm>

namespace
{
    QString resolveOrganizationName()
    {
        const QString org = QCoreApplication::organizationName();
        return org.isEmpty() ? QStringLiteral("ShibaMusic") : org;
    }

    QString resolveApplicationName()
    {
        const QString app = QCoreApplication::applicationName();
        return app.isEmpty() ? QStringLiteral("Shiba Music") : app;
    }

    QSize ensureMinimumSize(const QSize &size, const QSize &minimum)
    {
        const int width = std::max(size.width(), minimum.width());
        const int height = std::max(size.height(), minimum.height());
        return QSize(width, height);
    }

    QRect fallbackRect(int x, int y, int width, int height)
    {
        const int safeWidth = std::max(width, 1);
        const int safeHeight = std::max(height, 1);
        return QRect(QPoint(x, y), QSize(safeWidth, safeHeight));
    }

    // Clamp stored geometry to the available screen real estate while respecting minimum dimensions.
    QRect sanitizeGeometry(const QRect &storedRect, const QRect &defaultRect, const QSize &minimumSize)
    {
        const QSize effectiveMinimum(std::max(minimumSize.width(), 1), std::max(minimumSize.height(), 1));

        QRect normalized = storedRect;
        if (!normalized.isValid())
            normalized = QRect(storedRect.topLeft(), defaultRect.size());
        if (!normalized.isValid())
            normalized = defaultRect;
        if (!normalized.isValid())
            normalized = QRect(defaultRect.topLeft(), effectiveMinimum);

        normalized.setSize(ensureMinimumSize(normalized.size(), effectiveMinimum));

        const auto screens = QGuiApplication::screens();
        if (screens.isEmpty())
            return normalized;

        auto pickPrimary = [&]() -> QScreen *
        {
            if (auto *primary = QGuiApplication::primaryScreen(); primary && primary->availableGeometry().isValid())
                return primary;
            for (QScreen *screen : screens)
            {
                if (!screen)
                    continue;
                if (screen->availableGeometry().isValid())
                    return screen;
            }
            return nullptr;
        };

        auto *primaryScreen = pickPrimary();
        if (!primaryScreen)
            return normalized;

        auto resolveArea = [](QScreen *screen) -> QRect
        {
            return screen ? screen->availableGeometry() : QRect();
        };

        QRect targetArea;
        for (QScreen *screen : screens)
        {
            if (!screen)
                continue;
            const QRect area = resolveArea(screen);
            if (area.contains(normalized.topLeft()))
            {
                targetArea = area;
                break;
            }
        }
        if (!targetArea.isValid())
            targetArea = resolveArea(primaryScreen);

        if (!targetArea.isValid())
            return normalized;

        const int widthWithMinimum = std::max(normalized.width(), effectiveMinimum.width());
        const int heightWithMinimum = std::max(normalized.height(), effectiveMinimum.height());
        const int finalWidth = std::min(widthWithMinimum, targetArea.width());
        const int finalHeight = std::min(heightWithMinimum, targetArea.height());
        normalized.setSize(QSize(std::max(finalWidth, 1), std::max(finalHeight, 1)));

        const bool topLeftInside = targetArea.contains(normalized.topLeft());
        if (!topLeftInside)
        {
            const int centeredX = targetArea.x() + std::max(0, (targetArea.width() - normalized.width()) / 2);
            const int centeredY = targetArea.y() + std::max(0, (targetArea.height() - normalized.height()) / 2);
            normalized.moveTo(centeredX, centeredY);
            return normalized;
        }

        const int minX = targetArea.x();
        const int minY = targetArea.y();
        const int maxX = targetArea.x() + std::max(0, targetArea.width() - normalized.width());
        const int maxY = targetArea.y() + std::max(0, targetArea.height() - normalized.height());

        const int clampedX = std::min(std::max(normalized.x(), minX), maxX);
        const int clampedY = std::min(std::max(normalized.y(), minY), maxY);
        normalized.moveTo(clampedX, clampedY);

        return normalized;
    }
} // namespace

WindowStateManager::WindowStateManager(QObject *parent)
    : QObject(parent),
      m_settings(resolveOrganizationName(), resolveApplicationName())
{
}

void WindowStateManager::save(const QPoint &position, const QSize &size, bool maximized)
{
    m_settings.beginGroup("window");
    m_settings.setValue("position", position);
    m_settings.setValue("size", size);
    m_settings.setValue("maximized", maximized);
    m_settings.endGroup();
    m_settings.sync();
}

QPoint WindowStateManager::loadPosition(const QPoint &defaultPos) const
{
    m_settings.beginGroup("window");
    const QPoint pos = m_settings.value("position", defaultPos).toPoint();
    m_settings.endGroup();
    return pos;
}

QSize WindowStateManager::loadSize(const QSize &defaultSize) const
{
    m_settings.beginGroup("window");
    const QSize size = m_settings.value("size", defaultSize).toSize();
    m_settings.endGroup();
    return size;
}

bool WindowStateManager::loadMaximized() const
{
    m_settings.beginGroup("window");
    const bool maximized = m_settings.value("maximized", false).toBool();
    m_settings.endGroup();
    return maximized;
}

QVariantMap WindowStateManager::loadState(int defaultX, int defaultY, int defaultWidth, int defaultHeight,
                                          bool defaultMaximized, int minimumWidth, int minimumHeight) const
{
    const bool hasState = m_settings.contains("window/position") && m_settings.contains("window/size");

    const QSize fallbackSize(std::max(defaultWidth, 1), std::max(defaultHeight, 1));
    const int effectiveMinWidth = minimumWidth > 0 ? minimumWidth : fallbackSize.width();
    const int effectiveMinHeight = minimumHeight > 0 ? minimumHeight : fallbackSize.height();
    const QSize minimumSize(std::max(effectiveMinWidth, 1), std::max(effectiveMinHeight, 1));

    QPoint pos(defaultX, defaultY);
    QSize size(defaultWidth, defaultHeight);
    bool maximized = defaultMaximized;

    if (hasState)
    {
        pos = loadPosition(pos);
        size = loadSize(size);
        maximized = loadMaximized();
    }

    const QRect defaultRect = fallbackRect(defaultX, defaultY, defaultWidth, defaultHeight);
    const QRect desiredRect(pos, size);
    const QRect sanitized = sanitizeGeometry(desiredRect, defaultRect, minimumSize);

    QVariantMap state;
    state.insert(QStringLiteral("x"), sanitized.x());
    state.insert(QStringLiteral("y"), sanitized.y());
    state.insert(QStringLiteral("width"), sanitized.width());
    state.insert(QStringLiteral("height"), sanitized.height());
    state.insert(QStringLiteral("maximized"), maximized);
    state.insert(QStringLiteral("stored"), hasState);
    return state;
}

void WindowStateManager::saveState(int x, int y, int width, int height, bool maximized)
{
    const QSize safeSize(std::max(width, 1), std::max(height, 1));
    save(QPoint(x, y), safeSize, maximized);
}

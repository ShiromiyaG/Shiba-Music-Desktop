#include "WindowStateManager.h"

#include <QCoreApplication>

namespace {
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

QVariantMap WindowStateManager::loadState(int defaultX, int defaultY, int defaultWidth, int defaultHeight, bool defaultMaximized) const
{
    const bool hasState = m_settings.contains("window/position") && m_settings.contains("window/size");

    QPoint pos(defaultX, defaultY);
    QSize size(defaultWidth, defaultHeight);
    bool maximized = defaultMaximized;

    if (hasState) {
        pos = loadPosition(pos);
        size = loadSize(size);
        maximized = loadMaximized();
    }

    QVariantMap state;
    state.insert(QStringLiteral("x"), pos.x());
    state.insert(QStringLiteral("y"), pos.y());
    state.insert(QStringLiteral("width"), size.width());
    state.insert(QStringLiteral("height"), size.height());
    state.insert(QStringLiteral("maximized"), maximized);
    state.insert(QStringLiteral("stored"), hasState);
    return state;
}

void WindowStateManager::saveState(int x, int y, int width, int height, bool maximized)
{
    save(QPoint(x, y), QSize(width, height), maximized);
}

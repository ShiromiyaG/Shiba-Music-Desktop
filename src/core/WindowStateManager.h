#pragma once

#include <QObject>
#include <QPoint>
#include <QSize>
#include <QSettings>
#include <QVariantMap>
#include <QCoreApplication>

class WindowStateManager : public QObject
{
    Q_OBJECT

public:
    explicit WindowStateManager(QObject *parent = nullptr);

    void save(const QPoint &position, const QSize &size, bool maximized);
    QPoint loadPosition(const QPoint &defaultPos) const;
    QSize loadSize(const QSize &defaultSize) const;
    bool loadMaximized() const;

    Q_INVOKABLE QVariantMap loadState(int defaultX, int defaultY, int defaultWidth, int defaultHeight, bool defaultMaximized = false) const;
    Q_INVOKABLE void saveState(int x, int y, int width, int height, bool maximized);

private:
    mutable QSettings m_settings;
};

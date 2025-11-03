#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QString>

class ThemeManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList availableThemes READ availableThemes NOTIFY availableThemesChanged)
    Q_PROPERTY(QString selectedThemeId READ selectedThemeId NOTIFY selectedThemeIdChanged)
    Q_PROPERTY(QString appliedThemeId READ appliedThemeId NOTIFY appliedThemeIdChanged)
    Q_PROPERTY(bool restartRequired READ restartRequired NOTIFY restartRequiredChanged)
    Q_PROPERTY(QVariantMap palette READ palette NOTIFY paletteChanged)

public:
    explicit ThemeManager(const QString &appliedThemeId, QObject *parent = nullptr);

    QVariantList availableThemes() const;
    QString selectedThemeId() const;
    QString appliedThemeId() const;
    bool restartRequired() const;
    QVariantMap palette() const;

    Q_INVOKABLE void setSelectedThemeId(const QString &themeId);

    static QString startupThemeId();
    static QString styleKeyForThemeId(const QString &themeId);
    static QString defaultThemeId();

signals:
    void availableThemesChanged();
    void selectedThemeIdChanged();
    void appliedThemeIdChanged();
    void restartRequiredChanged();
    void paletteChanged();

private:
    void reloadAvailableThemes();
    void loadSelectedThemeFromSettings();
    void persistSelectedTheme() const;
    bool isThemeAvailable(const QString &themeId) const;
    QString resolveThemeId(const QString &candidateId) const;
    QString labelForTheme(const QString &themeId) const;
    void updatePalette();
    static QVariantMap paletteForThemeId(const QString &themeId);

    QVariantList m_availableThemes;
    QString m_selectedThemeId;
    QString m_appliedThemeId;
    bool m_restartRequired = false;
    QVariantMap m_palette;
};

#include "ThemeManager.h"

#include <QtQuickControls2/QQuickStyle>
#include <QFile>
#include <QRegularExpression>
#include <QSettings>
#include <QVariantMap>
#include <QDebug>

namespace {

enum class PlatformRequirement {
    Any,
    WindowsOnly,
    LinuxOnly
};

struct ThemeOption {
    QString id;
    QString styleKey;
    PlatformRequirement requirement;
    QString qssResource;
};

const QList<ThemeOption> &themeOptions() {
    static const QList<ThemeOption> options = {
        { QStringLiteral("material"), QStringLiteral("Material"), PlatformRequirement::Any, QStringLiteral(":/themes/material.qss") }
    };
    return options;
}

const ThemeOption *findOption(const QString &id) {
    const auto &options = themeOptions();
    for (const ThemeOption &option : options) {
        if (option.id.compare(id, Qt::CaseInsensitive) == 0)
            return &option;
    }
    return nullptr;
}

bool platformMatches(PlatformRequirement requirement) {
    switch (requirement) {
    case PlatformRequirement::Any:
        return true;
    case PlatformRequirement::WindowsOnly:
#ifdef Q_OS_WINDOWS
        return true;
#else
        return false;
#endif
    case PlatformRequirement::LinuxOnly:
#ifdef Q_OS_LINUX
        return true;
#else
        return false;
#endif
    }
    return true;
}

bool themeAvailable(const QString &id) {
    const ThemeOption *option = findOption(id);
    if (!option)
        return false;
    if (!platformMatches(option->requirement))
        return false;
    return true;
}

QString readStoredThemeId() {
    QSettings settings;
    settings.beginGroup(QStringLiteral("Appearance"));
    const QString stored = settings.value(QStringLiteral("ThemeId")).toString();
    settings.endGroup();
    return stored;
}

QVariantMap parsePaletteFromQss(const QString &content) {
    QVariantMap result;
    static const QRegularExpression propertyRegex(QStringLiteral("qproperty-([A-Za-z0-9_]+)\\s*:\\s*([^;]+);"));
    static const QRegularExpression numberRegex(QStringLiteral("^-?\\d+(?:\\.\\d+)?$"));
    auto matchIterator = propertyRegex.globalMatch(content);
    while (matchIterator.hasNext()) {
        const QRegularExpressionMatch match = matchIterator.next();
        const QString key = match.captured(1);
        if (key.isEmpty())
            continue;
        QString rawValue = match.captured(2).trimmed();
        if (rawValue.isEmpty())
            continue;

        if (rawValue.startsWith(QLatin1Char('"')) && rawValue.endsWith(QLatin1Char('"')) && rawValue.size() >= 2) {
            rawValue = rawValue.mid(1, rawValue.size() - 2);
            result.insert(key, rawValue);
            continue;
        }
        if (rawValue.startsWith(QLatin1Char('\'')) && rawValue.endsWith(QLatin1Char('\'')) && rawValue.size() >= 2) {
            rawValue = rawValue.mid(1, rawValue.size() - 2);
            result.insert(key, rawValue);
            continue;
        }
        if (rawValue.compare(QStringLiteral("true"), Qt::CaseInsensitive) == 0) {
            result.insert(key, true);
            continue;
        }
        if (rawValue.compare(QStringLiteral("false"), Qt::CaseInsensitive) == 0) {
            result.insert(key, false);
            continue;
        }
        if (numberRegex.match(rawValue).hasMatch()) {
            bool ok = false;
            const double numeric = rawValue.toDouble(&ok);
            if (ok) {
                result.insert(key, numeric);
                continue;
            }
        }
        result.insert(key, rawValue);
    }
    return result;
}

QVariantMap loadPaletteFromResource(const QString &resourcePath) {
    if (resourcePath.isEmpty())
        return {};
    QFile file(resourcePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning().noquote() << "ThemeManager: Unable to open theme palette" << resourcePath << "-" << file.errorString();
        return {};
    }
    const QString content = QString::fromUtf8(file.readAll());
    return parsePaletteFromQss(content);
}

} // namespace

ThemeManager::ThemeManager(const QString &appliedThemeId, QObject *parent)
    : QObject(parent),
      m_selectedThemeId(appliedThemeId),
      m_appliedThemeId(appliedThemeId) {
    reloadAvailableThemes();
    loadSelectedThemeFromSettings();
    m_restartRequired = (m_selectedThemeId.compare(m_appliedThemeId, Qt::CaseInsensitive) != 0);
    updatePalette();
}

QVariantList ThemeManager::availableThemes() const {
    return m_availableThemes;
}

QString ThemeManager::selectedThemeId() const {
    return m_selectedThemeId;
}

QString ThemeManager::appliedThemeId() const {
    return m_appliedThemeId;
}

bool ThemeManager::restartRequired() const {
    return m_restartRequired;
}

QVariantMap ThemeManager::palette() const {
    return m_palette;
}

void ThemeManager::setSelectedThemeId(const QString &themeId) {
    const QString resolved = resolveThemeId(themeId);
    if (resolved.compare(m_selectedThemeId, Qt::CaseInsensitive) == 0)
        return;

    m_selectedThemeId = resolved;
    persistSelectedTheme();
    emit selectedThemeIdChanged();
    updatePalette();

    const bool needsRestart = (m_selectedThemeId.compare(m_appliedThemeId, Qt::CaseInsensitive) != 0);
    if (needsRestart != m_restartRequired) {
        m_restartRequired = needsRestart;
        emit restartRequiredChanged();
    }
}

QString ThemeManager::startupThemeId() {
    const QString stored = readStoredThemeId();
    if (!stored.isEmpty() && themeAvailable(stored))
        return stored;
    return defaultThemeId();
}

QString ThemeManager::styleKeyForThemeId(const QString &themeId) {
    if (const ThemeOption *option = findOption(themeId)) {
        return option->styleKey;
    }
    const QString fallbackId = defaultThemeId();
    if (const ThemeOption *fallback = findOption(fallbackId))
        return fallback->styleKey;
    return QStringLiteral("Material");
}

QString ThemeManager::defaultThemeId() {
    if (themeAvailable(QStringLiteral("material")))
        return QStringLiteral("material");
    const auto &options = themeOptions();
    for (const ThemeOption &option : options) {
        if (themeAvailable(option.id))
            return option.id;
    }
    return QStringLiteral("material");
}

void ThemeManager::reloadAvailableThemes() {
    QVariantList result;
    const auto &options = themeOptions();
    for (const ThemeOption &option : options) {
        if (!themeAvailable(option.id))
            continue;
        QVariantMap entry;
        entry.insert(QStringLiteral("id"), option.id);
        entry.insert(QStringLiteral("title"), labelForTheme(option.id));
        entry.insert(QStringLiteral("styleKey"), option.styleKey);
        result.append(entry);
    }
    if (result != m_availableThemes) {
        m_availableThemes = result;
        emit availableThemesChanged();
    } else {
        m_availableThemes = result;
    }
}

void ThemeManager::loadSelectedThemeFromSettings() {
    const QString stored = readStoredThemeId();
    const QString resolved = resolveThemeId(stored);
    m_selectedThemeId = resolved;
}

void ThemeManager::persistSelectedTheme() const {
    QSettings settings;
    settings.beginGroup(QStringLiteral("Appearance"));
    settings.setValue(QStringLiteral("ThemeId"), m_selectedThemeId);
    settings.endGroup();
}

bool ThemeManager::isThemeAvailable(const QString &themeId) const {
    return themeAvailable(themeId);
}

QString ThemeManager::resolveThemeId(const QString &candidateId) const {
    if (!candidateId.isEmpty() && isThemeAvailable(candidateId))
        return candidateId;
    if (isThemeAvailable(m_appliedThemeId))
        return m_appliedThemeId;
    return defaultThemeId();
}

QString ThemeManager::labelForTheme(const QString &themeId) const {
    if (themeId.compare(QStringLiteral("material"), Qt::CaseInsensitive) == 0)
        return tr("Material");
    return themeId;
}

void ThemeManager::updatePalette() {
    QVariantMap newPalette = paletteForThemeId(m_selectedThemeId);
    if (newPalette == m_palette)
        return;
    m_palette = newPalette;
    emit paletteChanged();
}

QVariantMap ThemeManager::paletteForThemeId(const QString &themeId) {
    const QString normalized = themeId.trimmed().toLower();
    const QString chosen = themeAvailable(normalized) ? normalized : defaultThemeId();

    QString resolvedId = chosen;
    QVariantMap palette;
    if (const ThemeOption *option = findOption(chosen)) {
        palette = loadPaletteFromResource(option->qssResource);
    }

    if (palette.isEmpty()) {
        const QString fallbackId = QStringLiteral("material");
        if (const ThemeOption *fallback = findOption(fallbackId)) {
            palette = loadPaletteFromResource(fallback->qssResource);
            if (!palette.isEmpty())
                resolvedId = fallback->id;
        }
    }

    if (!palette.contains(QStringLiteral("themeId"))) {
        palette.insert(QStringLiteral("themeId"), resolvedId);
    }

    return palette;
}

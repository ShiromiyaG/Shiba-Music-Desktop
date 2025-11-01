#include "TranslationManager.h"
#include <QSettings>
#include <QLocale>
#include <QDebug>
#include <QQmlContext>

TranslationManager* TranslationManager::s_instance = nullptr;

TranslationManager::TranslationManager(QObject *parent)
    : QObject(parent)
{
    s_instance = this;
    
    // Load saved language or use system language
    QString savedLang = loadLanguagePreference();
    if (savedLang.isEmpty()) {
        QString systemLang = QLocale::system().name().left(2);
        if (availableLanguages().contains(systemLang)) {
            savedLang = systemLang;
        } else {
            savedLang = "en"; // Default to English
        }
    }
    
    setLanguage(savedLang);
}

TranslationManager* TranslationManager::instance() {
    return s_instance;
}

void TranslationManager::setLanguage(const QString &language) {
    if (m_currentLanguage == language) {
        return;
    }
    
    qDebug() << "TranslationManager: Changing language to" << language;
    
    QString oldLanguage = m_currentLanguage;
    
    // Remove old translator
    if (!oldLanguage.isEmpty()) {
        QGuiApplication::removeTranslator(&m_translator);
    }
    
    // Load new translation
    loadTranslation(language);
    
    m_currentLanguage = language;
    saveLanguagePreference(language);
    
    // Emit signals BEFORE retranslate
    emit languageChanged();
    
    // Force QML to retranslate
    if (m_engine) {
        qDebug() << "TranslationManager: Calling engine->retranslate()";
        m_engine->retranslate();
    } else {
        qWarning() << "TranslationManager: QML engine not set";
    }
    
    // Emit after to trigger any UI updates
    emit translationReloaded();
    
    qDebug() << "TranslationManager: Language changed from" << oldLanguage << "to" << language;
}

void TranslationManager::loadTranslation(const QString &language) {
    QString translationFile = QString(":/i18n/shibamusic_%1.qm").arg(language);
    
    if (m_translator.load(translationFile)) {
        QGuiApplication::installTranslator(&m_translator);
        qDebug() << "TranslationManager: Loaded translation:" << translationFile;
    } else {
        qWarning() << "TranslationManager: Failed to load translation:" << translationFile;
    }
}

QStringList TranslationManager::availableLanguages() const {
    return {"en", "pt", "es", "fr", "de", "ja", "zh"};
}

QString TranslationManager::languageName(const QString &code) const {
    static QMap<QString, QString> names = {
        {"en", "English"},
        {"pt", "Português"},
        {"es", "Español"},
        {"fr", "Français"},
        {"de", "Deutsch"},
        {"ja", "日本語"},
        {"zh", "中文"}
    };
    return names.value(code, code);
}

void TranslationManager::saveLanguagePreference(const QString &language) {
    QSettings settings("ShibaMusic", "ShibaMusic");
    settings.setValue("language", language);
}

QString TranslationManager::loadLanguagePreference() {
    QSettings settings("ShibaMusic", "ShibaMusic");
    return settings.value("language").toString();
}

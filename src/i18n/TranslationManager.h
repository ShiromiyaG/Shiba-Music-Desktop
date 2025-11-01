#pragma once
#include <QObject>
#include <QTranslator>
#include <QQmlEngine>
#include <QGuiApplication>

class TranslationManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentLanguage READ currentLanguage NOTIFY languageChanged)
    
public:
    explicit TranslationManager(QObject *parent = nullptr);
    
    Q_INVOKABLE void setLanguage(const QString &language);
    Q_INVOKABLE QStringList availableLanguages() const;
    Q_INVOKABLE QString languageName(const QString &code) const;
    
    QString currentLanguage() const { return m_currentLanguage; }
    
    void setEngine(QQmlEngine *engine) { m_engine = engine; }
    
    static TranslationManager* instance();
    
signals:
    void languageChanged();
    void translationReloaded();
    
private:
    void loadTranslation(const QString &language);
    void saveLanguagePreference(const QString &language);
    QString loadLanguagePreference();
    
    QTranslator m_translator;
    QString m_currentLanguage;
    QQmlEngine *m_engine = nullptr;
    static TranslationManager* s_instance;
};

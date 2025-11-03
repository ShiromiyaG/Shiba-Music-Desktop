#ifndef UPDATECHECKER_H
#define UPDATECHECKER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QString>

class UpdateChecker : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isChecking READ isChecking NOTIFY isCheckingChanged)
    Q_PROPERTY(bool updateAvailable READ updateAvailable NOTIFY updateAvailableChanged)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY latestVersionChanged)
    Q_PROPERTY(QString downloadUrl READ downloadUrl NOTIFY downloadUrlChanged)
    Q_PROPERTY(QString releaseNotes READ releaseNotes NOTIFY releaseNotesChanged)
    Q_PROPERTY(bool isDownloading READ isDownloading NOTIFY isDownloadingChanged)
    Q_PROPERTY(int downloadProgress READ downloadProgress NOTIFY downloadProgressChanged)

public:
    explicit UpdateChecker(QObject *parent = nullptr);

    bool isChecking() const { return m_isChecking; }
    bool updateAvailable() const { return m_updateAvailable; }
    QString latestVersion() const { return m_latestVersion; }
    QString downloadUrl() const { return m_downloadUrl; }
    QString releaseNotes() const { return m_releaseNotes; }
    bool isDownloading() const { return m_isDownloading; }
    int downloadProgress() const { return m_downloadProgress; }

    Q_INVOKABLE void checkForUpdates();
    Q_INVOKABLE void downloadAndInstall();
    Q_INVOKABLE void ignoreUpdate();

signals:
    void isCheckingChanged();
    void updateAvailableChanged();
    void latestVersionChanged();
    void downloadUrlChanged();
    void releaseNotesChanged();
    void isDownloadingChanged();
    void downloadProgressChanged();
    void updateCheckFailed(const QString &error);
    void downloadFailed(const QString &error);
    void aboutToQuit();

private slots:
    void onUpdateCheckFinished();
    void onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal);
    void onDownloadFinished();

private:
    bool compareVersions(const QString &currentVersion, const QString &latestVersion);
    void installUpdate(const QString &installerPath);

    QNetworkAccessManager *m_networkManager;
    QNetworkReply *m_currentReply;
    
    bool m_isChecking;
    bool m_updateAvailable;
    QString m_latestVersion;
    QString m_downloadUrl;
    QString m_releaseNotes;
    bool m_isDownloading;
    int m_downloadProgress;
    QString m_downloadPath;
};

#endif // UPDATECHECKER_H

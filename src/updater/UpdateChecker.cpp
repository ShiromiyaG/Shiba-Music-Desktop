#include "UpdateChecker.h"
#include "../core/AppInfo.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFile>
#include <QStandardPaths>
#include <QProcess>
#include <QDebug>
#include <QDir>
#include <QCoreApplication>
#include <QGuiApplication>
#include <QTimer>
#include <QTextStream>

UpdateChecker::UpdateChecker(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_currentReply(nullptr)
    , m_isChecking(false)
    , m_updateAvailable(false)
    , m_isDownloading(false)
    , m_downloadProgress(0)
{
}

void UpdateChecker::checkForUpdates()
{
    if (m_isChecking) {
        qDebug() << "UpdateChecker: Already checking for updates";
        return;
    }

    qDebug() << "UpdateChecker: Starting update check...";
    qDebug() << "UpdateChecker: Current version:" << APP_VERSION;
    
    m_isChecking = true;
    emit isCheckingChanged();

    QUrl url("https://api.github.com/repos/ShiromiyaG/Shiba-Music-Desktop/releases/latest");
    qDebug() << "UpdateChecker: Requesting" << url;
    
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::UserAgentHeader, "ShibaMusic-Updater");
    request.setRawHeader("Accept", "application/vnd.github.v3+json");
    
    m_currentReply = m_networkManager->get(request);
    connect(m_currentReply, &QNetworkReply::finished, this, &UpdateChecker::onUpdateCheckFinished);
}

void UpdateChecker::onUpdateCheckFinished()
{
    m_isChecking = false;
    emit isCheckingChanged();

    if (!m_currentReply) {
        qDebug() << "UpdateChecker: No reply object";
        return;
    }

    qDebug() << "UpdateChecker: Response status:" << m_currentReply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    
    if (m_currentReply->error() != QNetworkReply::NoError) {
        qWarning() << "UpdateChecker: Network error:" << m_currentReply->errorString();
        qWarning() << "UpdateChecker: Error code:" << m_currentReply->error();
        emit updateCheckFailed(m_currentReply->errorString());
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
        return;
    }

    QByteArray data = m_currentReply->readAll();
    qDebug() << "UpdateChecker: Received" << data.size() << "bytes";
    m_currentReply->deleteLater();
    m_currentReply = nullptr;

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) {
        qWarning() << "UpdateChecker: Invalid JSON response";
        qDebug() << "UpdateChecker: Response data:" << QString::fromUtf8(data.left(500));
        emit updateCheckFailed("Invalid JSON response");
        return;
    }

    QJsonObject release = doc.object();
    QString tagName = release["tag_name"].toString();
    qDebug() << "UpdateChecker: Latest release tag:" << tagName;
    
    // Remove 'v' prefix if exists
    if (tagName.startsWith('v')) {
        tagName = tagName.mid(1);
    }

    m_latestVersion = tagName;
    emit latestVersionChanged();

    m_releaseNotes = release["body"].toString();
    emit releaseNotesChanged();

    // Find Windows x64 asset
    QJsonArray assets = release["assets"].toArray();
    for (const QJsonValue &assetVal : assets) {
        QJsonObject asset = assetVal.toObject();
        QString name = asset["name"].toString();
        
        if (name.contains("Windows") && name.contains("x64") && name.endsWith(".zip")) {
            m_downloadUrl = asset["browser_download_url"].toString();
            emit downloadUrlChanged();
            break;
        }
    }

    QString currentVersion = APP_VERSION;
    qDebug() << "UpdateChecker: Comparing versions - Current:" << currentVersion << "Latest:" << m_latestVersion;
    qDebug() << "UpdateChecker: Download URL:" << m_downloadUrl;
    
    if (compareVersions(currentVersion, m_latestVersion)) {
        m_updateAvailable = true;
        emit updateAvailableChanged();
        qDebug() << "UpdateChecker: ✓ Update available:" << currentVersion << "->" << m_latestVersion;
    } else {
        qDebug() << "UpdateChecker: ✗ No update available. Current:" << currentVersion << "Latest:" << m_latestVersion;
    }
}

bool UpdateChecker::compareVersions(const QString &currentVersion, const QString &latestVersion)
{
    QStringList currentParts = currentVersion.split('.');
    QStringList latestParts = latestVersion.split('.');

    int maxLen = qMax(currentParts.length(), latestParts.length());
    
    for (int i = 0; i < maxLen; i++) {
        int current = (i < currentParts.length()) ? currentParts[i].toInt() : 0;
        int latest = (i < latestParts.length()) ? latestParts[i].toInt() : 0;
        
        if (latest > current) {
            return true;
        } else if (latest < current) {
            return false;
        }
    }
    
    return false;
}

void UpdateChecker::downloadAndInstall()
{
    if (m_downloadUrl.isEmpty()) {
        qWarning() << "UpdateChecker: Download URL is empty";
        emit downloadFailed("No download URL available");
        return;
    }
    
    if (m_isDownloading) {
        qWarning() << "UpdateChecker: Already downloading";
        return;
    }

    qDebug() << "UpdateChecker: Starting download from" << m_downloadUrl;
    m_isDownloading = true;
    m_downloadProgress = 0;
    emit isDownloadingChanged();
    emit downloadProgressChanged();

    QString tempPath = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    m_downloadPath = tempPath + "/ShibaMusic-Update.zip";

    QNetworkRequest request(m_downloadUrl);
    request.setHeader(QNetworkRequest::UserAgentHeader, "ShibaMusic-Updater");
    
    m_currentReply = m_networkManager->get(request);
    connect(m_currentReply, &QNetworkReply::downloadProgress, this, &UpdateChecker::onDownloadProgress);
    connect(m_currentReply, &QNetworkReply::finished, this, &UpdateChecker::onDownloadFinished);
}

void UpdateChecker::onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal)
{
    if (bytesTotal > 0) {
        m_downloadProgress = static_cast<int>((bytesReceived * 100) / bytesTotal);
        emit downloadProgressChanged();
    }
}

void UpdateChecker::onDownloadFinished()
{
    qDebug() << "UpdateChecker: Download finished";
    
    if (!m_currentReply) {
        qWarning() << "UpdateChecker: No reply object";
        m_isDownloading = false;
        emit isDownloadingChanged();
        emit downloadFailed("Internal error: no reply object");
        return;
    }

    if (m_currentReply->error() != QNetworkReply::NoError) {
        qWarning() << "UpdateChecker: Download failed:" << m_currentReply->errorString();
        m_isDownloading = false;
        emit isDownloadingChanged();
        emit downloadFailed(m_currentReply->errorString());
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
        return;
    }

    QByteArray data = m_currentReply->readAll();
    qDebug() << "UpdateChecker: Downloaded" << data.size() << "bytes";
    m_currentReply->deleteLater();
    m_currentReply = nullptr;

    QFile file(m_downloadPath);
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning() << "UpdateChecker: Failed to open file for writing:" << m_downloadPath;
        m_isDownloading = false;
        emit isDownloadingChanged();
        emit downloadFailed("Failed to save update file");
        return;
    }

    file.write(data);
    file.close();

    qDebug() << "UpdateChecker: Update downloaded to:" << m_downloadPath;
    installUpdate(m_downloadPath);
}

void UpdateChecker::installUpdate(const QString &zipPath)
{
#ifdef Q_OS_WIN
    // Get application directory
    QString appDir = QCoreApplication::applicationDirPath();
    QString updaterPath = appDir + "/updater.exe";
    
    // Check if updater exists
    if (!QFile::exists(updaterPath)) {
        qWarning() << "UpdateChecker: updater.exe not found at" << updaterPath;
        m_isDownloading = false;
        emit isDownloadingChanged();
        emit downloadFailed("Updater executable not found");
        return;
    }
    
    // Start updater process with arguments: updater.exe <zipPath> <appDir> <exeName>
    QStringList args;
    args << zipPath << appDir << "shibamusic.exe";
    
    qDebug() << "UpdateChecker: Starting updater:" << updaterPath << args;
    qDebug() << "UpdateChecker: Working directory:" << appDir;
    
    qint64 pid;
    if (QProcess::startDetached(updaterPath, args, appDir, &pid)) {
        qDebug() << "UpdateChecker: Updater started with PID:" << pid;
        qDebug() << "UpdateChecker: Exiting application in 1 second...";
        
        m_isDownloading = false;
        emit isDownloadingChanged();
        emit aboutToQuit();
        
        // Give the updater time to start before quitting
        QTimer::singleShot(1000, []() {
            qDebug() << "UpdateChecker: Calling QGuiApplication::exit(0)";
            QGuiApplication::exit(0);
        });
    } else {
        qWarning() << "UpdateChecker: Failed to start updater process";
        m_isDownloading = false;
        emit isDownloadingChanged();
        emit downloadFailed("Failed to start updater");
    }
#else
    m_isDownloading = false;
    emit isDownloadingChanged();
    emit downloadFailed("Auto-update not supported on this platform");
#endif
}

void UpdateChecker::ignoreUpdate()
{
    m_updateAvailable = false;
    emit updateAvailableChanged();
}

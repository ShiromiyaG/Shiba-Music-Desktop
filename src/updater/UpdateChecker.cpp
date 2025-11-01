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
        return;
    }

    m_isChecking = true;
    emit isCheckingChanged();

    QNetworkRequest request(QUrl("https://api.github.com/repos/ShiromiyaG/Shiba-Music-Desktop/releases/latest"));
    request.setHeader(QNetworkRequest::UserAgentHeader, "ShibaMusic-Updater");
    
    m_currentReply = m_networkManager->get(request);
    connect(m_currentReply, &QNetworkReply::finished, this, &UpdateChecker::onUpdateCheckFinished);
}

void UpdateChecker::onUpdateCheckFinished()
{
    m_isChecking = false;
    emit isCheckingChanged();

    if (!m_currentReply) {
        return;
    }

    if (m_currentReply->error() != QNetworkReply::NoError) {
        qWarning() << "Update check failed:" << m_currentReply->errorString();
        emit updateCheckFailed(m_currentReply->errorString());
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
        return;
    }

    QByteArray data = m_currentReply->readAll();
    m_currentReply->deleteLater();
    m_currentReply = nullptr;

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) {
        emit updateCheckFailed("Invalid JSON response");
        return;
    }

    QJsonObject release = doc.object();
    QString tagName = release["tag_name"].toString();
    
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
    if (compareVersions(currentVersion, m_latestVersion)) {
        m_updateAvailable = true;
        emit updateAvailableChanged();
        qDebug() << "Update available:" << currentVersion << "->" << m_latestVersion;
    } else {
        qDebug() << "No update available. Current:" << currentVersion << "Latest:" << m_latestVersion;
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
    if (m_downloadUrl.isEmpty() || m_isDownloading) {
        return;
    }

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
    m_isDownloading = false;
    emit isDownloadingChanged();

    if (!m_currentReply) {
        return;
    }

    if (m_currentReply->error() != QNetworkReply::NoError) {
        qWarning() << "Download failed:" << m_currentReply->errorString();
        emit downloadFailed(m_currentReply->errorString());
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
        return;
    }

    QByteArray data = m_currentReply->readAll();
    m_currentReply->deleteLater();
    m_currentReply = nullptr;

    QFile file(m_downloadPath);
    if (!file.open(QIODevice::WriteOnly)) {
        emit downloadFailed("Failed to save update file");
        return;
    }

    file.write(data);
    file.close();

    qDebug() << "Update downloaded to:" << m_downloadPath;
    installUpdate(m_downloadPath);
}

void UpdateChecker::installUpdate(const QString &zipPath)
{
#ifdef Q_OS_WIN
    QString tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation) + "/ShibaMusic-Update";
    QDir().mkpath(tempDir);

    // Create PowerShell script to extract and replace files
    QString scriptPath = tempDir + "/update.ps1";
    QFile scriptFile(scriptPath);
    
    if (scriptFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&scriptFile);
        out << "# Wait for app to close\n";
        out << "Start-Sleep -Seconds 2\n\n";
        out << "# Extract update\n";
        out << "$zipPath = '" << zipPath << "'\n";
        out << "$extractPath = '" << tempDir << "/extracted'\n";
        out << "$appDir = Split-Path -Parent $PSCommandPath\n";
        out << "$appDir = Split-Path -Parent $appDir\n";
        out << "$appDir = Split-Path -Parent $appDir\n\n";
        out << "Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force\n\n";
        out << "# Find the actual app folder inside extracted\n";
        out << "$sourceFolder = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1\n\n";
        out << "# Copy all files\n";
        out << "Copy-Item -Path \"$($sourceFolder.FullName)\\*\" -Destination $appDir -Recurse -Force\n\n";
        out << "# Cleanup\n";
        out << "Remove-Item -Path $extractPath -Recurse -Force\n";
        out << "Remove-Item -Path $zipPath -Force\n\n";
        out << "# Restart app\n";
        out << "Start-Process -FilePath \"$appDir\\shibamusic.exe\"\n\n";
        out << "# Delete this script\n";
        out << "Remove-Item -Path $PSCommandPath -Force\n";
        scriptFile.close();

        // Run script in background and exit app
        QProcess::startDetached("powershell.exe", 
            QStringList() << "-ExecutionPolicy" << "Bypass" 
                         << "-WindowStyle" << "Hidden" 
                         << "-File" << scriptPath);
        
        qDebug() << "Update script started. Exiting app...";
        QCoreApplication::quit();
    } else {
        emit downloadFailed("Failed to create update script");
    }
#else
    emit downloadFailed("Auto-update not supported on this platform");
#endif
}

void UpdateChecker::ignoreUpdate()
{
    m_updateAvailable = false;
    emit updateAvailableChanged();
}

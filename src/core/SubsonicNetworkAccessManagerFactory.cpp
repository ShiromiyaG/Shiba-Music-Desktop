#include "SubsonicNetworkAccessManagerFactory.h"

#include <QNetworkDiskCache>
#include <QStandardPaths>
#include <QDir>

SubsonicNetworkAccessManager::SubsonicNetworkAccessManager(QObject *parent)
    : QNetworkAccessManager(parent)
{
    auto *diskCache = new QNetworkDiskCache(this);
    const QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/network";
    QDir().mkpath(cacheDir);
    diskCache->setCacheDirectory(cacheDir);
    diskCache->setMaximumCacheSize(100 * 1024 * 1024); // 100 MB cap
    setCache(diskCache);
}

QNetworkReply *SubsonicNetworkAccessManager::createRequest(Operation op,
                                                           const QNetworkRequest &original,
                                                           QIODevice *outgoingData) {
    QNetworkRequest request(original);
    const auto path = request.url().path();
    if (path.contains("/rest/getCoverArt.view")) {
        request.setRawHeader("Accept", "image/jpeg,image/png;q=0.9,*/*;q=0.8");
    }
    return QNetworkAccessManager::createRequest(op, request, outgoingData);
}

QNetworkAccessManager *SubsonicNetworkAccessManagerFactory::create(QObject *parent) {
    return new SubsonicNetworkAccessManager(parent);
}

#include "SubsonicNetworkAccessManagerFactory.h"

SubsonicNetworkAccessManager::SubsonicNetworkAccessManager(QObject *parent)
    : QNetworkAccessManager(parent) {}

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

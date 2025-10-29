#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QQmlNetworkAccessManagerFactory>
#include <QIODevice>

class SubsonicNetworkAccessManager : public QNetworkAccessManager {


public:
    explicit SubsonicNetworkAccessManager(QObject *parent = nullptr);

protected:
    QNetworkReply *createRequest(Operation op,
                                 const QNetworkRequest &request,
                                 QIODevice *outgoingData = nullptr) override;
};

class SubsonicNetworkAccessManagerFactory : public QQmlNetworkAccessManagerFactory {
public:
    QNetworkAccessManager *create(QObject *parent) override;
};

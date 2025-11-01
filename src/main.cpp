#include <set>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQuickControls2/QQuickStyle>
#include "core/SubsonicClient.h"
#include "core/SubsonicNetworkAccessManagerFactory.h"
#include "core/AppInfo.h"
#include "playback/PlayerController.h"
#include "discord/DiscordRPC.h"

int main(int argc, char *argv[]) {
    QQuickStyle::setStyle("Material");
    QGuiApplication app(argc, argv);
    app.setOrganizationName("YourOrg");
    app.setApplicationName("Shiba Music");

    SubsonicClient api;
    DiscordRPC discord;
    PlayerController player(&api, &discord);
    AppInfo appInfo;

    QQmlApplicationEngine engine;
    engine.setNetworkAccessManagerFactory(new SubsonicNetworkAccessManagerFactory);
    engine.rootContext()->setContextProperty("api", &api);
    engine.rootContext()->setContextProperty("player", &player);
    engine.rootContext()->setContextProperty("discord", &discord);
    engine.rootContext()->setContextProperty("appInfo", &appInfo);
    engine.load(QUrl("qrc:/qml/main.qml"));
    if (engine.rootObjects().isEmpty()) return -1;
    return app.exec();
}

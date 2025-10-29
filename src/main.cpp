#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "core/SubsonicClient.h"
#include "playback/PlayerController.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setOrganizationName("YourOrg");
    app.setApplicationName("Shiba Music");

    SubsonicClient api;
    PlayerController player(&api);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("api", &api);
    engine.rootContext()->setContextProperty("player", &player);
    engine.load(QUrl("qrc:/qml/main.qml"));
    if (engine.rootObjects().isEmpty()) return -1;
    return app.exec();
}

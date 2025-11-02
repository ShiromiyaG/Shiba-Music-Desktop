#include <set>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQuickControls2/QQuickStyle>
#include <QIcon>
#include "core/SubsonicClient.h"
#include "core/SubsonicNetworkAccessManagerFactory.h"
#include "core/CacheManager.h"
#include "core/AppInfo.h"
#include "core/WindowStateManager.h"
#include "playback/PlayerController.h"
#include "discord/DiscordRPC.h"
#include "updater/UpdateChecker.h"
#include "i18n/TranslationManager.h"

int main(int argc, char *argv[]) {
    QQuickStyle::setStyle("Material");
    QGuiApplication app(argc, argv);
    app.setOrganizationName("YourOrg");
    app.setApplicationName("Shiba Music");
    
    // Set window icon
    app.setWindowIcon(QIcon(":/qml/icons/shiba_nobg_4k.ico"));

    QQmlApplicationEngine engine;
    
    // Initialize cache manager
    CacheManager cacheManager;
    if (!cacheManager.initialize()) {
        qWarning() << "Failed to initialize cache manager";
    }
    
    TranslationManager translationManager;
    SubsonicClient api;
    DiscordRPC discord;
    PlayerController player(&api, &discord);
    AppInfo appInfo;
    UpdateChecker updateChecker;
    WindowStateManager windowState;

    // Set engine reference for translation updates
    translationManager.setEngine(&engine);
    
    engine.setNetworkAccessManagerFactory(new SubsonicNetworkAccessManagerFactory);
    engine.rootContext()->setContextProperty("cacheManager", &cacheManager);
    engine.rootContext()->setContextProperty("translationManager", &translationManager);
    engine.rootContext()->setContextProperty("api", &api);
    engine.rootContext()->setContextProperty("player", &player);
    engine.rootContext()->setContextProperty("discord", &discord);
    engine.rootContext()->setContextProperty("appInfo", &appInfo);
    engine.rootContext()->setContextProperty("updateChecker", &updateChecker);
    engine.rootContext()->setContextProperty("windowStateManager", &windowState);
    engine.load(QUrl("qrc:/qml/main.qml"));
    if (engine.rootObjects().isEmpty()) return -1;
    return app.exec();
}

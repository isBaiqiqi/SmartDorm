#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "bluetoothmanager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName(u"od_ble"_qs);
    QCoreApplication::setApplicationName(u"appod_ble"_qs);

    BluetoothManager btManager;
    QQmlApplicationEngine engine;

    // 将 btManager 注册为全局变量，QML 中直接使用该名称
    engine.rootContext()->setContextProperty("btManager", &btManager);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    // qt_add_qml_module() 会把 Main.qml 打包进模块资源里
    engine.loadFromModule(u"od_ble"_qs, u"Main"_qs);

    return app.exec();
}

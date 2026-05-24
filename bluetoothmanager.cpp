#include "bluetoothmanager.h"
#include <QDebug>
#include <QBluetoothDeviceInfo>
#include <QBluetoothAddress>
#include <QCoreApplication>
#include <QGuiApplication>
#include <QSettings>
#include <QTimer>

#if QT_CONFIG(permissions)
#include <QPermissions>
#endif

#include <QLowEnergyController>
#include <QLowEnergyService>
#include <QLowEnergyCharacteristic>
#include <QtBluetooth/QLowEnergyController>

namespace {
constexpr int kDoorSweepStart = 90;
constexpr int kDoorSweepEnd = 20;
constexpr int kDoorResetAngle = 90;
constexpr int kDirectConnectTimeout = 5000;
}

BluetoothManager::BluetoothManager(QObject *parent) : QObject(parent) {
    m_discoveryAgent = new QBluetoothDeviceDiscoveryAgent(this);
    connect(m_discoveryAgent, &QBluetoothDeviceDiscoveryAgent::deviceDiscovered,
            this, &BluetoothManager::addDevice);
    connect(m_discoveryAgent, &QBluetoothDeviceDiscoveryAgent::finished,
            this, &BluetoothManager::discoveryFinished);
    connect(m_discoveryAgent, &QBluetoothDeviceDiscoveryAgent::canceled,
            this, &BluetoothManager::discoveryFinished);
    connect(m_discoveryAgent, &QBluetoothDeviceDiscoveryAgent::errorOccurred,
            this, &BluetoothManager::discoveryError);

    m_openPulseTimer = new QTimer(this);
    m_openPulseTimer->setSingleShot(true);
    connect(m_openPulseTimer, &QTimer::timeout, this, [this]() {
        enqueueServoByte(kDoorResetAngle);
        m_doorPulsing = false;
        emit doorPulsingChanged();
        setStatus(QStringLiteral("已复位至 %1°，一键开门！").arg(kDoorResetAngle));
    });

    m_connectTimeoutTimer = new QTimer(this);
    m_connectTimeoutTimer->setSingleShot(true);
    connect(m_connectTimeoutTimer, &QTimer::timeout, this, [this]() {
        if (!m_isConnected && m_controller) {
            setStatus(QStringLiteral("直连超时，请手动扫描或点击已配对设备重试"));
            stopController();
        }
    });

    if (auto *gui = qobject_cast<QGuiApplication *>(QCoreApplication::instance())) {
        connect(gui, &QGuiApplication::applicationStateChanged, this,
                [this](Qt::ApplicationState state) {
                    if (state == Qt::ApplicationActive)
                        tryAutoReconnectFromForeground();
                });
    }

    loadSavedDevices();

    QTimer::singleShot(1200, this, &BluetoothManager::tryAutoReconnectOnStartup);
}

void BluetoothManager::setScanning(bool scanning)
{
    if (m_isScanning == scanning)
        return;
    m_isScanning = scanning;
    emit scanningChanged();
}

void BluetoothManager::setStatus(const QString &status)
{
    if (m_status == status)
        return;
    m_status = status;
    emit statusChanged();
}

void BluetoothManager::setConnectedDeviceName(const QString &name)
{
    if (m_connectedDeviceName == name)
        return;
    m_connectedDeviceName = name;
    emit connectedDeviceNameChanged();
}

void BluetoothManager::loadSavedDevices()
{
    QSettings s;
    QStringList names = s.value(QStringLiteral("ble/saved_device_names")).toStringList();
    QStringList addrs = s.value(QStringLiteral("ble/saved_device_addresses")).toStringList();
    m_savedDevices.clear();
    m_savedDeviceMap.clear();
    for (int i = 0; i < names.size() && i < addrs.size(); ++i) {
        if (!names[i].isEmpty() && !addrs[i].isEmpty()) {
            m_savedDevices.append(names[i]);
            m_savedDeviceMap[names[i]] = addrs[i];
        }
    }
    emit savedDevicesChanged();
}

void BluetoothManager::saveDevice(const QString &name, const QString &address)
{
    QSettings s;
    QStringList names = s.value(QStringLiteral("ble/saved_device_names")).toStringList();
    QStringList addrs = s.value(QStringLiteral("ble/saved_device_addresses")).toStringList();

    int idx = names.indexOf(name);
    if (idx >= 0) {
        addrs[idx] = address;
    } else {
        names.append(name);
        addrs.append(address);
    }
    s.setValue(QStringLiteral("ble/saved_device_names"), names);
    s.setValue(QStringLiteral("ble/saved_device_addresses"), addrs);
    loadSavedDevices();
}

void BluetoothManager::forgetSavedDevice(const QString &name)
{
    QSettings s;
    QStringList names = s.value(QStringLiteral("ble/saved_device_names")).toStringList();
    QStringList addrs = s.value(QStringLiteral("ble/saved_device_addresses")).toStringList();

    int idx = names.indexOf(name);
    if (idx >= 0) {
        names.removeAt(idx);
        addrs.removeAt(idx);
        s.setValue(QStringLiteral("ble/saved_device_names"), names);
        s.setValue(QStringLiteral("ble/saved_device_addresses"), addrs);
    }

    if (m_lastConnectName == name) {
        QSettings().remove(QStringLiteral("ble/last_device_name"));
    }

    loadSavedDevices();
    setStatus(QStringLiteral("已解除配对：%1").arg(name));
}

void BluetoothManager::stopController()
{
    if (m_connectTimeoutTimer)
        m_connectTimeoutTimer->stop();
    if (m_controller) {
        m_controller->disconnectFromDevice();
        m_controller->deleteLater();
        m_controller = nullptr;
    }
}

void BluetoothManager::disconnectFromDevice()
{
    if (m_controller) {
        m_controller->disconnectFromDevice();
        setStatus(QStringLiteral("正在断开连接…"));
    }
}

void BluetoothManager::connectToSavedDevice(const QString &name)
{
    if (m_isConnected)
        return;

    QString address = m_savedDeviceMap.value(name);
    if (address.isEmpty()) {
        setStatus(QStringLiteral("保存的设备地址无效，请重新扫描连接"));
        return;
    }

    stopController();

    QBluetoothDeviceInfo info(QBluetoothAddress(address), name, 0);
    if (info.address().isNull()) {
        setStatus(QStringLiteral("连接失败：地址无效"));
        return;
    }

    if (m_discoveryAgent && m_discoveryAgent->isActive())
        m_discoveryAgent->stop();

    m_lastConnectName = name;
    m_connectedDeviceAddress = address;
    m_controller = QLowEnergyController::createCentral(info, this);

    connect(m_controller, &QLowEnergyController::connected, this, [this](){
        m_connectTimeoutTimer->stop();
        setConnectedDeviceName(m_lastConnectName);
        setStatus(QStringLiteral("已连接，发现服务中…"));
        m_controller->discoverServices();
    });
    connect(m_controller, &QLowEnergyController::disconnected, this, [this]() {
        clearDoorPulse();
        clearServoWriteState();
        m_isConnected = false;
        m_service = nullptr;
        setConnectedDeviceName(QString());
        emit connectedChanged();
        setStatus(QStringLiteral("已断开连接"));
    });
    connect(m_controller, &QLowEnergyController::serviceDiscovered,
            this, &BluetoothManager::serviceDiscovered);
    connect(m_controller, &QLowEnergyController::errorOccurred, this, [this](QLowEnergyController::Error){
        setStatus(QStringLiteral("直连失败：%1，可尝试扫描连接").arg(m_controller ? m_controller->errorString() : QString()));
        stopController();
    });

    setStatus(QStringLiteral("正在直连：%1").arg(name));
    m_connectTimeoutTimer->start(kDirectConnectTimeout);
    m_controller->connectToDevice();
}

void BluetoothManager::startDiscovery() {
    startDiscoveryWithAutoFlag(false);
}

void BluetoothManager::startDiscoveryWithAutoFlag(bool autoReconnect)
{
    m_pendingDiscoveryIsAuto = autoReconnect;
    if (autoReconnect) {
        QSettings s;
        m_savedReconnectName = s.value(QStringLiteral("ble/last_device_name")).toString();
        if (m_savedReconnectName.isEmpty()) {
            setStatus(QStringLiteral("无已保存设备，请先手动连接一次"));
            return;
        }
    }

#if QT_CONFIG(permissions)
    QBluetoothPermission permission;
    permission.setCommunicationModes(QBluetoothPermission::Access);
    auto *app = QCoreApplication::instance();
    const auto st = app ? app->checkPermission(permission) : Qt::PermissionStatus::Denied;
    if (st == Qt::PermissionStatus::Undetermined) {
        setStatus(QStringLiteral("请求蓝牙权限中…"));
        if (!app) {
            setStatus(QStringLiteral("权限请求失败：无应用实例"));
            setScanning(false);
            return;
        }
        const bool wantAuto = m_pendingDiscoveryIsAuto;
        app->requestPermission(permission, this, [this, wantAuto](const QPermission &p) {
            if (p.status() == Qt::PermissionStatus::Granted)
                startDiscoveryWithAutoFlag(wantAuto);
            else {
                setStatus(QStringLiteral("未获得蓝牙权限"));
                setScanning(false);
            }
        });
        return;
    }
    if (st != Qt::PermissionStatus::Granted) {
        setStatus(QStringLiteral("未获得蓝牙权限"));
        setScanning(false);
        return;
    }
#endif

    performDiscoveryStart();
}

void BluetoothManager::performDiscoveryStart()
{
    m_autoReconnectScan = m_pendingDiscoveryIsAuto;
    m_devices.clear();
    m_foundDevices.clear();
    emit devicesChanged();

    if (m_autoReconnectScan)
        setStatus(QStringLiteral("自动重连：正在扫描…"));
    else
        setStatus(QStringLiteral("正在扫描…"));
    setScanning(true);
    m_discoveryAgent->start(QBluetoothDeviceDiscoveryAgent::LowEnergyMethod);
}

void BluetoothManager::tryAutoReconnectOnStartup()
{
    if (m_isConnected)
        return;

    loadSavedDevices();

    if (!m_savedDevices.isEmpty()) {
        QString name = m_savedDevices.first().toString();
        connectToSavedDevice(name);
        return;
    }

    QSettings s;
    if (!s.value(QStringLiteral("ble/last_device_name")).toString().isEmpty())
        startDiscoveryWithAutoFlag(true);
}

void BluetoothManager::tryAutoReconnectFromForeground()
{
    if (m_isConnected)
        return;
    if (m_discoveryAgent && m_discoveryAgent->isActive())
        return;
    if (m_controller && m_controller->state() != QLowEnergyController::ConnectedState)
        return;

    loadSavedDevices();

    if (!m_savedDevices.isEmpty()) {
        QString name = m_savedDevices.first().toString();
        connectToSavedDevice(name);
        return;
    }

    QSettings s;
    if (!s.value(QStringLiteral("ble/last_device_name")).toString().isEmpty())
        startDiscoveryWithAutoFlag(true);
}

void BluetoothManager::addDevice(const QBluetoothDeviceInfo &device) {
    if (device.coreConfigurations() & QBluetoothDeviceInfo::LowEnergyCoreConfiguration) {
        QString name = device.name().isEmpty() ? device.address().toString() : device.name();
        if (!m_devices.contains(name)) {
            m_devices.append(name);
            m_foundDevices.append(device);
            emit devicesChanged();
            setStatus(QStringLiteral("发现设备：%1").arg(name));
        }

        if (m_autoReconnectScan && !m_isConnected && name == m_savedReconnectName) {
            setStatus(QStringLiteral("自动重连：匹配到已保存设备，正在连接…"));
            m_autoReconnectScan = false;
            if (m_discoveryAgent->isActive())
                m_discoveryAgent->stop();
            connectToDevice(name);
        }
    }
}

void BluetoothManager::discoveryFinished()
{
    setScanning(false);
    if (m_devices.isEmpty()) {
        setStatus(QStringLiteral("扫描结束：未发现设备（确认设备在广播 & 手机蓝牙已开）"));
    } else {
        setStatus(QStringLiteral("扫描结束：发现 %1 台设备").arg(m_devices.size()));
    }
    m_autoReconnectScan = false;
}

void BluetoothManager::discoveryError(QBluetoothDeviceDiscoveryAgent::Error error)
{
    Q_UNUSED(error);
    setScanning(false);
    m_autoReconnectScan = false;
    setStatus(QStringLiteral("扫描失败：%1").arg(m_discoveryAgent->errorString()));
}

void BluetoothManager::connectToDevice(const QString &name) {
    if (m_discoveryAgent->isActive())
        m_discoveryAgent->stop();

    for (const auto &info : m_foundDevices) {
        if (info.name() == name || info.address().toString() == name) {
            stopController();

            m_lastConnectName = name;
            m_connectedDeviceAddress = info.address().toString();
            m_controller = QLowEnergyController::createCentral(info, this);

            connect(m_controller, &QLowEnergyController::connected, this, [this](){
                setConnectedDeviceName(m_lastConnectName);
                setStatus(QStringLiteral("已连接，发现服务中…"));
                m_controller->discoverServices();
            });
            connect(m_controller, &QLowEnergyController::disconnected, this, [this]() {
                clearDoorPulse();
                clearServoWriteState();
                m_isConnected = false;
                m_service = nullptr;
                setConnectedDeviceName(QString());
                emit connectedChanged();
                setStatus(QStringLiteral("已断开连接"));
            });
            connect(m_controller, &QLowEnergyController::serviceDiscovered,
                    this, &BluetoothManager::serviceDiscovered);
            connect(m_controller, &QLowEnergyController::errorOccurred, this, [this](QLowEnergyController::Error){
                setStatus(QStringLiteral("连接失败：%1").arg(m_controller ? m_controller->errorString() : QString()));
                stopController();
            });

            setStatus(QStringLiteral("正在连接：%1").arg(name));
            m_controller->connectToDevice();
            return;
        }
    }
}

void BluetoothManager::serviceDiscovered(const QBluetoothUuid &gatt) {
    if (gatt == m_serviceUuid && m_controller) {
        m_service = m_controller->createServiceObject(gatt, this);
        if (m_service) {
            connect(m_service, &QLowEnergyService::stateChanged,
                    this, &BluetoothManager::updateServiceState);
            connect(m_service, &QLowEnergyService::characteristicWritten,
                    this, &BluetoothManager::onCharacteristicWritten);
            connect(m_service, &QLowEnergyService::errorOccurred,
                    this, &BluetoothManager::onServiceError);
            m_service->discoverDetails();
        }
    }
}

void BluetoothManager::updateServiceState(QLowEnergyService::ServiceState newState) {
    if (newState == QLowEnergyService::RemoteServiceDiscovered) {
        m_isConnected = true;
        emit connectedChanged();
        if (!m_lastConnectName.isEmpty()) {
            QSettings s;
            s.setValue(QStringLiteral("ble/last_device_name"), m_lastConnectName);
            if (!m_connectedDeviceAddress.isEmpty()) {
                saveDevice(m_lastConnectName, m_connectedDeviceAddress);
            }
        }
        setStatus(QStringLiteral("服务已就绪！！！"));
    }
}

void BluetoothManager::enqueueServoByte(int angle)
{
    if (angle < 0)
        angle = 0;
    if (angle > 180)
        angle = 180;
    if (!m_service || !m_isConnected)
        return;
    m_pendingServoAngles.enqueue(angle);
    tryStartNextServoWrite();
}

void BluetoothManager::tryStartNextServoWrite()
{
    if (m_servoWriteInFlight)
        return;
    if (m_pendingServoAngles.isEmpty())
        return;
    if (!m_service || !m_isConnected)
        return;

    QLowEnergyCharacteristic c = m_service->characteristic(m_charUuid);
    if (!c.isValid())
        return;

    const auto props = c.properties();
    if (!props.testFlag(QLowEnergyCharacteristic::WriteNoResponse)
        && !props.testFlag(QLowEnergyCharacteristic::Write)) {
        return;
    }

    const int angle = m_pendingServoAngles.dequeue();
    m_servoWriteInFlight = true;
    QByteArray data;
    data.append(static_cast<char>(angle));

    QLowEnergyService::WriteMode mode = QLowEnergyService::WriteWithResponse;
    if (props.testFlag(QLowEnergyCharacteristic::WriteNoResponse))
        mode = QLowEnergyService::WriteWithoutResponse;

    m_service->writeCharacteristic(c, data, mode);
}

void BluetoothManager::onCharacteristicWritten(const QLowEnergyCharacteristic &c, const QByteArray &value)
{
    Q_UNUSED(value);
    if (c.uuid() != m_charUuid)
        return;
    m_servoWriteInFlight = false;
    tryStartNextServoWrite();
}

void BluetoothManager::onServiceError(QLowEnergyService::ServiceError error)
{
    m_servoWriteInFlight = false;
    m_pendingServoAngles.clear();
    setStatus(QStringLiteral("GATT 错误（写入已中止）：%1").arg(int(error)));
}

void BluetoothManager::clearServoWriteState()
{
    m_pendingServoAngles.clear();
    m_servoWriteInFlight = false;
}

void BluetoothManager::setServoAngle(int angle) {
    enqueueServoByte(angle);
}

void BluetoothManager::clearDoorPulse()
{
    if (m_openPulseTimer)
        m_openPulseTimer->stop();
    if (m_doorPulsing) {
        m_doorPulsing = false;
        emit doorPulsingChanged();
    }
}

void BluetoothManager::pulseOpenDoor()
{
    if (!m_isConnected || !m_service)
        return;

    enqueueServoByte(kDoorSweepStart);
    enqueueServoByte(kDoorSweepEnd);
    setStatus(QStringLiteral("开门中 (%1°→%2°)！！！").arg(kDoorSweepStart).arg(kDoorSweepEnd));
    m_doorPulsing = true;
    emit doorPulsingChanged();
    m_openPulseTimer->stop();
    m_openPulseTimer->start(2000);
}

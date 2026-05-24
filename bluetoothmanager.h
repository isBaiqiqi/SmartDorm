#ifndef BLUETOOTHMANAGER_H
#define BLUETOOTHMANAGER_H

#include <QObject>
#include <QVariantList>
#include <QBluetoothUuid>
#include <QLowEnergyController>
#include <QLowEnergyCharacteristic>
#include <QLowEnergyService>
#include <QBluetoothDeviceDiscoveryAgent>
#include <QQueue>
#include <QHash>

class QTimer;

class BluetoothManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged)
    Q_PROPERTY(QVariantList savedDevices READ savedDevices NOTIFY savedDevicesChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(bool doorPulsing READ doorPulsing NOTIFY doorPulsingChanged)
    Q_PROPERTY(QString connectedDeviceName READ connectedDeviceName NOTIFY connectedDeviceNameChanged)
public:
    explicit BluetoothManager(QObject *parent = nullptr);

    QVariantList devices() const { return m_devices; }
    QVariantList savedDevices() const { return m_savedDevices; }
    bool connected() const { return m_isConnected; }
    bool scanning() const { return m_isScanning; }
    QString status() const { return m_status; }
    bool doorPulsing() const { return m_doorPulsing; }
    QString connectedDeviceName() const { return m_connectedDeviceName; }

    Q_INVOKABLE void startDiscovery();
    Q_INVOKABLE void connectToDevice(const QString &name);
    Q_INVOKABLE void connectToSavedDevice(const QString &name);
    Q_INVOKABLE void forgetSavedDevice(const QString &name);
    Q_INVOKABLE void disconnectFromDevice();
    Q_INVOKABLE void setServoAngle(int angle);
    Q_INVOKABLE void pulseOpenDoor();

signals:
    void devicesChanged();
    void savedDevicesChanged();
    void connectedChanged();
    void scanningChanged();
    void statusChanged();
    void doorPulsingChanged();
    void connectedDeviceNameChanged();

private slots:
    void addDevice(const QBluetoothDeviceInfo &device);
    void serviceDiscovered(const QBluetoothUuid &gatt);
    void updateServiceState(QLowEnergyService::ServiceState newState);
    void discoveryFinished();
    void discoveryError(QBluetoothDeviceDiscoveryAgent::Error error);
    void onCharacteristicWritten(const QLowEnergyCharacteristic &c, const QByteArray &value);
    void onServiceError(QLowEnergyService::ServiceError error);
    void tryAutoReconnectOnStartup();
    void tryAutoReconnectFromForeground();

private:
    void setScanning(bool scanning);
    void setStatus(const QString &status);
    void enqueueServoByte(int angle);
    void tryStartNextServoWrite();
    void clearServoWriteState();
    void clearDoorPulse();
    void performDiscoveryStart();
    void startDiscoveryWithAutoFlag(bool autoReconnect);
    void loadSavedDevices();
    void saveDevice(const QString &name, const QString &address);
    void stopController();
    void setConnectedDeviceName(const QString &name);

    QBluetoothDeviceDiscoveryAgent *m_discoveryAgent;
    QLowEnergyController *m_controller = nullptr;
    QLowEnergyService *m_service = nullptr;

    QVariantList m_devices;
    QList<QBluetoothDeviceInfo> m_foundDevices;
    QVariantList m_savedDevices;
    QHash<QString, QString> m_savedDeviceMap;

    bool m_isConnected = false;
    bool m_isScanning = false;
    QString m_status;
    QString m_lastConnectName;
    QString m_connectedDeviceName;
    QString m_connectedDeviceAddress;
    QString m_savedReconnectName;
    bool m_autoReconnectScan = false;
    bool m_pendingDiscoveryIsAuto = false;

    QTimer *m_openPulseTimer = nullptr;
    QTimer *m_connectTimeoutTimer = nullptr;
    bool m_doorPulsing = false;
    QQueue<int> m_pendingServoAngles;
    bool m_servoWriteInFlight = false;

    const QBluetoothUuid m_serviceUuid{QString("0000ff01-0000-1000-8000-00805f9b34fb")};
    const QBluetoothUuid m_charUuid{QString("0000ff02-0000-1000-8000-00805f9b34fb")};
};

#endif // BLUETOOTHMANAGER_H

#ifndef BLUETOOTHMANAGER_H // 如果没有定义 BLUETOOTHMANAGER_H
#define BLUETOOTHMANAGER_H // 则定义它，防止头文件被重复包含

#include <QObject> // 包含 Qt 核心对象基类
#include <QVariantList> // 包含用于同 QML 交互的通用列表类型
#include <QBluetoothUuid> // 包含蓝牙全局唯一标识符类
#include <QLowEnergyController> // 包含低功耗蓝牙连接控制器类
#include <QLowEnergyCharacteristic> // 包含蓝牙特征值类（读写数据的基本单位）
#include <QLowEnergyService> // 包含蓝牙服务类
#include <QBluetoothDeviceDiscoveryAgent> // 包含蓝牙设备搜索代理类

#include <QQueue> // 包含队列容器，用于管理待发送的指令

class QTimer; // 前向声明定时器类，优化编译速度

class BluetoothManager : public QObject // 定义继承自 QObject 的蓝牙管理类
{
    Q_OBJECT // 开启 Qt 元对象系统宏，支持信号槽和属性系统

    // 暴露给 QML 使用的属性：读取函数、通知信号
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged) // 已发现设备列表
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged) // 当前连接状态
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged) // 是否正在扫描
    Q_PROPERTY(QString status READ status NOTIFY statusChanged) // 当前状态描述文字
    Q_PROPERTY(bool doorPulsing READ doorPulsing NOTIFY doorPulsingChanged) // 是否正在执行开门脉冲

public:
    explicit BluetoothManager(QObject *parent = nullptr); // 构造函数，可指定父对象

    // 属性读取函数（Getter），供外部或 QML 访问内部变量
    QVariantList devices() const { return m_devices; } // 返回设备列表
    bool connected() const { return m_isConnected; } // 返回连接标志位
    bool scanning() const { return m_isScanning; } // 返回扫描标志位
    QString status() const { return m_status; } // 返回状态字符串
    bool doorPulsing() const { return m_doorPulsing; } // 返回开门中标志位

    // 可在 QML 中通过 JavaScript 直接调用的函数
    Q_INVOKABLE void startDiscovery(); // 开始搜索蓝牙设备
    Q_INVOKABLE void connectToDevice(const QString &name); // 通过名称连接到指定设备
    Q_INVOKABLE void setServoAngle(int angle); // 发送角度指令给舵机
    /// 一键开门逻辑：舵机转动并延时自动复位，内部处理串行发送以兼容 iOS
    Q_INVOKABLE void pulseOpenDoor();

signals:
    // 当对应的属性值发生变化时发送的信号，用于触发 UI 刷新
    void devicesChanged(); // 设备列表变化信号
    void connectedChanged(); // 连接状态变化信号
    void scanningChanged(); // 扫描状态变化信号
    void statusChanged(); // 状态文字变化信号
    void doorPulsingChanged(); // 开门状态变化信号

private slots:
    // 内部私有槽函数，处理蓝牙库触发的异步回调
    void addDevice(const QBluetoothDeviceInfo &device); // 发现新设备时的处理逻辑
    void serviceDiscovered(const QBluetoothUuid &gatt); // 找到 GATT 服务时的处理逻辑
    void updateServiceState(QLowEnergyService::ServiceState newState); // 服务状态更新（如发现特征值）
    void discoveryFinished(); // 搜索结束的处理逻辑
    void discoveryError(QBluetoothDeviceDiscoveryAgent::Error error); // 搜索出错时的处理逻辑
    void onCharacteristicWritten(const QLowEnergyCharacteristic &c, const QByteArray &value); // 数据写入硬件后的确认回调
    void onServiceError(QLowEnergyService::ServiceError error); // 服务操作出错处理
    void tryAutoReconnectOnStartup(); // 程序启动时尝试自动连接已知设备
    void tryAutoReconnectFromForeground(); // 程序从后台切回前台时尝试恢复连接

private:
    // 蓝牙底层操作对象指针
    QBluetoothDeviceDiscoveryAgent *m_discoveryAgent; // 蓝牙搜索代理对象
    QLowEnergyController *m_controller = nullptr; // 负责连接和通信的控制器对象
    QLowEnergyService *m_service = nullptr; // 当前正在交互的 BLE 服务对象

    // 内部数据存储
    QVariantList m_devices; // 存储给 UI 展示的设备信息列表
    QList<QBluetoothDeviceInfo> m_foundDevices; // 存储搜索到的原生蓝牙设备对象列表
    bool m_isConnected = false; // 连接状态变量
    bool m_isScanning = false; // 扫描状态变量
    QString m_status; // 状态描述文字存储

    // 内部私有逻辑辅助函数
    void setScanning(bool scanning); // 更新扫描状态并触发信号
    void setStatus(const QString &status); // 更新状态文字并触发信号
    void enqueueServoByte(int angle); // 将舵机角度加入待发送队列
    void tryStartNextServoWrite(); // 尝试从队列中取出并发送下一条角度数据
    void clearServoWriteState(); // 清理发送状态（如断开连接时）
    void clearDoorPulse(); // 结束开门脉冲状态
    void performDiscoveryStart(); // 执行真实的搜索启动动作
    void startDiscoveryWithAutoFlag(bool autoReconnect); // 带有自动重连标识的搜索

    QString m_lastConnectName; // 记录最后一次手动连接的设备名
    QString m_savedReconnectName; // 从本地存储加载的、需要自动重连的设备名
    bool m_autoReconnectScan = false; // 标记当前的搜索是否为自动重连搜索
    bool m_pendingDiscoveryIsAuto = false; // 标记挂起的搜索任务是否为自动重连

    QTimer *m_openPulseTimer = nullptr; // 处理开门延迟复位的定时器
    bool m_doorPulsing = false; // 标识是否正处于开门脉冲过程中
    QQueue<int> m_pendingServoAngles; // 舵机角度指令队列（防止并发写入）
    bool m_servoWriteInFlight = false; // 标记当前是否有指令正在空中传输（锁定机制）

    // 硬件协议 UUID（需与 ESP32 等下位机代码保持绝对一致）
    const QBluetoothUuid m_serviceUuid{QString("0000ff01-0000-1000-8000-00805f9b34fb")}; // 服务 UUID
    const QBluetoothUuid m_charUuid{QString("0000ff02-0000-1000-8000-00805f9b34fb")}; // 特征值 UUID（写数据接口）
};

#endif // BLUETOOTHMANAGER_H

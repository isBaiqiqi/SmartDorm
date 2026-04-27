import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    width: 400
    height: 800
    visible: true
    color: "#f2f4f7"

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: homePage
    }

    // =========================
    // 🏠 首页
    // =========================
    Component {
        id: homePage

        Flickable {
            contentWidth: parent.width
            contentHeight: contentColumn.height
            anchors.fill: parent

            Column {
                id: contentColumn
                width: parent.width
                spacing: 16
                anchors.margins: 16

                // 标题
                Text {
                    text: "智慧寝室"
                    font.pixelSize: 26
                    font.bold: true
                    font.family: "Arial"
                    color: "#333"
                }

                Text {
                    text: btManager.status
                    color: "#666"
                }

                // 卡片
                Rectangle {
                    width: parent.width
                    height: 100
                    radius: 12
                    color: "white"

                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Rectangle {
                            width: 60
                            height: 60
                            radius: 10
                            color: "#4a90e2"
                        }

                        Column {
                            spacing: 4

                            Text { text: "3栋 304" }
                            Text { text: "4人间 | 当前 4/4"; color: "#888" }
                        }
                    }
                }

                // ===== 开门按钮（带动画）=====
                Rectangle {
                    id: doorButton
                    width: 220
                    height: 220
                    radius: 110
                    color: btManager.connected ? "#4a90e2" : "#cccccc"
                    anchors.horizontalCenter: parent.horizontalCenter

                    scale: 1.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutQuad
                        }
                    }

                    // 呼吸动画
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: btManager.connected

                        NumberAnimation { from: 1.0; to: 0.85; duration: 1200 }
                        NumberAnimation { from: 0.85; to: 1.0; duration: 1200 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: btManager.connected && !btManager.doorPulsing

                        onPressed: doorButton.scale = 0.9
                        onReleased: {
                            doorButton.scale = 1.0
                            btManager.pulseOpenDoor()
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "🔓"
                            font.pixelSize: 40
                        }

                        Text {
                            text: btManager.doorPulsing ? "开门中…" : "点击开门"
                            color: "white"
                        }
                    }
                }

                // 功能入口
                Row {
                    width: parent.width
                    spacing: 10

                    Repeater {
                        model: ["成员管理", "开门记录", "设备管理", "通知"]

                        delegate: Rectangle {
                            width: (parent.width - 30) / 4
                            height: 70
                            radius: 10
                            color: "white"

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (modelData === "设备管理") {
                                        stack.push(devicePage)
                                    }
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 5

                                Text { text: "📦" }
                                Text { text: modelData; font.pixelSize: 10 }
                            }
                        }
                    }
                }

                // 数据卡片（无分号版本）
                Rectangle {
                    width: parent.width
                    height: 120
                    radius: 12
                    color: "white"

                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 20

                        Column {
                            Text { text: "温度" }
                            Text { text: "26°C" }
                        }

                        Column {
                            Text { text: "湿度" }
                            Text { text: "50%" }
                        }

                        Column {
                            Text { text: "电量" }
                            Text { text: "85%" }
                        }

                        Column {
                            Text { text: "安全" }
                            Text { text: "正常" }
                        }
                    }
                }
            }
        }
    }

    // =========================
    // ⚙️ 设备管理页
    // =========================
    Component {
        id: devicePage

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Button {
                text: "← 返回"
                onClicked: stack.pop()
            }

            Text {
                text: "设备管理"
                font.pixelSize: 22
                font.bold: true
            }

            Text {
                text: btManager.status
                color: "#666"
            }

            Button {
                text: btManager.scanning ? "扫描中…" : "搜索 ESP32"
                enabled: !btManager.scanning
                onClicked: btManager.startDiscovery()
            }

            ListView {
                width: parent.width
                height: 200
                clip: true
                model: btManager.devices

                delegate: Rectangle {
                    width: parent.width
                    height: 50
                    radius: 8
                    color: "white"

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: btManager.connectToDevice(modelData)
                    }
                }
            }

            Column {
                spacing: 10
                visible: btManager.connected

                Text {
                    text: "控制角度: " + servoSlider.value + "°"
                    font.bold: true
                }

                Slider {
                    id: servoSlider
                    from: 0
                    to: 180
                    stepSize: 1
                    onMoved: btManager.setServoAngle(value)
                }
            }
        }
    }
}

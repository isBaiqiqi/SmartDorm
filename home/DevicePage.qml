import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 1. 去掉 Component，改用 Page
Page {
    id: devicePage

    // 【关键】：在根节点先拿到 stack 引用
    readonly property StackView stack: StackView.view

    // 背景色（可选，Page默认透明或跟随主题）
    background: Rectangle { color: "#f5f5f5" }

    // 2. 建议把标题栏放在 Page 的 header 里，这样滚动时标题不会消失
    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            ToolButton {
                text: "← 返回"
                // 使用 StackView.view.pop() 比直接写 homeStack 更稳
                onClicked: {
                    if (devicePage.stack) {
                        devicePage.stack.pop()
                    } else {
                        console.error("返回失败：无法获取 StackView")
                    }
                }
            }
            Label {
                text: "设备管理"
                font.bold: true
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Item { Layout.preferredWidth: 40 } // 占位保持居中
        }
    }

    // 3. 页面内容
    Flickable {
        anchors.fill: parent
        contentHeight: contentCol.height
        clip: true

        Column {
            id: contentCol
            width: parent.width - 32
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 16
            spacing: 12

            Text {
                text: "当前状态: " + btManager.status
                color: "#666"
            }

            Button {
                width: parent.width
                text: btManager.scanning ? "扫描中…" : "搜索 ESP32"
                enabled: !btManager.scanning
                onClicked: btManager.startDiscovery()
            }

            // 设备列表
            ListView {
                width: parent.width
                height: 300 // 建议给固定高度或根据内容计算
                clip: true
                model: btManager.devices
                delegate: Rectangle {
                    width: parent.width
                    height: 50
                    radius: 8
                    color: "white"
                    border.color: "#ddd"

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

            // 控制区域
            Column {
                width: parent.width
                spacing: 10
                visible: btManager.connected

                Text {
                    text: "控制角度: " + servoSlider.value + "°"
                    font.bold: true
                }

                Slider {
                    id: servoSlider
                    width: parent.width
                    from: 0
                    to: 180
                    stepSize: 1
                    onMoved: btManager.setServoAngle(value)
                }
            }
        }
    }
}

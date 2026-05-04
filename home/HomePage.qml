import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Flickable {
    id: root

    readonly property StackView stack: StackView.view

    contentWidth: parent.width
    contentHeight: contentColumn.height
    anchors.fill: parent
    clip: true // 建议加上，防止内容溢出边界

    Column {
        id: contentColumn
        width: parent.width
        spacing: 16
        // 注意：Column 的 margins 属性在 QML 中不生效，需使用 padding
        padding: 16

        // 1. 标题
        Label {
            text: "智慧寝室"
            font.pixelSize: 26
            font.bold: true
            color: "#333"
        }

        Text {
            text: btManager.status
            color: "#666"
        }

        // 2. 房间信息卡片
        Rectangle {
            width: parent.width - 24
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            height: 100
            radius: 12
            color: "white"
            // 添加阴影或边框让卡片更明显
            border.color: "#f0f0f0"

            Row {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Rectangle {
                    width: 60; height: 60
                    radius: 10
                    color: "#4a90e2"
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Text { text: "汤城一品 404"; font.bold: true }
                    Text { text: "4人间 | 当前 4/4"; color: "#888" }
                }
            }
        }

        // 在 QML 的 Column 布局中，最灵活的做法是在两个组件之间插入一个透明的 Item，手动指定其高度。
        Item {
            width: 1; height: 30 - parent.spacing // 减去 Column 原有的 spacing
        }

        // 3. 开门按钮
        Rectangle {
            id: doorButton
            width: 200; height: 200
            radius: 100
            color: btManager.connected ? "#4a90e2" : "#cccccc"
            anchors.horizontalCenter: parent.horizontalCenter
            scale: 1.0

            Behavior on scale { NumberAnimation { duration: 150 } }

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
                Text { text: "🔓"; font.pixelSize: 40; anchors.horizontalCenter: parent }
                Text {
                    text: btManager.doorPulsing ? "开门中…" : "点击开门"
                    color: "white"
                    anchors.horizontalCenter: parent
                }
            }
        }


        // 在 QML 的 Column 布局中，最灵活的做法是在两个组件之间插入一个透明的 Item，手动指定其高度。
        Item {
            width: 1; height: 30 - parent.spacing // 减去 Column 原有的 spacing
        }

        // 4. 功能入口 (修正跳转逻辑)
        Row {
            id: functionEntry
            width: parent.width - 24
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            Repeater {
                model: ["成员管理", "开门记录", "设备管理", "通知"]

                delegate: Rectangle {
                    // 自动计算宽度，减去 spacing
                    width: (contentColumn.width - contentColumn.padding * 2 - 30) / 4
                    height: 80
                    radius: 10
                    color: itemMouse.pressed ? "#f0f0f0" : "white"
                    border.color: "#f0f0f0"

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        onClicked: {
                            console.log("尝试跳转到: " + modelData)
                            if (modelData === "设备管理") {
                                // 【关键修正】：使用附加属性 StackView.view
                                // 不要使用 homeStack.view
                                if (root.stack) {
                                    root.stack.push("DevicePage.qml")
                                } else {
                                    console.error("依然找不到 StackView")
                                }
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: "📦"; font.pixelSize: 20; anchors.horizontalCenter: parent }
                        Text { text: modelData; font.pixelSize: 11; anchors.horizontalCenter: parent }
                    }
                }
            }
        }

        // 5. 数据卡片
        Rectangle {
            width: parent.width - 24
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            height: 100
            radius: 12
            color: "white"
            border.color: "#f0f0f0"

            GridLayout {
                anchors.fill: parent
                columns: 4
                rows: 1

                // 内部使用延展布局更整齐
                Repeater {
                    model: [
                        {t: "温度", v: "26°C"},
                        {t: "湿度", v: "50%"},
                        {t: "电量", v: "85%"},
                        {t: "安全", v: "正常"}
                    ]
                    Column {
                        Layout.alignment: Qt.AlignCenter
                        Text { text: modelData.t; color: "#888"; font.pixelSize: 12; anchors.horizontalCenter: parent }
                        Text { text: modelData.v; font.bold: true; anchors.horizontalCenter: parent }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Flickable {
    id: root

    readonly property StackView stack: StackView.view

    contentWidth: parent.width
    contentHeight: contentColumn.height
    anchors.fill: parent
    clip: true

    Column {
        id: contentColumn
        width: parent.width
        spacing: 12
        // 这里保留 padding，作为全局的基础边距
        padding: 12

        // 1. 标题
        Label {
            text: "智慧寝室"
            font.pixelSize: 26
            font.bold: true
            color: "#333"
            // 补偿标题位置
            leftPadding: 0
        }

        Text {
            text: btManager.status
            color: "#666"
        }

        // 2. 房间信息卡片
        Rectangle {
            // 修正：宽度通过锚点固定，并保留两侧 12 间距
            width: parent.width - (contentColumn.padding * 2)
            height: 100
            radius: 12
            color: "white"
            border.color: "#f0f0f0"
            anchors.horizontalCenter: parent.horizontalCenter

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

        Item { width: 1; height: 15 } // 间距调整

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
                    text: btManager.doorPulsing ? "开门中…" : "玄武开门"
                    color: "white"
                    anchors.horizontalCenter: parent
                }
            }
        }

        Item { width: 1; height: 15 }

        // 4. 功能入口
        Row {
            id: functionEntry
            // 修正：确保 Row 的宽度也减去 padding
            width: parent.width - (contentColumn.padding * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Repeater {
                model: ["成员管理", "开门记录", "设备管理", "通知"]

                delegate: Rectangle {
                    // 动态计算宽度：(总宽 - 3个间隔) / 4
                    width: (functionEntry.width - (3 * functionEntry.spacing)) / 4
                    height: 80
                    radius: 10
                    color: itemMouse.pressed ? "#f0f0f0" : "white"
                    border.color: "#f0f0f0"

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        onClicked: {
                            if (modelData === "设备管理") {
                                if (root.stack) root.stack.push("DevicePage.qml")
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

        // 5. 数据卡片 (均匀排布 + 两侧 12 边距)
        Rectangle {
            width: parent.width - (contentColumn.padding * 2)
            height: 200
            radius: 12
            color: "white"
            border.color: "#f0f0f0"
            anchors.horizontalCenter: parent.horizontalCenter

            GridLayout {
                anchors.fill: parent
                columns: 4
                rows: 2
                columnSpacing: 0
                rowSpacing: 0

                Repeater {
                    model: [
                        {t: "温度", v: "26°C"}, {t: "湿度", v: "50%"},
                        {t: "电量", v: "85%"}, {t: "安全", v: "正常"},
                        {t: "电压", v: "7.4V"}, {t: "电流", v: "0.2A"},
                        {t: "功率", v: "1.48W"}, {t: "耗电", v: "0.01度"}
                    ]

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: modelData.t
                                color: "#888"
                                font.pixelSize: 12
                                anchors.horizontalCenter: parent
                            }
                            Text {
                                text: modelData.v
                                font.bold: true
                                font.pixelSize: 14
                                color: "#333"
                                anchors.horizontalCenter: parent
                            }
                        }
                    }
                }
            }
        }
    }
}

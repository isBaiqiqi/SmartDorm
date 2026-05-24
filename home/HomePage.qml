import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    readonly property StackView stack: StackView.view
    readonly property real availH: root.height
    anchors.fill: parent

    // 比例分配（总和约 95%）
    readonly property real rTitle:     0.04
    readonly property real rStatus:    0.06
    readonly property real rRoomCard:  0.11
    readonly property real rDoorGapT:  0.04
    readonly property real rDoorBtn:   0.30
    readonly property real rDoorGapB:  0.05
    readonly property real rFuncEntry: 0.11
    readonly property real rFuncGap:   0.015
    readonly property real rDataCard:  0.215
    readonly property real rBottomGap: 0.01
    readonly property real rPadding:   0.015

    Flickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: Math.max(parent.height, contentCol.implicitHeight)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentCol
            width: parent.width
            spacing: 0
            topPadding: availH * rPadding

            // 1. 标题
            Label {
                text: "智慧寝室"
                font.pixelSize: Math.max(20, availH * rTitle)
                font.bold: true
                color: "#333"
                leftPadding: 14
            }

            // 2. 状态
            Text {
                text: btManager.status
                color: "#666"
                font.pixelSize: 13
                leftPadding: 14
                height: availH * rStatus
                verticalAlignment: Text.AlignVCenter
            }

            // 3. 房间卡片
            Rectangle {
                width: parent.width - 20
                height: availH * rRoomCard
                radius: 12
                color: "white"
                border.color: "#f0f0f0"
                anchors.horizontalCenter: parent.horizontalCenter

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Rectangle {
                        width: height
                        height: parent.height - anchors.margins * 2
                        radius: 8
                        color: "#4a90e2"
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text { text: "汤臣一品 404"; font.bold: true; font.pixelSize: 14 }
                        Text { text: "4人间 | 当前 4/4"; color: "#888"; font.pixelSize: 12 }
                    }
                }
            }

            // 门按钮上方留白
            Item { width: 1; height: availH * rDoorGapT }

            // 4. 开门按钮
            Rectangle {
                id: doorBtn
                property real sz: availH * rDoorBtn
                width: sz
                height: sz
                radius: sz / 2
                color: btManager.connected ? "#4a90e2" : "#cccccc"
                anchors.horizontalCenter: parent.horizontalCenter
                scale: 1.0

                Behavior on scale { NumberAnimation { duration: 150 } }

                MouseArea {
                    anchors.fill: parent
                    enabled: btManager.connected && !btManager.doorPulsing
                    onPressed: doorBtn.scale = 0.9
                    onReleased: {
                        doorBtn.scale = 1.0
                        btManager.pulseOpenDoor()
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: doorBtn.sz * 0.04
                    Text {
                        text: "🚪"
                        font.pixelSize: doorBtn.sz * 0.22
                        anchors.horizontalCenter: parent
                    }
                    Text {
                        text: btManager.doorPulsing ? "开门中…" : "玄武开门"
                        color: "white"
                        font.pixelSize: doorBtn.sz * 0.09
                        anchors.horizontalCenter: parent
                    }
                }
            }

            // 门按钮下方留白
            Item { width: 1; height: availH * rDoorGapB }

            // 5. 功能入口
            Row {
                id: funcRow
                width: parent.width - 20
                height: availH * rFuncEntry
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                Repeater {
                    model: ["成员管理", "开门记录", "设备管理", "消息通知"]

                    delegate: Rectangle {
                        width: (funcRow.width - (3 * funcRow.spacing)) / 4
                        height: parent.height
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
                            spacing: Math.max(5, parent.height * 0.10)
                            Text {
                                text: "📦"
                                font.pixelSize: Math.max(18, parent.height * 0.28)
                                anchors.horizontalCenter: parent
                            }
                            Text {
                                text: modelData
                                font.pixelSize: Math.max(11, parent.height * 0.17)
                                anchors.horizontalCenter: parent
                            }
                        }
                    }
                }
            }

            // 功能入口 → 数据卡片间距
            Item { width: 1; height: availH * rFuncGap }

            // 6. 数据卡片
            Rectangle {
                width: parent.width - 20
                height: availH * rDataCard
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
                                spacing: 3
                                Text {
                                    text: modelData.t
                                    color: "#888"
                                    font.pixelSize: 12
                                    anchors.horizontalCenter: parent
                                }
                                Text {
                                    text: modelData.v
                                    font.bold: true
                                    font.pixelSize: 13
                                    color: "#333"
                                    anchors.horizontalCenter: parent
                                }
                            }
                        }
                    }
                }
            }

            // 底部间距（紧贴导航栏上方）
            Item { width: 1; height: availH * rBottomGap }
        }
    }
}



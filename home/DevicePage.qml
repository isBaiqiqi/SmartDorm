import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: devicePage

    readonly property StackView stack: StackView.view

    background: Rectangle { color: "#f5f5f5" }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            ToolButton {
                text: "\u2190 \u8fd4\u56de"
                onClicked: {
                    if (devicePage.stack) {
                        devicePage.stack.pop()
                    }
                }
            }
            Label {
                text: "\u8bbe\u5907\u7ba1\u7406"
                font.bold: true
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Item { Layout.preferredWidth: 40 }
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: contentCol.height
        clip: true

        Column {
            id: contentCol
            width: parent.width - 32
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 16
            spacing: 12

            // Status
            Text {
                text: btManager.status
                color: "#666"
                width: parent.width
                wrapMode: Text.WordWrap
            }

            // --- Section 1: Saved / Paired Devices ---
            Label {
                text: "\u5df2\u914d\u5bf9\u8bbe\u5907"
                font.bold: true
                font.pixelSize: 16
                color: "#333"
            }

            Rectangle {
                width: parent.width
                height: savedCol.height + 16
                radius: 10
                color: "white"
                border.color: "#e0e0e0"

                Column {
                    id: savedCol
                    width: parent.width - 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 8
                    spacing: 4

                    Repeater {
                        model: btManager.savedDevices
                        delegate: Rectangle {
                            width: parent.width
                            height: 56
                            color: "transparent"
                            radius: 8

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                // Status dot
                                Rectangle {
                                    width: 10; height: 10; radius: 5
                                    color: {
                                        if (modelData === btManager.connectedDeviceName) return "#4caf50"
                                        return "#bbbbbb"
                                    }
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth: 10
                                }

                                // Device name
                                Text {
                                    text: modelData
                                    font.pixelSize: 14
                                    color: "#333"
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    elide: Text.ElideRight
                                }

                                // Status badge
                                Rectangle {
                                    radius: 10
                                    color: modelData === btManager.connectedDeviceName ? "#e8f5e9" : "#f5f5f5"
                                    implicitWidth: statusLabel.implicitWidth + 20
                                    implicitHeight: 26
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        id: statusLabel
                                        anchors.centerIn: parent
                                        text: modelData === btManager.connectedDeviceName ? "\u5df2\u8fde\u63a5" : "\u79bb\u7ebf"
                                        font.pixelSize: 12
                                        color: modelData === btManager.connectedDeviceName ? "#4caf50" : "#999999"
                                    }
                                }

                                // Action button
                                Rectangle {
                                    radius: 6
                                    color: modelData === btManager.connectedDeviceName ? "#ffebee" : "#e8f0fe"
                                    implicitWidth: actionLabel.implicitWidth + 16
                                    implicitHeight: 30
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        id: actionLabel
                                        anchors.centerIn: parent
                                        text: modelData === btManager.connectedDeviceName ? "\u65ad\u5f00\u8fde\u63a5" : "\u8fde\u63a5"
                                        font.pixelSize: 13
                                        color: modelData === btManager.connectedDeviceName ? "#e53935" : "#4a8ffc"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (modelData === btManager.connectedDeviceName)
                                                btManager.disconnectFromDevice()
                                            else
                                                btManager.connectToSavedDevice(modelData)
                                        }
                                    }
                                }

                                // Unpair button
                                ToolButton {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth: 30
                                    Layout.preferredHeight: 30
                                    opacity: 0.4
                                    contentItem: Text {
                                        text: "\u2715"
                                        font.pixelSize: 14
                                        color: "#999"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle { color: "transparent" }
                                    onClicked: btManager.forgetSavedDevice(modelData)
                                }
                            }
                        }
                    }

                    Text {
                        visible: btManager.savedDevices.length === 0
                        text: "\u5c1a\u65e0\u5df2\u914d\u5bf9\u8bbe\u5907\uff0c\u8bf7\u5148\u626b\u63cf\u5e76\u8fde\u63a5\u8bbe\u5907"
                        color: "#999"
                        font.pixelSize: 13
                        anchors.horizontalCenter: parent.horizontalCenter
                        topPadding: 20
                        bottomPadding: 12
                    }
                }
            }

            // --- Section 2: Scan Button ---
            Button {
                width: parent.width
                height: 44
                text: btManager.scanning ? "\u626b\u63cf\u4e2d\u2026" : "\u626b\u63cf\u65b0\u8bbe\u5907"
                enabled: !btManager.scanning
                contentItem: Text {
                    text: parent.text; color: "white"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.enabled ? "#4a8ffc" : "#b0cffc"
                    radius: 8
                }
                onClicked: btManager.startDiscovery()
            }

            // --- Section 3: Scanned Devices ---
            Label {
                text: "\u626b\u63cf\u8bbe\u5907"
                font.bold: true
                font.pixelSize: 16
                color: "#333"
            }

            Rectangle {
                width: parent.width
                height: scannedCol.height + 16
                radius: 10
                color: "white"
                border.color: "#e0e0e0"

                Column {
                    id: scannedCol
                    width: parent.width - 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 8
                    spacing: 4

                    Repeater {
                        model: btManager.devices
                        delegate: Rectangle {
                            width: parent.width
                            height: 48
                            color: "transparent"
                            radius: 8

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Rectangle {
                                    width: 10; height: 10; radius: 5
                                    color: "#4a8ffc"
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth: 10
                                }

                                Text {
                                    text: modelData
                                    font.pixelSize: 14
                                    color: "#333"
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    radius: 6
                                    color: "#e8f0fe"
                                    implicitWidth: 56
                                    implicitHeight: 30
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\u8fde\u63a5"
                                        font.pixelSize: 13
                                        color: "#4a8ffc"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: btManager.connectToDevice(modelData)
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: btManager.devices.length === 0
                        text: btManager.scanning
                              ? "\u6b63\u5728\u626b\u63cf\u4e2d\u2026"
                              : "\u70b9\u51fb\u201c\u626b\u63cf\u65b0\u8bbe\u5907\u201d\u53d1\u73b0\u5468\u56f4\u8bbe\u5907"
                        color: "#999"
                        font.pixelSize: 13
                        anchors.horizontalCenter: parent.horizontalCenter
                        topPadding: 20
                        bottomPadding: 12
                    }
                }
            }

            // --- Servo Control ---
            Column {
                width: parent.width
                spacing: 10
                visible: btManager.connected

                Rectangle {
                    width: parent.width
                    height: 80
                    radius: 10
                    color: "white"
                    border.color: "#e0e0e0"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "\u63a7\u5236\u8235\u673a\u89d2\u5ea6: " + servoSlider.value + "\u00b0"
                            font.bold: true
                            color: "#333"
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

            Item { width: 1; height: 20 }
        }
    }
}

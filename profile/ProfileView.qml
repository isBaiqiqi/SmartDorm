import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Rectangle {
        anchors.fill: parent
        color: '#f5f5f5'
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: contentCol.implicitHeight + 20
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentCol
            width: parent.width
            spacing: 0

            // user info card
            Rectangle {
                width: parent.width
                height: userCard.height + 40
                color: 'white'

                Column {
                    id: userCard
                    width: parent.width - 32
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 28
                    spacing: 14

                    Rectangle {
                        width: 72
                        height: 72
                        radius: 36
                        color: '#c44d82'
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            anchors.centerIn: parent
                            text: '👤'
                            font.pixelSize: 32
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: '张三'
                        font.pixelSize: 20
                        font.bold: true
                        color: '#333'
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10

                        Text {
                            text: '学号: 20240001'
                            font.pixelSize: 13
                            color: '#888'
                        }

                        Rectangle {
                            radius: 10
                            color: '#f3e8f7'
                            implicitWidth: tagText.implicitWidth + 16
                            implicitHeight: 22

                            Text {
                                id: tagText
                                anchors.centerIn: parent
                                text: '寝室长'
                                font.pixelSize: 11
                                color: '#c44d82'
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 52
                        radius: 10
                        color: '#fafafa'
                        border.color: '#f0f0f0'

                        Row {
                            anchors.centerIn: parent
                            spacing: 32

                            Column {
                                spacing: 2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: '汤臣一品 404'
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: '#333'
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: '所在寝室'
                                    font.pixelSize: 11
                                    color: '#aaa'
                                }
                            }

                            Rectangle {
                                width: 1
                                height: 24
                                color: '#e8e8e8'
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                spacing: 2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: '4 人'
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: '#333'
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: '寝室人数'
                                    font.pixelSize: 11
                                    color: '#aaa'
                                }
                            }

                            Rectangle {
                                width: 1
                                height: 24
                                color: '#e8e8e8'
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                spacing: 2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: '2024-09'
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: '#333'
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: '入住时间'
                                    font.pixelSize: 11
                                    color: '#aaa'
                                }
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: 12 }

            // settings list
            Column {
                width: parent.width
                spacing: 0

                Repeater {
                    model: [
                        { icon: '👤', label: '个人信息' },
                        { icon: '🔐', label: '账号安全' },
                        { icon: '🔔', label: '消息通知' },
                        { icon: '🔒', label: '隐私设置' },
                        { icon: '💬', label: '帮助与反馈' },
                        { icon: 'ℹ️', label: '关于我们' }
                    ]

                    delegate: Rectangle {
                        width: parent.width
                        height: 52
                        color: itemMouse.pressed ? '#f8f8f8' : 'white'

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                leftMargin: 52
                            }
                            height: 0.5
                            color: '#f0f0f0'
                            visible: index < 5
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12

                            Text {
                                text: modelData.icon
                                font.pixelSize: 20
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: 28
                            }

                            Text {
                                text: modelData.label
                                font.pixelSize: 15
                                color: '#333'
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: '>'
                                font.pixelSize: 14
                                color: '#ccc'
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            onClicked: {
                                console.log('click:', modelData.label)
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: 12 }

            // logout button
            Rectangle {
                width: parent.width - 32
                height: 48
                radius: 24
                color: logoutMouse.pressed ? '#fce4ec' : 'white'
                border.color: '#ffcdd2'
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    anchors.centerIn: parent
                    text: '退出登录'
                    font.pixelSize: 15
                    color: '#e53935'
                }

                MouseArea {
                    id: logoutMouse
                    anchors.fill: parent
                    onClicked: {
                        console.log('logout')
                    }
                }
            }

            Item { width: 1; height: 24 }
        }
    }
}

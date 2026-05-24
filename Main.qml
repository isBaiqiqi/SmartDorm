// main.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "home"
import "message"
import "service"
import "profile"

ApplicationWindow {
    id: window
    visible: true
    width: 360
    height: 640
    title: "智慧寝室"

    StackLayout {
        id: mainLayout
        anchors.fill: parent
        currentIndex: floatingTabBar.currentIndex
        // 底部留出悬浮导航栏的空间
        anchors.bottomMargin: floatingTabBar.height + floatingTabBar.anchors.bottomMargin + 16

        HomeView {}
        ServiceView {}
        MessageView {}
        ProfileView {}
    }

    // --- 悬浮胶囊式底部导航栏 ---
    Item {
        id: floatingTabBar
        property int currentIndex: 0
        readonly property int tabCount: 4
        readonly property real capsuleWidth: Math.min(window.width - 32, 400)
        readonly property real tabWidth: (capsuleWidth - 8) / tabCount
        readonly property real highlightPadding: 6

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Qt.platform.os === "ios" ? 28 : 12
        }
        width: capsuleWidth
        height: 64

        // 胶囊背景
        Rectangle {
            id: capsuleBg
            anchors.fill: parent
            radius: height / 2
            color: "#fafafa"
            border { width: 0.5; color: "#e8e8e8" }
        }

        // 选中高亮背景块（平滑平移动画）
        Rectangle {
            id: highlight
            width: floatingTabBar.tabWidth - floatingTabBar.highlightPadding * 2
            height: parent.height - 12
            radius: (parent.height - 12) / 2
            color: "#f3e8f7"
            y: 6
            x: floatingTabBar.highlightPadding + floatingTabBar.currentIndex * floatingTabBar.tabWidth

            Behavior on x {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Tab 项
        Row {
            anchors {
                fill: parent
                leftMargin: 4
                rightMargin: 4
            }

            Repeater {
                model: [
                    { icon: "assets/icons/home.png",     label: "首页" },
                    { icon: "assets/icons/service.png",  label: "设备" },
                    { icon: "assets/icons/message.png",  label: "消息" },
                    { icon: "assets/icons/profile.png",  label: "我的" }
                ]

                delegate: Item {
                    width: floatingTabBar.tabWidth
                    height: parent.height

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: modelData.icon
                            sourceSize: Qt.size(22, 22)
                            opacity: index === floatingTabBar.currentIndex ? 1.0 : 0.45
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label
                            font.pixelSize: 11
                            font.weight: index === floatingTabBar.currentIndex ? Font.DemiBold : Font.Normal
                            color: index === floatingTabBar.currentIndex ? "#c44d82" : "#999999"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: floatingTabBar.currentIndex = index
                    }
                }
            }
        }
    }
}

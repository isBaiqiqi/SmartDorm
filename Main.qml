// main.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 假设这些目录和文件已经存在
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

    // --- 顶部标题栏 (根据需要取消注释) ---
    /*
    header: ToolBar {
        background: Rectangle { color: "#4a8ffc" }
        Label {
            text: ["首页", "服务", "消息", "我的"][tabBar.currentIndex]
            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 20
            font.bold: true
            color: "white"
        }
    }
    */

    StackLayout {
        id: mainLayout
        anchors.fill: parent
        currentIndex: tabBar.currentIndex

        HomeView {}
        ServiceView {}
        MessageView {}
        ProfileView {}
    }

    footer: TabBar {
        id: tabBar
        readonly property bool isIos: Qt.platform.os === "ios"

        // 1. 固定一个较大的高度（适配 iOS 和安卓的留白）
        // iOS 给 85, 安卓给 70（或者你喜欢的数值）
        implicitHeight: isIos ? 85 : 70

        background: Rectangle {
            color: "#ffffff"
            Rectangle { width: parent.width; height: 1; color: "#e0e0e0"; anchors.top: parent.top }
        }

        component MyTabButton: TabButton {
            property alias iconSource: img.source
            property alias tabText: txt.text

            // 1. 关键：将 topPadding 设小，bottomPadding 设大
            // 这样按钮的感应区域依然是整个高度，但内容被底部的 padding 挤到了上方
            topPadding: 10
            bottomPadding: window.footer.isIos ? 35 : 20

            contentItem: ColumnLayout {
                // 2. 这里不再需要 anchors.fill: parent，让它自然布局
                spacing: 4

                Image {
                    id: img
                    Layout.alignment: Qt.AlignHCenter
                    sourceSize: Qt.size(24, 24)
                    // 使用 parent.parent 指向 TabButton
                    opacity: parent.parent.checked ? 1.0 : 0.5
                }
                Text {
                    id: txt
                    Layout.alignment: Qt.AlignHCenter
                    text: tabText
                    font.pixelSize: 12
                    color: parent.parent.checked ? "#4a8ffc" : "#888888"
                }
            }

            // 3. 背景设为透明，但确保它占满空间，增加点击命中率
            background: Rectangle {
                color: "transparent"
                // 可以在这里加个显式的大小限制，确保点击区域完整
                implicitWidth: 60
                implicitHeight: parent.height
            }
        }

        // 按钮实例保持不变...
        MyTabButton { iconSource: "assets/icons/home.png"; tabText: "首页" }
        MyTabButton { iconSource: "assets/icons/service.png"; tabText: "服务" }
        MyTabButton { iconSource: "assets/icons/message.png"; tabText: "消息" }
        MyTabButton { iconSource: "assets/icons/profile.png"; tabText: "我的" }
    }
}

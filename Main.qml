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

    // --- 顶部标题栏 (可选) ---
    // header: ToolBar {
    //     Label {
    //         // 1. 设置内容
    //         text: ["智慧寝室", "服务", "消息", "我的"][tabBar.currentIndex]

    //         // 2. 居左显示
    //         anchors.left: parent.left        // 锚定到父容器的左边
    //         anchors.leftMargin: 15           // 设置左边距，防止贴死边缘
    //         anchors.verticalCenter: parent.verticalCenter // 垂直方向依然居中，保证美观

    //         // 3. 设置字体和大小
    //         font.pixelSize: 24               // 字号大小 (像素)
    //         font.bold: true                  // 加粗
    //         font.family: "Microsoft YaHei"   // 字体家族（如微软雅黑、PingFang SC等）
    //         color: "white"                 // 字体颜色
    //     }
    // }

    StackLayout {
        id: mainLayout
        anchors.fill: parent
        currentIndex: tabBar.currentIndex

        // 直接引用组件名称
        HomeView {}    // 对应 HomeView.qml
        ServiceView {}
        MessageView {}
        ProfileView {}
    }

    footer: TabBar {
        id: tabBar

        // 定义一个可复用的模板组件，减少重复代码
        component MyTabButton: TabButton {
            property alias iconSource: img.source
            property alias tabText: txt.text

            contentItem: ColumnLayout {
                spacing: 2
                Image {
                    id: img
                    Layout.alignment: Qt.AlignHCenter
                    sourceSize.width: 24  // 控制图标大小
                    sourceSize.height: 24
                    fillMode: Image.PreserveAspectFit
                    // 选中的时候改变图标透明度或颜色（如果是SVG）
                    opacity: parent.parent.checked ? 1.0 : 0.5
                }
                Text {
                    id: txt
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: 12
                    color: parent.parent.checked ? "#4a8ffc" : "#888888" // 选中变色
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        MyTabButton {
            iconSource: "assets/icons/home.png"
            tabText: "首页"
        }
        MyTabButton {
            iconSource: "assets/icons/service.png"
            tabText: "服务"
        }
        MyTabButton {
            iconSource: "assets/icons/message.png"
            tabText: "消息"
        }
        MyTabButton {
            iconSource: "assets/icons/profile.png"
            tabText: "我的"
        }
    }
}

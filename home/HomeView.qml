import QtQuick
import QtQuick.Controls


// 底座，只负责管理 StackView

Item {
    id: homeRoot

    StackView {
        id: homeStack
        anchors.fill: parent

        // 初始化页面
        initialItem: "HomePage.qml"
    }
}

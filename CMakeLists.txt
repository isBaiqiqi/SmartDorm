cmake_minimum_required(VERSION 3.16)

# 工程名
project(od_ble VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 1. 关键修改：添加 Bluetooth 模块
find_package(Qt6 REQUIRED COMPONENTS Quick Bluetooth)

qt_standard_project_setup(REQUIRES 6.7)

# 2. 你的项目目标名称是 appod_ble
qt_add_executable(appod_ble
    main.cpp
    bluetoothmanager.cpp
    bluetoothmanager.h
)

# --- iOS图标配置开始 ---
# 假设你的 Assets.xcassets 放在项目根目录下的 ios 文件夹内
set(APPLE_ASSETS "${CMAKE_CURRENT_SOURCE_DIR}/ios/Assets.xcassets")

# 将资源文件添加到目标，并标记为 RESOURCE 属性
target_sources(appod_ble PRIVATE ${APPLE_ASSETS})
set_source_files_properties(${APPLE_ASSETS} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
# --- iOS图标配置结束 ---

# 安卓图标
set_property(TARGET appod_ble PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
             ${CMAKE_CURRENT_SOURCE_DIR}/android)


         qt_add_qml_module(appod_ble
             URI od_ble
             VERSION 1.0
             QML_FILES
                 Main.qml
                 home/HomeView.qml
                 home/HomePage.qml
                 home/DevicePage.qml
                 message/MessageView.qml
                 profile/ProfileView.qml
                 service/ServiceView.qml
             RESOURCES
                 # 图片资源
                 assets/icons/home.png
                 assets/icons/service.png
                 assets/icons/message.png
                 assets/icons/profile.png
                 # 其他资源
                 ios/Info.plist
                 android/AndroidManifest.xml
                 android/build.gradle
                 android/res/values/libs.xml
                 android/res/xml/qtprovider_paths.xml
                 android/gradle/wrapper/gradle-wrapper.jar
                 android/gradle/wrapper/gradle-wrapper.properties
                 android/gradle.properties
                 android/gradlew
                 android/gradlew.bat
         )

# 3. 设置 iOS 捆绑包属性
set_target_properties(appod_ble PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.li.servodoor
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
    # 指定自定义 Info.plist 路径
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/ios/Info.plist"
    # 关键：告诉 Xcode 自动从 Assets 中寻找名为 "AppIcon" 的图标集
    ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
)

# 4. 关键修改：链接 Bluetooth 库
target_link_libraries(appod_ble
    PRIVATE Qt6::Quick Qt6::Bluetooth
)

if(IOS)
    # 让 Info.plist 里的版本号有值，并配置 Xcode 属性
    set_target_properties(appod_ble PROPERTIES
        XCODE_ATTRIBUTE_MARKETING_VERSION "${PROJECT_VERSION}"
        XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION "1"
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
        XCODE_ATTRIBUTE_INFOPLIST_KEY_UIRequiresFullScreen "YES"
        # 这一行确保资产包被正确处理
        XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
    )
endif()

include(GNUInstallDirs)
install(TARGETS appod_ble
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services

PanelWindow {
    id: root

    required property var screen

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top:  true
        left: true
        right: true
    }

    implicitHeight: root.screen ? root.screen.height : 800

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    visible: slidePanel.windowVisible

    property string currentPage: "output"
    property int tabDirection: 1

    readonly property var tabModel: [
        {
            key: "output",
            icon: "󰕾",
            label: "Output"
        },
        {
            key: "input",
            icon: "󰍬",
            label: "Input"
        },
        {
            key: "devices",
            icon: "󰓃",
            label: "Devices"
        }
    ]

    function setPage(key) {
        const keys = root.tabModel.map(tab => tab.key)
        const oldIndex = keys.indexOf(root.currentPage)
        const newIndex = keys.indexOf(key)
        if (newIndex === -1 || newIndex === oldIndex) return
        root.tabDirection = newIndex > oldIndex ? 1 : -1
        root.currentPage = key
    }

    function nextPage() {
        const keys = root.tabModel.map(tab => tab.key)
        const index = keys.indexOf(root.currentPage)
        if (index < keys.length - 1) root.setPage(keys[index + 1])
    }

    function previousPage() {
        const keys = root.tabModel.map(tab => tab.key)
        const index = keys.indexOf(root.currentPage)
        if (index > 0) root.setPage(keys[index - 1])
    }

    onVisibleChanged: {
        if (!visible) root.currentPage = "output"
    }

    mask: Region {
        x: card.x
        y: Theme.barHeight + 8
        width: card.width
        height: card.height
    }

    PopupSlide {
        id: slidePanel

        anchors.fill: parent
        edge: "top"
        open: Popups.volumeOpen && Popups.volumeScreen === root.screen
        onCloseRequested: Popups.volumeOpen = false

        Rectangle {
            id: card

            anchors {
                top: parent.top
                topMargin: Theme.barHeight + 8
            }

            x: Popups.volumeAnchorX - width / 2
            width: 380
            height: cardColumn.implicitHeight + 32
            radius: Theme.popupRadius
            color: Colors.surfaceContainer
            border.color: Colors.outlineVariant
            border.width: Theme.popupBorder
            clip: true

            Behavior on height {
                NumberAnimation {
                    duration: Theme.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                id: cardColumn

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: 16
                    leftMargin: 16
                    rightMargin: 16
                    bottomMargin: 16
                }

                spacing: 12

                // Tabs
                TabBar {
                    id: tabs
                    Layout.fillWidth: true
                    orientation: "horizontal"
                    model: root.tabModel
                    currentPage: root.currentPage
                    onPageChanged: (key) => root.setPage(key)
                }

                // Animated page content
                Item {
                    id: pageContainer
                    Layout.fillWidth: true
                    implicitHeight: {
                        if (root.currentPage === "output") return outputPage.implicitHeight
                        if (root.currentPage === "input") return inputPage.implicitHeight
                        if (root.currentPage === "devices") return devicesPage.implicitHeight
                        return 0
                    }

                    clip: true

                    // Output
                    ColumnLayout {
                        id: outputPage

                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }

                        spacing: 12
                        opacity: root.currentPage === "output" ? 1 : 0
                        enabled: root.currentPage === "output"
                        transform: Translate {
                            x: root.currentPage === "output" ? 0 : (root.tabDirection > 0 ? -32 : 32)

                            Behavior on x {
                                NumberAnimation {
                                    duration: Theme.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.animDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        // Volume control
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                width: 36
                                height: 36
                                radius: 18
                                color: VolumeService.muted
                                    ? Colors.errorContainer
                                    : (muteOutHov.containsMouse
                                        ? Colors.surfaceContainerHighest
                                        : Colors.surfaceContainerHigh)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: VolumeService.muted ? "󰝟" : "󰕾"
                                    color: VolumeService.muted ? Colors.on_ErrorContainer : Colors.primary
                                    font.pixelSize: 16
                                    font.family: Fonts.font
                                }

                                MouseArea {
                                    id: muteOutHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: VolumeService.toggleMute()
                                }
                            }

                            VolumeSlider {
                                Layout.fillWidth: true
                                value: VolumeService.volume
                                muted: VolumeService.muted
                                onMoved: (value) => {
                                    if (VolumeService.audio) VolumeService.audio.volume = value
                                }
                            }

                            Text {
                                text: Math.round(VolumeService.volume * 100) + "%"
                                color: Colors.on_Surface
                                font.pixelSize: 12
                                font.bold: true
                                font.family: Fonts.font
                                horizontalAlignment: Text.AlignRight
                                width: 36
                            }
                        }

                        // Current output device
                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            radius: 10
                            color: outputDeviceHov.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: "󰓃"
                                    color: Colors.primary
                                    font.pixelSize: 17
                                    font.family: Fonts.font
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: "Current output"
                                        color: Colors.on_SurfaceVariant
                                        font.pixelSize: 10
                                        font.family: Fonts.font
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: VolumeService.sink ? (VolumeService.sink.description || "Unknown") : "No output device"
                                        color: Colors.on_Surface
                                        font.pixelSize: 12
                                        font.bold: true
                                        font.family: Fonts.font
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Text {
                                    text: "󰄾"
                                    color: Colors.on_SurfaceVariant
                                    font.pixelSize: 14
                                    font.family: Fonts.font
                                }
                            }

                            MouseArea {
                                id: outputDeviceHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setPage("devices")
                            }
                        }
                    }

                    // Input
                    ColumnLayout {
                        id: inputPage

                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }

                        spacing: 12
                        opacity: root.currentPage === "input" ? 1 : 0
                        enabled: root.currentPage === "input"
                        transform: Translate {
                            x: root.currentPage === "input" ? 0 : (root.tabDirection > 0 ? -32 : 32)

                            Behavior on x {
                                NumberAnimation {
                                    duration: Theme.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.animDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                width: 36
                                height: 36
                                radius: 18

                                color: VolumeService.inputMuted
                                    ? Colors.errorContainer
                                    : (muteInHov.containsMouse
                                        ? Colors.surfaceContainerHighest
                                        : Colors.surfaceContainerHigh)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: VolumeService.inputMuted ? "󰍭" : "󰍬"
                                    color: VolumeService.inputMuted ? Colors.on_ErrorContainer : Colors.primary
                                    font.pixelSize: 16
                                    font.family: Fonts.font
                                }

                                MouseArea {
                                    id: muteInHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: VolumeService.toggleInputMute()
                                }
                            }

                            VolumeSlider {
                                Layout.fillWidth: true
                                value: VolumeService.inputVolume
                                muted: VolumeService.inputMuted
                                onMoved: (value) => {
                                    if (VolumeService.inputAudio) VolumeService.inputAudio.volume = value
                                }
                            }

                            Text {
                                text: Math.round(VolumeService.inputVolume * 100) + "%"
                                color: Colors.on_Surface
                                font.pixelSize: 12
                                font.bold: true
                                font.family: Fonts.font
                                horizontalAlignment: Text.AlignRight
                                width: 36
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            radius: 10
                            color: inputDeviceHov.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: "󰍬"
                                    color: Colors.primary
                                    font.pixelSize: 17
                                    font.family: Fonts.font
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: "Current input"
                                        color: Colors.on_SurfaceVariant
                                        font.pixelSize: 10
                                        font.family: Fonts.font
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: VolumeService.source ? (VolumeService.source.description || "Unknown") : "No input device"
                                        color: Colors.on_Surface
                                        font.pixelSize: 12
                                        font.bold: true
                                        font.family: Fonts.font
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Text {
                                    text: "󰄾"
                                    color: Colors.on_SurfaceVariant
                                    font.pixelSize: 14
                                    font.family: Fonts.font
                                }
                            }

                            MouseArea {
                                id: inputDeviceHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setPage("devices")
                            }
                        }
                    }

                    // Devices
                    ColumnLayout {
                        id: devicesPage

                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }

                        spacing: 8
                        opacity: root.currentPage === "devices" ? 1 : 0
                        enabled: root.currentPage === "devices"
                        transform: Translate {
                            x: root.currentPage === "devices" ? 0 : (root.tabDirection > 0 ? -32 : 32)
                            Behavior on x {
                                NumberAnimation {
                                    duration: Theme.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.animDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            text: "Output"
                            color: Colors.on_SurfaceVariant
                            font.pixelSize: 11
                            font.bold: true
                            font.family: Fonts.font
                            leftPadding: 4
                        }

                        Repeater {
                            model: Pipewire.nodes.values
                            delegate: DeviceRow {
                                required property var modelData
                                Layout.fillWidth: true
                                visible: modelData.audio !== null && !modelData.isStream && modelData.isSink
                                height: visible ? implicitHeight : 0
                                deviceName: modelData.description || modelData.name || "Unknown"
                                isDefault: VolumeService.sink && VolumeService.sink.id === modelData.id
                                icon: "󰓃"
                                onActivated: Pipewire.preferredDefaultAudioSink = modelData
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Colors.outlineVariant
                            opacity: 0.5
                        }

                        Text {
                            text: "Input"
                            color: Colors.on_SurfaceVariant
                            font.pixelSize: 11
                            font.bold: true
                            font.family: Fonts.font
                            leftPadding: 4
                        }

                        Repeater {
                            model: Pipewire.nodes.values
                            delegate: DeviceRow {
                                required property var modelData
                                Layout.fillWidth: true
                                visible: modelData.audio !== null && !modelData.isStream && !modelData.isSink
                                height: visible ? implicitHeight : 0
                                deviceName: modelData.description || modelData.name || "Unknown"
                                isDefault: VolumeService.source && VolumeService.source.id === modelData.id
                                icon: "󰍬"
                                onActivated: Pipewire.preferredDefaultAudioSource = modelData
                            }
                        }
                        Layout.bottomMargin: 4
                    }
                }
            }
        }
    }
}

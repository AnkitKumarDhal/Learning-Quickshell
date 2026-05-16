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

    property var screen

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top:   true
        right: true
    }

    implicitWidth:  380
    implicitHeight: root.screen ? root.screen.height : 800

    WlrLayershell.layer: WlrLayer.Overlay
    visible: slidePanel.windowVisible

    PopupSlide {
        id: slidePanel
        anchors.fill: parent
        edge: "top"
        open: Popups.volumeOpen
        onCloseRequested: Popups.volumeOpen = false
    }

    // ── Popup card ────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors {
            top:         parent.top
            right:       parent.right
            topMargin:   Theme.barHeight + 8
            rightMargin: Theme.barMargin
        }
        width:        360
        height:       cardCol.implicitHeight + 24
        radius:       Theme.popupRadius
        color:        Colors.surfaceContainer
        border.color: Colors.outlineVariant
        border.width: Theme.popupBorder
        clip:         true

        ColumnLayout {
            id: cardCol
            anchors {
                top:     parent.top
                left:    parent.left
                right:   parent.right
                margins: 16
            }
            spacing: 12

            // ── Tab bar ───────────────────────────────────────────────────────
            TabBar {
                id: tabs
                Layout.fillWidth: true
                orientation: "horizontal"

                model: [
                    { key: "output",  icon: "󰕾", label: "Output"  },
                    { key: "input",   icon: "󰍬", label: "Input"   },
                    { key: "devices", icon: "󰓃", label: "Devices" }
                ]

                currentPage: "output"
                onPageChanged: (key) => currentPage = key
            }

            // ── Output tab ────────────────────────────────────────────────────
            ColumnLayout {
                visible:          tabs.currentPage === "output"
                Layout.fillWidth: true
                spacing:          12

                // Volume row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // Mute button
                    Rectangle {
                        width:  36
                        height: 36
                        radius: 18
                        color:  VolumeService.muted
                                    ? Colors.errorContainer
                                    : (muteOutHov.containsMouse
                                        ? Qt.rgba(1,1,1,0.08)
                                        : Colors.surfaceContainerHighest)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: VolumeService.muted ? "󰝟" : "󰕾"
                            color: VolumeService.muted
                                       ? Colors.on_ErrorContainer
                                       : Colors.primary
                            font.pixelSize: 16
                            font.family:    Fonts.font
                        }

                        MouseArea {
                            id:           muteOutHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    VolumeService.toggleMute()
                        }
                    }

                    // Slider
                    VolumeSlider {
                        Layout.fillWidth: true
                        value:    VolumeService.volume
                        muted:    VolumeService.muted
                        onMoved:  (v) => {
                            if (VolumeService.audio)
                                VolumeService.audio.volume = v
                        }
                    }

                    // Percentage label
                    Text {
                        text:           Math.round(VolumeService.volume * 100) + "%"
                        color:          Colors.on_Surface
                        font.pixelSize: 12
                        font.bold:      true
                        font.family:    Fonts.font
                        horizontalAlignment: Text.AlignRight
                        width: 36
                    }
                }

                // Current output device — click to go to devices tab
                Rectangle {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    height:  44
                    radius:  10
                    color:   outDevHov.containsMouse
                                 ? Colors.surfaceContainerHighest
                                 : Colors.surfaceContainerHigh
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors { fill: parent; rightMargin: 12; leftMargin: 12 }
                        spacing: 8

                        Text {
                            text:           "󰓃"
                            color:          Colors.primary
                            font.pixelSize: 16
                            font.family:    Fonts.font
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing:          0

                            Text {
                                text:              "Output device"
                                color:             Colors.on_SurfaceVariant
                                font.pixelSize:    10
                                font.family:       Fonts.font
                                Layout.fillWidth:  true
                            }

                            Text {
                                text:             VolumeService.sink
                                                      ? (VolumeService.sink.description || "Unknown")
                                                      : "None"
                                color:            Colors.on_Surface
                                font.pixelSize:   12
                                font.bold:        true
                                font.family:      Fonts.font
                                elide:            Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            text:           "󰄾"
                            color:          Colors.on_SurfaceVariant
                            font.pixelSize: 14
                            font.family:    Fonts.font
                        }
                    }

                    MouseArea {
                        id:           outDevHov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    tabs.currentPage = "devices"
                    }
                }
            }

            // ── Input tab ─────────────────────────────────────────────────────
            ColumnLayout {
                visible:          tabs.currentPage === "input"
                Layout.fillWidth: true
                spacing:          12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // Mute button
                    Rectangle {
                        width:  36
                        height: 36
                        radius: 18
                        color:  VolumeService.inputMuted
                                    ? Colors.errorContainer
                                    : (muteInHov.containsMouse
                                        ? Qt.rgba(1,1,1,0.08)
                                        : Colors.surfaceContainerHighest)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text:  VolumeService.inputMuted ? "󰍭" : "󰍬"
                            color: VolumeService.inputMuted
                                       ? Colors.on_ErrorContainer
                                       : Colors.primary
                            font.pixelSize: 16
                            font.family:    Fonts.font
                        }

                        MouseArea {
                            id:           muteInHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    VolumeService.toggleInputMute()
                        }
                    }

                    VolumeSlider {
                        Layout.fillWidth: true
                        value:   VolumeService.inputVolume
                        muted:   VolumeService.inputMuted
                        onMoved: (v) => {
                            if (VolumeService.inputAudio)
                                VolumeService.inputAudio.volume = v
                        }
                    }

                    Text {
                        text:           Math.round(VolumeService.inputVolume * 100) + "%"
                        color:          Colors.on_Surface
                        font.pixelSize: 12
                        font.bold:      true
                        font.family:    Fonts.font
                        horizontalAlignment: Text.AlignRight
                        width: 36
                    }
                }

                // Current input device
                Rectangle {
                    Layout.fillWidth: true
                    height:  44
                    radius:  10
                    color:   inDevHov.containsMouse
                                 ? Colors.surfaceContainerHighest
                                 : Colors.surfaceContainerHigh
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors { fill: parent; margins: 12 }
                        spacing: 8

                        Text {
                            text:           "󰍬"
                            color:          Colors.primary
                            font.pixelSize: 16
                            font.family:    Fonts.font
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text:           "Input device"
                                color:          Colors.on_SurfaceVariant
                                font.pixelSize: 10
                                font.family:    Fonts.font
                            }

                            Text {
                                text: VolumeService.source
                                          ? (VolumeService.source.description || "Unknown")
                                          : "None"
                                color:          Colors.on_Surface
                                font.pixelSize: 12
                                font.bold:      true
                                font.family:    Fonts.font
                                elide:          Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            text:           "󰄾"
                            color:          Colors.on_SurfaceVariant
                            font.pixelSize: 14
                            font.family:    Fonts.font
                        }
                    }

                    MouseArea {
                        id:           inDevHov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    tabs.currentPage = "devices"
                    }
                }
            }

            // ── Devices tab ───────────────────────────────────────────────────
            ColumnLayout {
                visible:          tabs.currentPage === "devices"
                Layout.fillWidth: true
                spacing:          8

                // Output devices section
                Text {
                    text:           "Output"
                    color:          Colors.on_SurfaceVariant
                    font.pixelSize: 11
                    font.bold:      true
                    font.family:    Fonts.font
                    leftPadding:    4
                }

                Repeater {
                    model: Pipewire.nodes.values.filter(n =>
                        n.isStream === false &&
                        n.audio !== null &&
                        n.type === PwNodeType.Sink
                    )

                    delegate: DeviceRow {
                        required property var modelData
                        Layout.fillWidth: true

                        deviceName:  modelData.description || modelData.name || "Unknown"
                        isDefault:   VolumeService.sink && VolumeService.sink.id === modelData.id
                        icon:        "󰓃"

                        onActivated: {
                            Pipewire.preferredDefaultAudioSink = modelData
                        }
                    }
                }

                // Divider between output and input
                Rectangle {
                    Layout.fillWidth: true
                    height:  1
                    color:   Colors.outlineVariant
                    opacity: 0.5
                }

                // Input devices section
                Text {
                    text:           "Input"
                    color:          Colors.on_SurfaceVariant
                    font.pixelSize: 11
                    font.bold:      true
                    font.family:    Fonts.font
                    leftPadding:    4
                }

                Repeater {
                    model: Pipewire.nodes.values.filter(n =>
                        n.isStream === false &&
                        n.audio !== null &&
                        n.type === PwNodeType.Source
                    )

                    delegate: DeviceRow {
                        required property var modelData
                        Layout.fillWidth: true

                        deviceName: modelData.description || modelData.name || "Unknown"
                        isDefault:  VolumeService.source && VolumeService.source.id === modelData.id
                        icon:       "󰍬"

                        onActivated: {
                            Pipewire.preferredDefaultAudioSource = modelData
                        }
                    }
                }

                Layout.bottomMargin: 4
            }
        }
    }
}

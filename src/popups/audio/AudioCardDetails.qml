import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

import qs.src.theme
import qs.src.services
import qs.src.popups

Item {
    id: root

    required property string mode
    readonly property bool isOutput: root.mode === "output"
    readonly property bool isInput: root.mode === "input"

    implicitHeight: visible ? detailsColumn.implicitHeight : 0
    clip: true

    function deviceName() {
        if (root.isOutput) {
            if (VolumeService.sink)
                return VolumeService.sink.description || VolumeService.sink.name || "Unknown"
            return Pipewire.ready ? "No output device" : "Waiting for PipeWire"
        }
        if (VolumeService.source)
            return VolumeService.source.description || VolumeService.source.name || "Unknown"
        return Pipewire.ready ? "No input device" : "Waiting for PipeWire"
    }

    function selectOutput(node) {
        Pipewire.preferredDefaultAudioSink = node
    }

    function selectInput(node) {
        Pipewire.preferredDefaultAudioSource = node
    }

    ColumnLayout {
        id: detailsColumn

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: 8
        opacity: root.visible ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }

        // Master volume
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                readonly property bool muted: root.isOutput ? VolumeService.muted : VolumeService.inputMuted
                color: muted ? Colors.errorContainer : Colors.surfaceContainerHighest

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (root.isOutput) return VolumeService.muted ? "󰝟" : "󰕾"
                        return VolumeService.inputMuted ? "󰍭" : "󰍬"
                    }
                    color: parent.muted ? Colors.on_ErrorContainer : Colors.primary
                    font.family: Fonts.font
                    font.pixelSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.isOutput) VolumeService.toggleMute()
                        else VolumeService.toggleInputMute()
                    }
                }
            }

            VolumeSlider {
                Layout.fillWidth: true
                value: root.isOutput ? VolumeService.volume : VolumeService.inputVolume
                muted: root.isOutput ? VolumeService.muted : VolumeService.inputMuted
                onMoved: (value) => {
                    if (root.isOutput) {
                        if (VolumeService.audio) VolumeService.audio.volume = value
                    } else {
                        if (VolumeService.inputAudio) VolumeService.inputAudio.volume = value
                    }
                }
            }

            Text {
                text: root.isOutput ? Math.round(VolumeService.volume * 100) + "%" : Math.round(VolumeService.inputVolume * 100) + "%"
                color: Colors.on_Surface
                font.family: Fonts.font
                font.pixelSize: 12
                font.bold: true
                width: 38
                horizontalAlignment: Text.AlignRight
            }
        }

        // Device selector
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 46
            radius: 10
            color: selectorHov.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
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
                    text: root.isOutput ? "󰓃" : "󰍬"
                    color: Colors.primary
                    font.family: Fonts.font
                    font.pixelSize: 15
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: root.isOutput ? "Output device" : "Input device"
                        color: Colors.on_SurfaceVariant
                        font.family: Fonts.font
                        font.pixelSize: 9
                    }

                    Text {
                        text: root.deviceName()
                        color: Colors.on_Surface
                        font.family: Fonts.font
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Text {
                    text: selector.expanded ? "󰅀" : "󰅂"
                    color: Colors.on_SurfaceVariant
                    font.family: Fonts.font
                    font.pixelSize: 14
                }
            }

            MouseArea {
                id: selectorHov
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: selector.expanded = !selector.expanded
            }
        }

        ColumnLayout {
            id: selector

            property bool expanded: false
            visible: expanded
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: Pipewire.nodes.values
                delegate: AudioDeviceOption {
                    required property var modelData
                    Layout.fillWidth: true
                    visible: modelData.audio !== null && !modelData.isStream && (root.isOutput ? modelData.isSink : !modelData.isSink)
                    deviceName: modelData.description || modelData.name || "Unknown"
                    isDefault: root.isOutput ? (VolumeService.sink && VolumeService.sink.id === modelData.id) : (VolumeService.source && VolumeService.source.id === modelData.id)
                    icon: root.isOutput ? "󰓃" : "󰍬"
                    onSelected: {
                        if (root.isOutput) root.selectOutput(modelData)
                        else root.selectInput(modelData)
                        selector.expanded = false
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts

import qs.src.theme
import qs.src.services

Item {
    id: root

    required property string mode
    property bool expanded: false
    signal clicked()

    implicitHeight: 84

    readonly property bool isOutput: root.mode === "output"
    readonly property bool available: root.isOutput ? VolumeService.sink !== null : VolumeService.source !== null
    readonly property real volume: root.isOutput ? VolumeService.volume : VolumeService.inputVolume
    readonly property bool muted: root.isOutput ? VolumeService.muted : VolumeService.inputMuted
    readonly property string deviceName: {
        if (root.isOutput) {
            if (VolumeService.sink)
                return VolumeService.sink.description || VolumeService.sink.name || "Unknown"
            if (!Pipewire.ready)
                return "Waiting for Pipewire"
            return "No output device"
        }

        if (VolumeService.source)
            return VolumeService.source.description || VolumeService.source.name || "Unknown"
        if (!Pipewire.ready)
            return "Waiting for pipewire"

        return "No input device"
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: root.expanded ? Colors.primaryContainer : (cardHov.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh)
        border.width: root.expanded ? 1 : 0
        border.color: Colors.primary
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
        Behavior on border.width {
            NumberAnimation {
                duration: 150
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.isOutput ? "󰕾" : "󰍬"
                    color: root.available ? Colors.primary : Colors.outline
                    font.family: Fonts.font
                    font.pixelSize: 16
                }
                Text {
                    text: root.isOutput ? "Output" : "Input"
                    color: Colors.on_Surface
                    font.family: Fonts.font
                    font.pixelSize: 11
                    font.bold: true
                    Layout.fillWidth: true
                }
                Text {
                    text: root.available ? Math.round(root.volume * 100) + "%" : "-"
                    color: root.muted ? Colors.error : Colors.on_SurfaceVariant
                    font.family: Fonts.font
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            Text {
                text: root.deviceName
                color: Colors.on_SurfaceVariant
                font.family: Fonts.font
                font.pixelSize: 10
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 4
                radius: 2
                color: Colors.surfaceContainerHighest

                Rectangle {
                    width: root.available ? parent.width * root.volume : 0
                    height: parent.height
                    radius: parent.radius
                    color: root.muted ? Colors.error : Colors.primary
                    Behavior on width {
                        NumberAnimation {
                            duration: 100
                        }
                    }
                }
            }
        }

        MouseArea {
            id: cardHov
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}

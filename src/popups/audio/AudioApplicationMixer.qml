import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

import qs.src.theme

ColumnLayout {
    id: root

    property string mode: "output"
    readonly property bool inputMode: root.mode === "input"
    readonly property var streams: ScriptModel {
            values: [...Pipewire.nodes.values].filter(node => node.audio !== null && node.isStream && (root.inputMode ? !node.isSink : node.isSink))
    }

    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        Text {
            text: root.inputMode ? "Recording applications" : "Applications"
            color: Colors.on_SurfaceVariant
            font.family: Fonts.font
            font.pixelSize: 10
            font.bold: true
            Layout.fillWidth: true
        }

        Text {
            text: root.streams.values.length
            color: Colors.outline
            font.family: Fonts.font
            font.pixelSize: 9
            font.bold: true
        }
    }

    Repeater {
        model: root.streams
        delegate: AudioApplicationRow {
            required property var modelData
            Layout.fillWidth: true
            node: modelData
        }
    }

    Item {
        visible: root.streams.values.length === 0
        Layout.fillWidth: true
        implicitHeight: 54

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Colors.surfaceContainerHigh
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: root.inputMode ? "󰍭" : "󰕾"
                    color: Colors.outline
                    font.family: Fonts.font
                    font.pixelSize: 16
                }

                Text {
                    text: root.inputMode ? "No recording applications" : "No active applications"
                    color: Colors.on_SurfaceVariant
                    font.family: Fonts.font
                    font.pixelSize: 10
                    Layout.fillWidth: true
                }
            }
        }
    }
}

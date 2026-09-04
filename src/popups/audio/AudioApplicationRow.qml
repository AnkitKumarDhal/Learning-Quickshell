import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets

import qs.src.components
import qs.src.theme
import qs.src.popups

Item {
    id: root

    required property var node
    implicitHeight: 64

    PwObjectTracker {
        objects: root.node ? [root.node] : []
    }

    readonly property bool available: root.node !== null && root.node.ready && root.node.audio !== null
    readonly property string applicationName: {
        const properties = root.node?.properties
        if (properties?.["application.name"]) return properties["application.name"]
        return root.node?.description || root.node?.name || "Unknown application"
    }

    readonly property string mediaName: {
        const properties = root.node?.properties
        if (properties?.["media.name"]) return properties["media.name"]
        if (properties?.["media.title"]) return properties["media.title"]
        return ""
    }

    readonly property string applicationIcon: {
        const properties = root.node?.properties
        return properties?.["application.icon-name"] || "application-x-executable"
    }

    readonly property real volume: root.available ? root.node.audio.volume : 0.0
    readonly property bool muted: root.available ? root.node.audio.muted : false

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: rowHov.containsMouse ? Colors.surfaceContainerHighest : Colors.surfaceContainerHigh
        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
                topMargin: 6
                bottomMargin: 6
            }
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 17
                color: Colors.surfaceContainerHighest

                IconImage {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    asynchronous: true
                    source: Quickshell.iconPath(root.applicationIcon, "application-x-executable")
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: root.applicationName
                        color: Colors.on_Surface
                        font.family: Fonts.font
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: Math.round(root.volume * 100) + "%"
                        color: root.muted ? Colors.error : Colors.on_SurfaceVariant
                        font.family: Fonts.font
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                Text {
                    visible: root.mediaName.length > 0
                    text: root.mediaName
                    color: Colors.outline
                    font.family: Fonts.font
                    font.pixelSize: 9
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                VolumeSlider {
                    Layout.fillWidth: true
                    implicitHeight: 20
                    value: root.volume
                    muted: root.muted
                    onMoved: (value) => {
                        if (root.available) root.node.audio.volume = value
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: root.muted ? Colors.errorContainer : Colors.surfaceContainerHighest

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.muted ? "󰝟" : "󰕾"
                    color: root.muted ? Colors.on_ErrorContainer : Colors.primary
                    font.family: Fonts.font
                    font.pixelSize: 14
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.available) root.node.audio.muted = !root.node.audio.muted
                    }
                }
            }
        }

        MouseArea {
            id: rowHov
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }
}

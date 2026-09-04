import QtQuick
import QtQuick.Layouts

import qs.src.theme

Item {
    id: root

    required property string deviceName
    required property bool isDefault
    required property string icon
    signal selected()
    implicitHeight: 48

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: rowHov.containsMouse
            ? Colors.surfaceContainerHighest
            : (root.isDefault
                ? Colors.primaryContainer
                : Colors.surfaceContainerHigh)

        border.width: root.isDefault ? 1 : 0
        border.color: Colors.primary

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        Behavior on border.width {
            NumberAnimation {
                duration: 120
            }
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 14
                color: root.isDefault ? Colors.primary : Colors.surfaceContainerHighest

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    color: root.isDefault ? Colors.on_Primary : Colors.on_SurfaceVariant
                    font.family: Fonts.font
                    font.pixelSize: 14
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: root.deviceName
                    color: root.isDefault ? Colors.on_Surface : Colors.on_SurfaceVariant
                    font.family: Fonts.font
                    font.pixelSize: 11
                    font.bold: root.isDefault
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    visible: root.isDefault
                    text: "Default device"
                    color: Colors.on_SurfaceVariant
                    font.family: Fonts.font
                    font.pixelSize: 8
                    Layout.fillWidth: true
                }
            }

            Text {
                visible: root.isDefault
                text: "󰄵"
                color: Colors.primary
                font.family: Fonts.font
                font.pixelSize: 13
            }
        }

        MouseArea {
            id: rowHov
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!root.isDefault) root.selected()
            }
        }
    }
}

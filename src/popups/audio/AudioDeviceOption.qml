import QtQuick
import QtQuick.Layouts

import qs.src.theme

Item {
    id: root

    required property string deviceName
    required property bool isDefault
    required property string icon
    signal selected()
    implicitHeight: 44

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: rowHov.containsMouse
            ? Colors.surfaceContainerHighest
            : (root.isDefault
                ? Qt.rgba(
                    Colors.primaryContainer.r,
                    Colors.primaryContainer.g,
                    Colors.primaryContainer.b,
                    0.35
                )
                : "transparent")

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
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Text {
                text: root.icon
                color: root.isDefault ? Colors.primary : Colors.on_SurfaceVariant
                font.family: Fonts.font
                font.pixelSize: 15
            }

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
                text: "󰄵"
                color: Colors.primary
                font.family: Fonts.font
                font.pixelSize: 12
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

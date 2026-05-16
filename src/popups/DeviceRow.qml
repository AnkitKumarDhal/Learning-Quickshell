import QtQuick
import QtQuick.Layouts
import qs.src.theme

// Single device row for the Devices tab
// Shows device name, default indicator chip, and sets default on click

Item {
    id: root

    property string deviceName: ""
    property bool   isDefault:  false
    property string icon:       "󰓃"

    signal activated()

    implicitHeight: 44

    Rectangle {
        anchors.fill: parent
        radius:       10
        color:        rowHov.containsMouse
                          ? Colors.surfaceContainerHighest
                          : (root.isDefault
                              ? Qt.rgba(
                                    Colors.primaryContainer.r,
                                    Colors.primaryContainer.g,
                                    Colors.primaryContainer.b, 0.3)
                              : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors { fill: parent; margins: 12 }
            spacing: 10

            // Device icon
            Text {
                text:           root.icon
                color:          root.isDefault ? Colors.primary : Colors.on_SurfaceVariant
                font.pixelSize: 16
                font.family:    Fonts.font
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            // Device name
            Text {
                text:           root.deviceName
                color:          root.isDefault ? Colors.on_Surface : Colors.on_SurfaceVariant
                font.pixelSize: 12
                font.bold:      root.isDefault
                font.family:    Fonts.font
                elide:          Text.ElideRight
                Layout.fillWidth: true
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            // Default chip — filled pill with checkmark
            Rectangle {
                visible: root.isDefault
                width:   chipRow.implicitWidth + 16
                height:  22
                radius:  11
                color:   Colors.primary

                Row {
                    id:       chipRow
                    anchors.centerIn: parent
                    spacing:  4

                    Text {
                        text:           "󰄵"
                        color:          Colors.on_Primary
                        font.pixelSize: 10
                        font.family:    Fonts.font
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text:           "Default"
                        color:          Colors.on_Primary
                        font.pixelSize: 10
                        font.bold:      true
                        font.family:    Fonts.font
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        MouseArea {
            id:           rowHov
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            onClicked:    if (!root.isDefault) root.activated()
        }
    }
}

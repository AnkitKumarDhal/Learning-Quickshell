import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../settings"

Rectangle {
    id: notifButton

    property int notifCount: notifService.notifications.length

    implicitWidth: layout.implicitWidth + 32
    implicitHeight: 30
    radius: 15
    color: notifService.panelVisible ? Colors.primaryContainer : Colors.background

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: "󰂚"
            color: notifService.panelVisible ? Colors.on_PrimaryContainer : Colors.primary
            font.pointSize: 11
            font.family: Fonts.font
        }

        Text {
            visible: notifButton.notifCount > 0
            text: notifButton.notifCount
            color: notifService.panelVisible ? Colors.on_PrimaryContainer : Colors.primary
            font.pointSize: 11
            font.bold: true
            font.family: Fonts.font
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            notifService.panelVisible = !notifService.panelVisible
        }
    }
}

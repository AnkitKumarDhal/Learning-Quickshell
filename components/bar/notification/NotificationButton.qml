import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../settings"
import "../../../services"

Rectangle {
    id: notifButton

    property int notifCount: NotificationService.notifications.length

    implicitWidth: layout.implicitWidth + 32
    implicitHeight: 30
    radius: 15
    color: NotificationService.panelVisible ? Colors.primaryContainer : Colors.background

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: "󰂚"
            color: NotificationService.panelVisible ? Colors.on_PrimaryContainer : Colors.primary
            font.pointSize: 11
            font.family: Fonts.font
        }

        Text {
            visible: notifButton.notifCount > 0
            text: notifButton.notifCount
            color: NotificationService.panelVisible ? Colors.on_PrimaryContainer : Colors.primary
            font.pointSize: 11
            font.bold: true
            font.family: Fonts.font
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            NotificationService.panelVisible = !NotificationService.panelVisible
        }
    }
}

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
    color: Colors.background
    border.color: Colors.primary
    border.width: NotificationService.panelVisible ? 1 : 0

    Behavior on border.width { NumberAnimation { duration: 150 } }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: "󰂚"
            color: Colors.primary
            font.pointSize: 11
            font.family: Fonts.font
        }

        Text {
            visible: notifButton.notifCount > 0
            text: notifButton.notifCount
            color: Colors.primary
            font.pointSize: 11
            font.bold: true
            font.family: Fonts.font
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: NotificationService.panelVisible = !NotificationService.panelVisible
    }
}

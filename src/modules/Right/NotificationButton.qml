import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services

PillBase {
    id: root

    hoverExpand: true

    // Highlight border when panel is open
    border.color: Colors.primary
    border.width: Popups.notificationsOpen ? 1 : 0
    Behavior on border.width { NumberAnimation { duration: 150 } }

    Row {
        spacing: 8

        Text {
            text: "󰂚"
            color: Colors.primary
            font.pointSize: 11
            font.family: Fonts.font
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            visible: NotificationService.notifications.length > 0
            text:    NotificationService.notifications.length
            color:   Colors.primary
            font.pointSize: 11
            font.bold: true
            font.family: Fonts.font
            verticalAlignment: Text.AlignVCenter
        }
    }

    onClicked: Popups.notificationsOpen = !Popups.notificationsOpen
}

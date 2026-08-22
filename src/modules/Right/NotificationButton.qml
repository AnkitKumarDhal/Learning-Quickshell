import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services

PillBase {
    id: root

    required property var screen

    hoverExpand: true

    border.color: Colors.primary
    border.width: Popups.notificationsOpen || NotificationService.notificationsSuppressed ? 1 : 0

    Behavior on border.width {
        NumberAnimation {
            duration: 150
        }
    }

    Row {
        spacing: 8

        Text {
            text: NotificationService.notificationsSuppressed ? "󰂛" : "󰂚"
            color: Colors.primary

            font.pointSize: 11
            font.family: Fonts.font

            verticalAlignment: Text.AlignVCenter
        }

        Text {
            visible: NotificationService.notificationCount > 0
            text: NotificationService.notificationCount

            color: Colors.primary

            font.pointSize: 11
            font.bold: true
            font.family: Fonts.fontM

            verticalAlignment: Text.AlignVCenter
        }
    }

    onClicked: {
        NotificationService.panelScreen = root.screen
        Popups.notificationsOpen = !Popups.notificationsOpen
    }

    onRightClicked:
        NotificationService.toggleSuppressed()
}

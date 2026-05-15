import "../../settings"
import "../popups"
import QtQuick
import QtQuick.Layouts
import Quickshell
import "battery"
import "clock"
import "notification"
import "system"
import "window"
import "workspaces"
import "volume"
import "tray"
import "media"

PanelWindow {
    id: topBar

    color: "transparent"
    implicitHeight: 38

    anchors {
        top: true
        left: true
        right: true
    }

    SystemPopup { id: sysPopup }

    Item {
        anchors.fill: parent
        anchors.margins: 8

        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Window {}
            Clock {}
        }

        RowLayout {
            anchors.centerIn: parent
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Workspaces {}
            Media {}
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Battery {}
            Cpu { popup: sysPopup }
            Memory { popup: sysPopup }
            Volume {}
            Tray {}
            NotificationButton {}
        }
    }
}

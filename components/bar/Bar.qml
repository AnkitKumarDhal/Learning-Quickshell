import "../../settings"
import QtQuick
import QtQuick.Layouts
import Quickshell
import "clock"
import "window"
import "workspaces"
import "system"

PanelWindow {
    id: topBar

    color: "transparent"
    implicitHeight: 38

    anchors {
        top: true
        left: true
        right: true
    }

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
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Cpu{}
            Memory{}
        }
    }
}

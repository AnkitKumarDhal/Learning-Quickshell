import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../settings"
import "clock"
import "window"

PanelWindow {
    id: topBar

    anchors {
        top: true
        left: true
        right: true
    }

    color: "transparent"
    implicitHeight: 38

    Item {
        anchors.fill: parent
        anchors.margins: 8

        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Window {}
            Clock{}
        }
    }
}

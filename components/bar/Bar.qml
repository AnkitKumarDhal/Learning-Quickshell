import QtQuick
import Quickshell
import "../../settings"
import "clock"

PanelWindow {
    id: topBar

    anchors {
        top: true
        left: true
        right: true
    }

    // exclusionMode: ExclusionMode.Normal
    color: "transparent"
    implicitHeight: 38

    Item {
        anchors.fill: parent
        anchors.margins: 8

        Clock {
            anchors.left: parent.left
        }
    }
}

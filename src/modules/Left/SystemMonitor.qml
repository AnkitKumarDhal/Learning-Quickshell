import QtQuick
import Quickshell
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services
import qs.src.services.system

PillBase {
    id: root

    border.color: Colors.primary
    border.width: Popups.systemOpen ? 1 : 0
    Behavior on border.width { NumberAnimation { duration: 150 } }

    required property var screen

    hoverExpand: false

    property real cpuUsage: SystemStats.cpuUsage * 100
    property real memUsedGb: SystemStats.memUsedGb

    Row {
        spacing: 6

        Text {
            text:           " " + Math.round(root.cpuUsage) + "%"
            color:          Colors.primary
            font.pointSize: 11
            font.bold:      true
            font.family:    Fonts.fontM
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            width:          1
            height:         14
            radius:         0.5
            color:          Colors.outlineVariant
            opacity:        0.8
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text:           " " + root.memUsedGb.toFixed(1) + "GB"
            color:          Colors.primary
            font.pointSize: 11
            font.bold:      true
            font.family:    Fonts.fontM
            verticalAlignment: Text.AlignVCenter
        }
    }

    onClicked: {
        Popups.systemScreen = root.screen
        Popups.systemAnchorX = Theme.barMargin + root.x + root.width / 2
        Popups.systemOpen = !Popups.systemOpen
    }

    onRightClicked: {
        Popups.systemScreen = root.screen
        Popups.systemAnchorX = Theme.barMargin + root.x + root.width / 2
        Popups.systemOpen = !Popups.systemOpen
    }
}

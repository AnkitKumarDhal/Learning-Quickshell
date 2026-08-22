import QtQuick
import Quickshell
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services
import qs.src.services.system

PillBase {
    id: root

    required property var screen

    hoverExpand: false

    property real cpuUsage: SystemStats.cpuUsage * 100
    property real memUsage: SystemStats.memUsage * 100

    Row {
        spacing: 6

        Text {
            text:           " " + Math.round(root.cpuUsage) + "%"
            color:          Colors.primary
            font.pointSize: 10.5
            font.bold:      true
            font.family:    Fonts.font
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            text:           " " + Math.round(root.memUsage) + "%"
            color:          Colors.primary
            font.pointSize: 10.5
            font.bold:      true
            font.family:    Fonts.font
            verticalAlignment: Text.AlignVCenter
        }
    }

    onClicked: {
        Popups.systemScreen = root.screen
        Popups.systemOpen = !Popups.systemOpen
    }

    onRightClicked: {
        Popups.systemScreen = root.screen
        Popups.systemOpen = !Popups.systemOpen
    }
}

import QtQuick
import Quickshell
import Quickshell.Io
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services
import qs.src.services.system

PillBase {
    id: root

    hoverExpand: true

    property real cpuUsage: SystemStats.cpuUsage * 100
    property real memUsed:  SystemStats.memUsedGb
    property real memTotal: SystemStats.memTotalGb

    Row {
        spacing: 8

        Text {
            text:           " " + Math.round(root.cpuUsage) + "%"
            color:          Colors.primary
            font.pointSize: 11
            font.bold:      true
            font.family:    Fonts.fontM
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            width:  1
            height: 14
            color:  Colors.outline
            opacity: 0.5
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text:           " " + root.memUsed.toFixed(1) + "G"
            color:          Colors.primary
            font.pointSize: 11
            font.bold:      true
            font.family:    Fonts.fontM
            verticalAlignment: Text.AlignVCenter
        }
    }

    onClicked:      Popups.systemOpen = !Popups.systemOpen
    onRightClicked: Popups.systemOpen = !Popups.systemOpen
}

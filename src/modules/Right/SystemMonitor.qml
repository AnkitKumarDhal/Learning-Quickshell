import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.src.theme
import qs.src.state

PillBase {
    id: root

    hoverExpand: true

    // SystemMonitor.qml — bind directly to cached SystemStats properties
    property real cpuUsage: SystemStats.cpuUsage * 100
    property real memUsed:  SystemStats.memUsedGb
    property real memTotal: SystemStats.memTotalGb

    // ── Display ───────────────────────────────────────────────────────────────
    Row {
        spacing: 8

        Text {
            text:           "CPU " + Math.round(root.cpuUsage) + "%"
            color:          Colors.primary
            font.pointSize: 11
            font.bold:      true
            font.family:    Fonts.font
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
            text:           "MEM " + root.memUsed.toFixed(1) + "G"
            color:          Colors.primary
            font.pointSize: 11
            font.bold:      true
            font.family:    Fonts.font
            verticalAlignment: Text.AlignVCenter
        }
    }

    onClicked:      Popups.systemOpen = !Popups.systemOpen
    onRightClicked: Popups.systemOpen = !Popups.systemOpen
}

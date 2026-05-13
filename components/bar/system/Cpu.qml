import QtQuick
import Quickshell
import Quickshell.Io
import "../../../settings"

Rectangle {
    id: cpuPill
    implicitWidth: cpuText.implicitWidth + 32
    implicitHeight: 30
    radius: 15
    color: Colors.background

    property real cpuUsage: 0.0
    property var _prevIdle: 0
    property var _prevTotal: 0

    Process {
        id: cpuProc
        command: ["cat", "/proc/stat"]
        running: false

        stdout: SplitParser {
            onRead: function(line) {
                if (!line.startsWith("cpu ")) return

                const parts = line.trim().split(/\s+/)
                const user    = parseInt(parts[1])
                const nice    = parseInt(parts[2])
                const system  = parseInt(parts[3])
                const idle    = parseInt(parts[4])
                const iowait  = parseInt(parts[5])
                const irq     = parseInt(parts[6])
                const softirq = parseInt(parts[7])

                const totalIdle  = idle + iowait
                const totalBusy  = user + nice + system + irq + softirq
                const total      = totalIdle + totalBusy

                const diffIdle  = totalIdle - cpuPill._prevIdle
                const diffTotal = total     - cpuPill._prevTotal

                if (diffTotal > 0)
                    cpuPill.cpuUsage = (1.0 - diffIdle / diffTotal) * 100.0

                cpuPill._prevIdle  = totalIdle
                cpuPill._prevTotal = total
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: cpuProc.running = true
    }

    Text {
        id: cpuText
        anchors.centerIn: parent
        text: "CPU: " + Math.round(cpuPill.cpuUsage) + "%"
        color: Colors.primary
        font.pointSize: 11
        font.bold: true
        font.family: Fonts.font
    }
}

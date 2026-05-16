import QtQuick
import Quickshell
import Quickshell.Io
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services

PillBase {
    id: root

    hoverExpand: true

    property real cpuUsage: 0.0
    property real memUsed:  0.0
    property real memTotal: 0.0

    // ── CPU polling ───────────────────────────────────────────────────────────
    property var _prev: ({})

    Process {
        id: cpuProc
        command: ["cat", "/proc/stat"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                const m = line.match(/^(cpu\d*)\s+(.+)/)
                if (!m) return
                const id    = m[1]
                if (id !== "cpu") return   // pill only shows overall

                const parts = m[2].trim().split(/\s+/).map(Number)
                const idle  = parts[3] + parts[4]
                const busy  = parts[0] + parts[1] + parts[2] + parts[5] + parts[6]
                const total = idle + busy

                const prev   = root._prev["cpu"] || { idle, total }
                const dIdle  = idle  - prev.idle
                const dTotal = total - prev.total
                root._prev["cpu"] = { idle, total }
                root.cpuUsage = dTotal > 0 ? (1.0 - dIdle / dTotal) * 100.0 : 0.0
            }
        }
    }

    // ── Memory polling ────────────────────────────────────────────────────────
    Process {
        id: memProc
        command: ["cat", "/proc/meminfo"]
        running: false

        stdout: SplitParser {
            property var _t: 0

            onRead: (line) => {
                const val = parseInt(line.split(/\s+/)[1])
                if      (line.startsWith("MemTotal:"))     _t = val
                else if (line.startsWith("MemAvailable:")) {
                    root.memTotal = _t / 1024 / 1024
                    root.memUsed  = (_t - val) / 1024 / 1024
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
        }
    }

    // ── Display ───────────────────────────────────────────────────────────────
    Row {
        spacing: 8

        Text {
            text: "CPU " + Math.round(root.cpuUsage) + "%"
            color: Colors.primary
            font.pointSize: 11
            font.bold: true
            font.family: Fonts.font
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 1; height: 14
            color: Colors.outline
            opacity: 0.5
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: "MEM " + root.memUsed.toFixed(1) + "G"
            color: Colors.primary
            font.pointSize: 11
            font.bold: true
            font.family: Fonts.font
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    onClicked:      Popups.systemOpen = !Popups.systemOpen
    onRightClicked: Popups.systemOpen = !Popups.systemOpen
}

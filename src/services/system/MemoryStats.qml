pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property real usage: root._usage
    readonly property real usedGb: root._usedGb
    readonly property real totalGb: root._totalGb
    readonly property real availableGb: root._availableGb
    readonly property real swapUsage: root._swapUsage
    readonly property real swapUsedGb: root._swapUsedGb
    readonly property real swapTotalGb: root._swapTotalGb

    property real _usage: 0.0
    property real _usedGb: 0.0
    property real _totalGb: 0.0
    property real _availableGb: 0.0
    property real _swapUsage: 0.0
    property real _swapUsedGb: 0.0
    property real _swapTotalGb: 0.0

    property int _memTotal: 0
    property int _memAvailable: 0
    property int _swapTotal: 0
    property int _swapFree: 0

    Process {
        id: memProc
        command: ["cat", "/proc/meminfo"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                const parts = line.split(/\s+/)
                if (parts.length < 2) return

                const value = parseInt(parts[1])
                if (isNaN(value)) return

                if      (line.startsWith("MemTotal:"))     root._memTotal = value
                else if (line.startsWith("MemAvailable:")) root._memAvailable = value
                else if (line.startsWith("SwapTotal:"))    root._swapTotal = value
                else if (line.startsWith("SwapFree:"))     root._swapFree = value
            }
        }

        onExited: {
            const usedKb = Math.max(0, root._memTotal - root._memAvailable)
            const swapUsedKb = Math.max(0, root._swapTotal - root._swapFree)

            root._totalGb     = root._memTotal / 1024 / 1024
            root._usedGb      = usedKb / 1024 / 1024
            root._availableGb = root._memAvailable / 1024 / 1024
            root._usage       = root._memTotal > 0 ? usedKb / root._memTotal : 0.0

            root._swapTotalGb = root._swapTotal / 1024 / 1024
            root._swapUsedGb  = swapUsedKb / 1024 / 1024
            root._swapUsage   = root._swapTotal > 0 ? swapUsedKb / root._swapTotal : 0.0
        }
    }

    Timer {
        interval:        1000
        running:         true
        repeat:          true
        triggeredOnStart: true

        onTriggered: {
            root._memTotal = 0
            root._memAvailable = 0
            root._swapTotal = 0
            root._swapFree = 0
            memProc.running = true
        }
    }
}

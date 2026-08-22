pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property real usage: root._usage
    readonly property var cores: root._cores
    readonly property real frequencyGhz: root._frequencyGhz

    property real _usage: 0.0
    property var  _cores: []
    property real _frequencyGhz: 0.0
    property var  _prevTotal: ({})
    property var  _prevCores: ({})
    property var  _currentCores: []

    Process {
        id: cpuProc
        command: ["cat", "/proc/stat"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                const totalMatch = line.match(/^cpu\s+(.+)/)
                if (totalMatch) {
                    const parts = totalMatch[1].trim().split(/\s+/).map(Number)
                    if (parts.length < 5) return

                    const idle  = parts[3] + parts[4]
                    const total = parts.reduce((a, b) => a + b, 0)
                    const prev  = root._prevTotal
                    const dIdle  = idle  - (prev.idle  ?? idle)
                    const dTotal = total - (prev.total ?? total)

                    root._prevTotal = { idle, total }
                    root._usage = dTotal > 0
                        ? Math.max(0, Math.min(1.0, 1.0 - dIdle / dTotal))
                        : 0.0
                    return
                }

                const coreMatch = line.match(/^cpu(\d+)\s+(.+)/)
                if (!coreMatch) return

                const id = Number(coreMatch[1])
                const parts = coreMatch[2].trim().split(/\s+/).map(Number)
                if (parts.length < 5) return

                const idle  = parts[3] + parts[4]
                const total = parts.reduce((a, b) => a + b, 0)
                const prev  = root._prevCores[id]
                const dIdle  = idle  - (prev?.idle  ?? idle)
                const dTotal = total - (prev?.total ?? total)
                const usage = dTotal > 0
                    ? Math.max(0, Math.min(1.0, 1.0 - dIdle / dTotal))
                    : 0.0

                root._prevCores[id] = { idle, total }
                root._currentCores.push({ id, usage })
            }
        }

        onExited: {
            root._cores = root._currentCores.sort((a, b) => a.id - b.id).slice()
            root._currentCores = []
        }
    }

    Process {
        id: freqProc
        command: ["sh", "-c",
            "f=/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq; " +
            "if [ -r \"$f\" ]; then cat \"$f\"; " +
            "else awk -F': ' '/^cpu MHz/ {print $2; exit}' /proc/cpuinfo; fi"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                const v = parseFloat(line.trim())
                if (isNaN(v)) return
                root._frequencyGhz = v > 100000 ? v / 1000000 : v / 1000
            }
        }
    }

    Timer {
        interval:        1000
        running:         true
        repeat:          true
        triggeredOnStart: true

        onTriggered: {
            root._currentCores = []
            cpuProc.running = true
            freqProc.running = true
        }
    }
}

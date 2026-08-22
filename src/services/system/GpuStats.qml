pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool available: root._available
    readonly property string name: root._name
    readonly property real usage: root._usage
    readonly property real vramUsedGb: root._vramUsedGb
    readonly property real vramTotalGb: root._vramTotalGb
    readonly property int temperature: root._temperature

    property bool _available: false
    property string _name: ""
    property real _usage: 0.0
    property real _vramUsedGb: 0.0
    property real _vramTotalGb: 0.0
    property int _temperature: 0
    property bool _received: false

    Process {
        id: gpuProc
        command: ["sh", "-c",
            "if command -v nvidia-smi >/dev/null 2>&1; then " +
            "result=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,name " +
            "--format=csv,noheader,nounits 2>/dev/null | head -1); " +
            "if [ -n \"$result\" ]; then echo \"$result\" | tr ',' '|'; exit; fi; fi; " +
            "for f in /sys/class/drm/card*/device/gpu_busy_percent; do " +
            "[ -r $f ] || continue; " +
            "d=${f%/*}; used=$(cat $f); usedm=$(cat $d/mem_info_vram_used 2>/dev/null || echo 0); " +
            "totalm=$(cat $d/mem_info_vram_total 2>/dev/null || echo 0); " +
            "echo AMD|$used|$usedm|$totalm|0; exit; done; " +
            "for f in /sys/class/drm/card*/device/gt/gt*/gt_busy_percent; do " +
            "[ -r $f ] || continue; used=$(cat $f); echo Intel|$used|0|0|0; exit; done; " +
            "echo NONE"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                root._received = true
                const text = line.trim()
                if (!text || text === "NONE") {
                    root._available = false
                    root._name = ""
                    root._usage = 0.0
                    root._vramUsedGb = 0.0
                    root._vramTotalGb = 0.0
                    root._temperature = 0
                    return
                }

                const parts = text.split("|")
                if (parts.length < 5) return

                const usage = parseFloat(parts[0])
                if (!isNaN(usage) && parts[0] !== "AMD" && parts[0] !== "Intel") {
                    root._available = true
                    root._usage = Math.max(0, Math.min(1.0, usage / 100.0))
                    root._vramUsedGb = (parseFloat(parts[1]) || 0) / 1024
                    root._vramTotalGb = (parseFloat(parts[2]) || 0) / 1024
                    root._temperature = parseInt(parts[3]) || 0
                    root._name = parts.slice(4).join("|").trim() || "NVIDIA GPU"
                    return
                }

                const family = parts[0]
                const busy = parseFloat(parts[1])
                if (isNaN(busy)) return

                root._available = true
                root._usage = Math.max(0, Math.min(1.0, busy / 100.0))
                root._vramUsedGb = (parseFloat(parts[2]) || 0) / 1024 / 1024 / 1024
                root._vramTotalGb = (parseFloat(parts[3]) || 0) / 1024 / 1024 / 1024
                root._temperature = parseInt(parts[4]) || 0
                root._name = family + " GPU"
            }
        }

        onExited: {
            if (!root._received) {
                root._available = false
                root._name = ""
                root._usage = 0.0
                root._vramUsedGb = 0.0
                root._vramTotalGb = 0.0
                root._temperature = 0
            }
        }
    }

    Timer {
        interval:        1500
        running:         true
        repeat:          true
        triggeredOnStart: true

        onTriggered: {
            root._received = false
            gpuProc.running = true
        }
    }
}

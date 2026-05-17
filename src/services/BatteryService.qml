pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── Battery State ─────────────────────────────────────────────────────────
    property int    capacity:   0
    property bool   charging:   false
    property bool   full:       false
    property string status:     "Unknown"
    property bool   hasBattery: false

    readonly property real fraction: capacity / 100

    // ── Polling Processes ─────────────────────────────────────────────────────
    Process {
        id: _capProc
        command: ["cat", "/sys/class/power_supply/BAT0/capacity"]
        running: true

        stdout: SplitParser {
            onRead: (data) => {
                const v = parseInt(data.trim())
                if (!isNaN(v)) {
                    root.capacity   = v
                    root.hasBattery = true
                }
            }
        }

        onExited: (code) => {
            if (code !== 0) {
                root.hasBattery = false
            }
        }
    }

    Process {
        id: _statProc
        command: ["cat", "/sys/class/power_supply/BAT0/status"]
        running: true

        stdout: SplitParser {
            onRead: (data) => {
                const s       = data.trim()
                root.status   = s
                root.charging = (s === "Charging")
                root.full     = (s === "Full")
            }
        }
    }

    // ── Polling Timer ─────────────────────────────────────────────────────────
    Timer {
        interval: 30000
        repeat:   true
        running:  true
        
        onTriggered: {
            _capProc.running  = true
            _statProc.running = true
        }
    }
}

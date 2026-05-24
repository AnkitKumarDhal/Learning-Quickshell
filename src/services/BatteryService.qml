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
        id: _finder
        command: ["sh", "-c", "ls /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                const path = line.trim()
                if (path) {
                    _capProc.command = ["cat", path]
                    _statProc.command = ["cat", path.replace("/capacity", "/status")]
                    root.hasBattery = true
                    _capProc.running = true
                    _statProc.running = true
                }
            }
        }
    }

    Process { 
        id: _capProc
        command: ["cat", "/dev/null"]
        running: false
        stdout: SplitParser { 
            onRead: (d) => { 
                const v = parseInt(d)
                if (!isNaN(v)) { 
                    root.capacity = v
                    root.hasBattery = true 
                } 
            } 
        } 
    }

    Process { 
        id: _statProc
        command: ["cat", "/dev/null"]
        running: false
        stdout: SplitParser { 
            onRead: (d) => { 
                const s = d.trim()
                root.status = s
                root.charging = s === "Charging"
                root.full = s === "Full" 
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

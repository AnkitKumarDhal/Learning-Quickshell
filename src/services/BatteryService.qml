pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.src.theme

/**
 * Battery service that monitors system battery status.
 * Polls /sys/class/power_supply for capacity and status information.
 */
Singleton {
    id: root

    // ── Battery State ─────────────────────────────────────────────────────────
    property int    capacity:   0
    property bool   charging:   false
    property bool   full:       false
    property string status:     "Unknown"
    property bool   hasBattery: false

    readonly property real fraction: capacity / 100

    /**
     * Returns the appropriate battery icon based on capacity and charging state.
     * Uses Nerd Font glyphs for visual representation.
     */
    function getIcon(): string {
        if (full)     return "󰁹 "
        if (charging) {
            if (capacity >= 90) return "󰂋 "
            if (capacity >= 80) return "󰂊 "
            if (capacity >= 70) return "󰢞 "
            if (capacity >= 60) return "󰂉 "
            if (capacity >= 50) return "󰢝 "
            if (capacity >= 40) return "󰂈 "
            if (capacity >= 30) return "󰂇 "
            if (capacity >= 20) return "󰂆 "
            if (capacity >= 10) return "󰢜 "
            return "󰢟 "
        }
        if (capacity >= 90) return "󰁹 "
        if (capacity >= 80) return "󰂀 "
        if (capacity >= 60) return "󰁿 "
        if (capacity >= 40) return "󰁼 "
        if (capacity >= 20) return "󰁻 "
        if (capacity >= 10) return "󰁺 "
        return "󰂎 "
    }

    /**
     * Returns the appropriate color based on battery state.
     * Error color for low battery, tertiary for charging/full, primary otherwise.
     */
    function getColor(): string {
        if (charging || full) return Colors.tertiary
        if (capacity <= 10) return Colors.error
        return Colors.primary
    }

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

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.src.theme

Singleton {
    id: root

    // ── Battery State ─────────────────────────────────────────────────────────
    property int    capacity:    0
    property bool   charging:    false
    property bool   full:        false
    property bool   notCharging: false   // conservation cap reached (80%)
    property string status:      "Unknown"
    property bool   hasBattery:  false
    property bool   applying:    false

    // ── Time remaining ────────────────────────────────────────────────────────
    property int timeRemainingMinutes: -1

    // ── Mode detection ────────────────────────────────────────────────────────
    property int    conservationMode: -1   // 0 or 1, -1 = unknown
    property string cpuProfile:       ""   // performance | balanced | power-saver

    // Persist last-applied mode to /tmp so eco vs quickjuice is distinguishable
    property string _savedMode: ""

    readonly property string currentMode: {
        if (conservationMode === 1 && cpuProfile === "performance") return "game"
        if (conservationMode === 1 && cpuProfile === "balanced")    return "study"
        if (conservationMode === 0 && cpuProfile === "power-saver") {
            return _savedMode === "quickjuice" ? "quickjuice" : "eco"
        }
        return "custom"
    }

    readonly property real fraction: capacity / 100

    function getIcon(): string {
        if (notCharging)  return "󱈸 "
        if (full)         return "󰁹 "
        if (charging) {
            if (capacity >= 95) return "󰂅 "
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

    function getColor(): string {
        if (charging || full || notCharging) return Colors.tertiary
        if (capacity <= 25) return Colors.error
        return Colors.primary
    }

    function formatTimeRemaining(): string {
        if (timeRemainingMinutes <= 0) return ""
        const h = Math.floor(timeRemainingMinutes / 60)
        const m = timeRemainingMinutes % 60
        if (h === 0) return m + "m"
        return h + "h " + String(m).padStart(2, "0") + "m"
    }

    function applyMode(mode) {
        applying   = true
        _savedMode = mode

        // Persist hint so eco vs quickjuice survives restarts
        _writeModeProc.command = ["sh", "-c", "printf '%s' " + mode + " > /tmp/qs_battery_mode"]
        _writeModeProc.running = true

        // Map id → fish function name
        const fishFn = (mode === "quickjuice") ? "quick-juice" : mode
        _modeProc.command = ["fish", "-c", fishFn + "-mode"]
        _modeProc.running = true
    }

    // ── Internal ──────────────────────────────────────────────────────────────
    property string _batPath: ""

    // Load saved mode hint on startup
    Process {
        id: _readModeProc
        command: ["cat", "/tmp/qs_battery_mode"]
        running: true
        stdout: SplitParser {
            onRead: (d) => {
                const m = d.trim()
                if (m) root._savedMode = m
            }
        }
    }

    Process {
        id: _writeModeProc
        command: []
        running: false
    }

    // Discover battery sysfs path and set commands for subsequent processes
    Process {
        id: _finder
        command: ["sh", "-c", "ls /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                const p = line.trim()
                if (!p) return
                root._batPath = p.replace("/capacity", "")

                _capProc.command  = ["cat", root._batPath + "/capacity"]
                _statProc.command = ["cat", root._batPath + "/status"]
                _energyProc.command = ["sh", "-c",
                    "a=$(cat " + root._batPath + "/energy_now 2>/dev/null || " +
                         "cat " + root._batPath + "/charge_now 2>/dev/null || echo -1); " +
                    "b=$(cat " + root._batPath + "/power_now 2>/dev/null || " +
                         "cat " + root._batPath + "/current_now 2>/dev/null || echo -1); " +
                    "c=$(cat " + root._batPath + "/energy_full 2>/dev/null || " +
                         "cat " + root._batPath + "/charge_full 2>/dev/null || echo -1); " +
                    "echo $a; echo $b; echo $c"
                ]

                root.hasBattery       = true
                _capProc.running     = true
                _statProc.running    = true
                _energyProc.running  = true
                _consProc.running    = true
                _profileProc.running = true
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
                if (!isNaN(v)) { root.capacity = v; root.hasBattery = true }
            }
        }
    }

    Process {
        id: _statProc
        command: ["cat", "/dev/null"]
        running: false
        stdout: SplitParser {
            onRead: (d) => {
                const s        = d.trim()
                root.status      = s
                root.charging    = (s === "Charging")
                root.full        = (s === "Full")
                root.notCharging = (s === "Not charging")
            }
        }
    }

    // Reads energy_now, power_now, energy_full (or charge_ equivalents) for time estimate
    Process {
        id: _energyProc
        command: []
        running: false
        property var _vals: []

        stdout: SplitParser {
            onRead: (line) => {
                const v = parseInt(line.trim())
                _energyProc._vals.push(isNaN(v) ? -1 : v)
            }
        }

        onExited: {
            const vals = _energyProc._vals.slice()
            _energyProc._vals = []

            if (vals.length < 3 || vals[1] <= 0 || vals[0] < 0) {
                root.timeRemainingMinutes = -1
                return
            }
            const now  = vals[0]
            const rate = vals[1]
            const full = vals[2]

            if (root.charging && full > 0 && full > now) {
                root.timeRemainingMinutes = Math.max(1, Math.round(((full - now) / rate) * 60))
            } else if (!root.full && !root.notCharging && !root.charging && now > 0) {
                root.timeRemainingMinutes = Math.max(1, Math.round((now / rate) * 60))
            } else {
                root.timeRemainingMinutes = -1
            }
        }
    }

    Process {
        id: _consProc
        command: ["cat", "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"]
        running: false
        stdout: SplitParser {
            onRead: (d) => {
                const v = parseInt(d.trim())
                if (!isNaN(v)) root.conservationMode = v
            }
        }
    }

    Process {
        id: _profileProc
        command: ["powerprofilesctl", "get"]
        running: false
        stdout: SplitParser {
            onRead: (d) => { root.cpuProfile = d.trim() }
        }
    }

    Process {
        id: _modeProc
        command: []
        running: false
        onExited: {
            root.applying        = false
            _capProc.running     = true
            _statProc.running    = true
            _energyProc.running  = true
            _consProc.running    = true
            _profileProc.running = true
        }
    }

    // Poll every 5 s instead of 30 s so status flips are near-instant
    Timer {
        interval:         5000
        repeat:           true
        running:          root.hasBattery
        triggeredOnStart: false
        onTriggered: {
            _capProc.running     = true
            _statProc.running    = true
            _energyProc.running  = true
            _consProc.running    = true
            _profileProc.running = true
        }
    }
}

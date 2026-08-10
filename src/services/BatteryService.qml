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
    property bool   notCharging: false
    property string status:      "Unknown"
    property bool   hasBattery:  false
    property bool   applying:    false

    // ── Time remaining ────────────────────────────────────────────────────────
    property int timeRemainingMinutes: -1

    // ── Independent control state ────────────────────────────────────────────
    property string cpuTier:     ""   // power-saving | balanced | performance
    property string chargeMode:  ""   // rapid | conserve | full
    property int    refreshRate: 0    // 60 | 120

    property string _epp:      ""
    property string _platform: ""

    readonly property real fraction: capacity / 100

    function getIcon(): string {
        if (full) return "󰁹 "
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

    function setCpuTier(tier) {
        const fn = { "power-saving": "pwr-power-saving", "balanced": "pwr-balanced", "performance": "pwr-performance" }[tier]
        if (!fn) return
        applying = true
        _cpuProc.command = ["fish", "-c", fn]
        _cpuProc.running = true
    }

    function setChargeMode(mode) {
        const fn = { "rapid": "charge-rapid", "conserve": "charge-conserve", "full": "charge-full" }[mode]
        if (!fn) return
        applying = true
        _chargeProc.command = ["fish", "-c", fn]
        _chargeProc.running = true
    }

    function setRefreshRate(hz) {
        applying = true
        _displayProc.command = ["fish", "-c", (hz === 120 ? "display-120hz" : "display-60hz")]
        _displayProc.running = true
    }

    function _recomputeCpuTier() {
        if (_platform === "low-power")        root.cpuTier = "power-saving"
        else if (_platform === "performance") root.cpuTier = "performance"
        else if (_platform === "balanced")    root.cpuTier = "balanced"
    }

    // ── Internal ──────────────────────────────────────────────────────────────
    property string _batPath: ""

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
                _chargeTypeProc.command = ["cat", root._batPath + "/charge_types"]
                _energyProc.command = ["sh", "-c",
                    "a=$(cat " + root._batPath + "/energy_now 2>/dev/null || " +
                         "cat " + root._batPath + "/charge_now 2>/dev/null || echo -1); " +
                    "b=$(cat " + root._batPath + "/power_now 2>/dev/null || " +
                         "cat " + root._batPath + "/current_now 2>/dev/null || echo -1); " +
                    "c=$(cat " + root._batPath + "/energy_full 2>/dev/null || " +
                         "cat " + root._batPath + "/charge_full 2>/dev/null || echo -1); " +
                    "echo $a; echo $b; echo $c"
                ]

                root.hasBattery         = true
                _capProc.running        = true
                _statProc.running       = true
                _energyProc.running     = true
                _chargeTypeProc.running = true
                _eppProc.running        = true
                _platformProc.running   = true
                _refreshProc.running    = true
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

    // charge_types looks like: "Fast Standard [Long_Life]" — bracketed entry is active
    Process {
        id: _chargeTypeProc
        command: ["cat", "/dev/null"]
        running: false
        stdout: SplitParser {
            onRead: (d) => {
                const m = d.match(/\[(\w+)\]/)
                if (!m) return
                const active = m[1]
                if (active === "Fast")            root.chargeMode = "rapid"
                else if (active === "Long_Life")  root.chargeMode = "conserve"
                else if (active === "Standard")   root.chargeMode = "full"
            }
        }
    }

    Process {
        id: _eppProc
        command: ["cat", "/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference"]
        running: false
        stdout: SplitParser {
            onRead: (d) => { root._epp = d.trim(); root._recomputeCpuTier() }
        }
    }

    Process {
        id: _platformProc
        command: ["cat", "/sys/firmware/acpi/platform_profile"]
        running: false
        stdout: SplitParser {
            onRead: (d) => { root._platform = d.trim(); root._recomputeCpuTier() }
        }
    }

    Process {
        id: _refreshProc
        command: ["sh", "-c", "hyprctl monitors -j | jq -r '.[] | select(.name==\"eDP-1\") | .refreshRate'"]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                const v = parseFloat(line.trim())
                if (!isNaN(v)) root.refreshRate = Math.round(v)
            }
        }
    }

    Process {
        id: _cpuProc
        command: []
        running: false
        onExited: { root.applying = false; _eppProc.running = true; _platformProc.running = true }
    }

    Process {
        id: _chargeProc
        command: []
        running: false
        onExited: { root.applying = false; _chargeTypeProc.running = true }
    }

    Process {
        id: _displayProc
        command: []
        running: false
        onExited: { root.applying = false; _refreshProc.running = true }
    }

    // Adaptive polling: poll more frequently when charging/discharging, less when full
    property int _batteryPollInterval: (root.charging || (!root.full && !root.notCharging)) ? 5000 : 15000
    
    Timer {
        id: batteryTimer
        interval:         root._batteryPollInterval
        repeat:           true
        running:          root.hasBattery
        triggeredOnStart: false
        
        onTriggered: {
            _capProc.running        = true
            _statProc.running       = true
            _energyProc.running     = true
            _chargeTypeProc.running = true
            _eppProc.running        = true
            _platformProc.running   = true
            _refreshProc.running    = true
        }
    }
    
    // Update polling interval based on battery state changes
    Connections {
        target: root
        function onChargingChanged() { batteryTimer.restart() }
        function onFullChanged() { batteryTimer.restart() }
        function onNotChargingChanged() { batteryTimer.restart() }
    }
}

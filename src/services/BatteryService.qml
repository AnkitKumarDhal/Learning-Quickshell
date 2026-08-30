pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.src.theme

Singleton {
    id: root

    property int capacity: 0
    property bool charging: false
    property bool full: false
    property bool notCharging: false
    property string status: "Unknown"
    property bool hasBattery: false
    property bool applying: false

    property int timeRemainingMinutes: -1

    property string cpuTier: ""
    property string chargeMode: ""
    property int refreshRate: 0

    readonly property real fraction: capacity / 100

    property string _backendPath: Qt.resolvedUrl("../../tools/battery/velox-battery/target/debug/velox-battery")
    property var _state: null

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
        if (!["power-saving", "balanced", "performance"].includes(tier))
            return

        applying = true
        _actionProc.command = [root._backendPath, "performance", "set", tier]
        _actionProc.running = true
    }

    function setChargeMode(mode) {
        if (!["conserve", "full"].includes(mode))
            return

        applying = true
        _actionProc.command = [root._backendPath, "charge", "set", mode]
        _actionProc.running = true
    }

    function setRefreshRate(hz) {
        if (!Number.isFinite(hz))
            return

        applying = true
        _actionProc.command = [root._backendPath, "display", "set", String(Math.round(hz))]
        _actionProc.running = true
    }

    function _applyState(data) {
        if (!data || typeof data !== "object")
            return

        root._state = data

        const battery = data.battery ?? {}
        const chargingState = data.charging ?? {}
        const performance = data.performance ?? {}
        const display = data.display ?? {}

        root.hasBattery = battery.present === true

        if (root.hasBattery) {
            root.capacity = Number(battery.capacity ?? 0)
            root.status = battery.status ?? "Unknown"
            root.timeRemainingMinutes = Number(battery.time_remaining_minutes ?? -1)

            root.charging = root.status === "Charging"
            root.full = root.status === "Full"
            root.notCharging = root.status === "Not charging"
        } else {
            root.capacity = 0
            root.status = "Unknown"
            root.timeRemainingMinutes = -1
            root.charging = false
            root.full = false
            root.notCharging = false
        }

        root.cpuTier = performance.current ?? ""

        root.chargeMode = chargingState.current ?? ""

        root.refreshRate = Number(display.current_refresh ?? 0)
        if (Number.isFinite(root.refreshRate))
            root.refreshRate = Math.round(root.refreshRate)
        else
            root.refreshRate = 0
    }

    function _refresh() {
        if (_statusProc.running)
            return

        _statusProc.running = true
    }

    Process {
        id: _statusProc
        command: [root._backendPath, "status"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    root._applyState(data)
                } catch (error) {
                    console.warn("BatteryService: failed to parse velox-battery output:", error)
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("BatteryService: velox-battery status failed:", exitCode)
        }
    }

    Process {
        id: _actionProc
        command: []
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)

                    if (data.result)
                        root._applyState(data.result)
                    else
                        root._refresh()
                } catch (error) {
                    root._refresh()
                }
            }
        }

        onExited: {
            root.applying = false
            root._refresh()
        }
    }

    Timer {
        id: batteryTimer
        interval: 5000
        repeat: true
        running: root.hasBattery
        triggeredOnStart: true
        onTriggered: root._refresh()
    }

    Component.onCompleted: root._refresh()
}

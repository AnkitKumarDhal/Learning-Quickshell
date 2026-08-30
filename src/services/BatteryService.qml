pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.src.theme

Singleton {
    id: root

    property int capacity: 0
    property bool charging: false
    property bool full: false
    property bool notCharging: false
    property string status: "Unknown"
    property bool hasBattery: false
    property bool initialized: false
    property bool applying: false

    property int timeRemainingMinutes: -1

    property string cpuTier: ""
    property string chargeMode: ""
    property int refreshRate: 0

    readonly property real fraction: capacity / 100

    readonly property bool performanceAvailable: _state?.performance?.available === true
    readonly property bool chargingAvailable: _state?.charging?.available === true
    readonly property bool displayAvailable: _state?.display?.available === true

    readonly property var performanceOptions: _state?.performance?.options ?? []
    readonly property var chargingOptions: _state?.charging?.options ?? []
    readonly property var displayOptions: _state?.display?.options ?? []

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
        if (!performanceAvailable || !performanceOptions.includes(tier))
            return

        applying = true
        _actionProc.command = [root._backendPath, "performance", "set", tier]
        _actionProc.running = true
    }

    function setChargeMode(mode) {
        if (!chargingAvailable || !chargingOptions.includes(mode))
            return

        applying = true
        _actionProc.command = [root._backendPath, "charge", "set", mode]
        _actionProc.running = true
    }

    function setRefreshRate(hz) {
        if (!displayAvailable || !Number.isFinite(hz))
            return

        const available = displayOptions.some(rate => Math.abs(Number(rate) - hz) < 0.01)
        if (!available)
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

        root.initialized = true
    }

    function _refresh() {
        if (_statusProc.running)
            return

        _statusProc.running = true
    }

    Connections {
        target: UPower
        function onOnBatteryChanged() {
            root._refresh()
        }
    }

    Connections {
        target: UPower.displayDevice
        function onStateChanged() {
            root._refresh()
        }
        function onPercentageChanged() {
            root._refresh()
        }
        function onTimeToEmptyChanged() {
            root._refresh()
        }
        function onTimeToFullChanged() {
            root._refresh()
        }
    }

    Process {
        id: _statusProc
        command: [root._backendPath, "status"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root._applyState(JSON.parse(text))
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

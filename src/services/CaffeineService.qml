pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // 0 = OFF
    // 1 = 2 min
    // 2 = 5 min
    // 3 = 10 min
    // 4 = 15 min
    // 5 = 30 min
    // 6 = Infinite

    readonly property var presets: [0, 2, 5, 10, 15, 30, -1]
    readonly property var presetLabels: ["Off", "2 min", "5 min", "10 min", "15 min", "30 min", "∞"]

    property int presetIndex: 0
    property bool caffeineActive: false
    property bool infinite: false

    property double expiresAtMs: 0
    property double nowMs: Date.now()

    readonly property int remainingSeconds:
        root.expiresAtMs > 0
            ? Math.max(0, Math.ceil((root.expiresAtMs - root.nowMs) / 1000))
            : 0

    property bool anyInhibitorActive: false
    property bool externalInhibitorActive: false

    property var ownInhibitorPids: []

    property bool _changingPreset: false
    property bool _startupSync: true
    property int _pendingPresetIndex: -1

    readonly property string stateFilePath: Quickshell.statePath("caffeine.json")

    FileView {
        id: stateFile
        path: root.stateFilePath
        printErrors: false
        blockLoading: false
    }

    function readSavedState() {
        const raw = stateFile.text()

        if (!raw || raw.trim() === "") return null

        try {
            return JSON.parse(raw)
        } catch (error) {
            console.warn("CaffeineService: failed to parse saved state:", error)
            return null
        }
    }

    function saveState() {
        stateFile.setText(
            JSON.stringify({
                presetIndex: root.presetIndex,
                expiresAtMs: root.expiresAtMs,
                infinite: root.infinite
            })
        )
    }

    function clearSavedState() {
        stateFile.setText("")
    }

    Timer {
        id: clockTimer

        interval: 250
        repeat: true
        running: true

        onTriggered: {
            root.nowMs = Date.now()

            if (root.caffeineActive && !root.infinite && root.expiresAtMs > 0 && root.nowMs >= root.expiresAtMs) {
                root.finishTimer()
            }
        }
    }

    Timer {
        id: inhibitorPollTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.refreshState()
    }

    Timer {
        id: presetStartTimer
        interval: 150
        repeat: false
        onTriggered: root.startPendingPreset()
    }

    Process {
        id: inhibitorListProcess

        command: [
            "systemd-inhibit",
            "--list",
            "--no-legend",
            "--no-pager"
        ]

        stdout: StdioCollector {
            onStreamFinished: root.parseInhibitors(this.text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    console.warn("CaffeineService:", this.text.trim())
                }
            }
        }
    }

    function refreshState() {
        if (inhibitorListProcess.running) return
        inhibitorListProcess.running = true
    }

    function parseInhibitors(output) {
        const lines = output
            .split(/\r?\n/)
            .map(line => line.trim())
            .filter(line => line.length > 0)

        let ownPids = []
        let otherCount = 0

        for (const line of lines) {
            const fields = line.split(/\s+/)

            if (fields.length < 8) continue

            const who = fields[0]
            const pid = Number(fields[3])

            if (who === "Quickshell-Caffeine") {
                if (Number.isFinite(pid) && pid > 0) {
                    ownPids.push(pid)
                }
                continue
            }

            otherCount++
        }

        root.ownInhibitorPids = ownPids
        root.anyInhibitorActive = lines.length > 0
        root.externalInhibitorActive = otherCount > 0

        const ownActive = ownPids.length > 0

        if (root._changingPreset) return
        if (ownActive) {
            root.caffeineActive = true
            if (root._startupSync) {
                const saved = root.readSavedState()

                if (saved) {
                    const savedIndex = Math.max(0, Math.min(6, Number(saved.presetIndex) || 0))
                    const savedExpiry = Number(saved.expiresAtMs) || 0
                    const savedInfinite = Boolean(saved.infinite)

                    if (!savedInfinite && savedExpiry > Date.now()) {
                        root.presetIndex = savedIndex
                        root.expiresAtMs = savedExpiry
                        root.infinite = false
                    }

                    else if (savedInfinite) {
                        root.presetIndex = 6
                        root.expiresAtMs = 0
                        root.infinite = true
                    }
                    else {
                        root._stopOwnInhibitors()

                        root.presetIndex = 0
                        root.expiresAtMs = 0
                        root.infinite = false
                        root.caffeineActive = false

                        root.clearSavedState()
                    }
                }
                else {
                    root.presetIndex = 6
                    root.expiresAtMs = 0
                    root.infinite = true
                    root.saveState()
                }

                root._startupSync = false
            }
            if (!root.infinite && root.expiresAtMs > 0 && root.expiresAtMs <= Date.now()) {
                root.finishTimer()
            }

            return
        }

        if (root._startupSync) {
            root._startupSync = false

            root.presetIndex = 0
            root.caffeineActive = false
            root.infinite = false
            root.expiresAtMs = 0

            root.clearSavedState()

            return
        }

        if (root.caffeineActive) {
            root.presetIndex = 0
            root.caffeineActive = false
            root.infinite = false
            root.expiresAtMs = 0

            root.clearSavedState()
        }
    }

    function startDetachedInhibitor(seconds) {
        const duration = seconds < 0 ? "infinity" : String(seconds)
        Quickshell.execDetached([
            "systemd-inhibit",
            "--what=idle:sleep",
            "--who=Quickshell-Caffeine",
            "--why=Caffeine",
            "--mode=block",
            "sleep",
            duration
        ])
    }

    function stopOwnInhibitors() {
        const pids = root.ownInhibitorPids.slice()

        for (const pid of pids) {
            Quickshell.execDetached([
                "kill",
                "-TERM",
                String(pid)
            ])
        }
    }

    function finishTimer() {
        if (!root.caffeineActive) return

        root._changingPreset = true
        root.stopOwnInhibitors()

        root.presetIndex = 0
        root.caffeineActive = false
        root.infinite = false
        root.expiresAtMs = 0

        root.clearSavedState()
        finishReleaseTimer.restart()
    }

    Timer {
        id: finishReleaseTimer
        interval: 100
        repeat: false
        onTriggered: {
            root._changingPreset = false
            root.refreshState()
        }
    }

    function setPreset(index) {
        index = Math.max(0, Math.min(6, Number(index)))

        if (index === 0) {
            root._changingPreset = true
            root._pendingPresetIndex = -1

            root.stopOwnInhibitors()

            root.presetIndex = 0
            root.caffeineActive = false
            root.infinite = false
            root.expiresAtMs = 0

            root.clearSavedState()

            presetStartTimer.stop()
            presetReleaseTimer.restart()

            return
        }

        root._changingPreset = true
        root.stopOwnInhibitors()

        root.presetIndex = index
        root.caffeineActive = true
        root.infinite = index === 6

        const minutes = Number(root.presets[index])
        root.expiresAtMs = index === 6 ? 0 : Date.now() + (minutes * 60 * 1000)
        root.saveState()
        root._pendingPresetIndex = index

        presetStartTimer.restart()
    }

    Timer {
        id: presetReleaseTimer
        interval: 150
        repeat: false
        onTriggered: {
            root._changingPreset = false
            root.refreshState()
        }
    }

    function startPendingPreset() {
        const index = root._pendingPresetIndex
        root._pendingPresetIndex = -1

        if (index < 1 || index > 6) {
            root._changingPreset = false
            return
        }

        const seconds = index === 6 ? -1 : Number(root.presets[index]) * 60
        root.startDetachedInhibitor(seconds)
        inhibitorAppearTimer.restart()
    }

    Timer {
        id: inhibitorAppearTimer

        interval: 300
        repeat: false

        onTriggered: {
            root._changingPreset = false
            root.refreshState()
        }
    }

    function cyclePreset() {
        let next = root.presetIndex + 1
        if (next > 6) next = 0
        root.setPreset(next)
    }

    function selectPreset(index) {
        root.setPreset(index)
    }

    Component.onCompleted: {
        root.nowMs = Date.now()
        root.refreshState()
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ─────────────────────────────────────────────────────────────────────────
    // Presets
    // ─────────────────────────────────────────────────────────────────────────

    // 0 = OFF
    // 1 = 2 min
    // 2 = 5 min
    // 3 = 10 min
    // 4 = 15 min
    // 5 = 30 min
    // 6 = Infinite

    readonly property var presets: [
        0,
        2,
        5,
        10,
        15,
        30,
        -1
    ]

    readonly property var presetLabels: [
        "Off",
        "2 min",
        "5 min",
        "10 min",
        "15 min",
        "30 min",
        "∞"
    ]

    // ─────────────────────────────────────────────────────────────────────────
    // Public state
    // ─────────────────────────────────────────────────────────────────────────

    property int presetIndex: 0
    property bool caffeineActive: false
    property bool infinite: false

    // Absolute Unix timestamp in milliseconds.
    // 0 = infinite / no expiry.
    property double expiresAtMs: 0

    property double nowMs: Date.now()

    readonly property int remainingSeconds:
        root.expiresAtMs > 0
            ? Math.max(
                0,
                Math.ceil(
                    (root.expiresAtMs - root.nowMs) / 1000
                )
            )
            : 0

    // System inhibitor state.
    property bool anyInhibitorActive: false
    property bool externalInhibitorActive: false

    // PIDs of our own systemd-inhibit processes.
    property var ownInhibitorPids: []

    // ─────────────────────────────────────────────────────────────────────────
    // Internal state
    // ─────────────────────────────────────────────────────────────────────────

    property bool _changingPreset: false
    property bool _startupSync: true
    property int _pendingPresetIndex: -1

    readonly property string stateFilePath:
        Quickshell.statePath("caffeine.json")

    // ─────────────────────────────────────────────────────────────────────────
    // Persistence
    // ─────────────────────────────────────────────────────────────────────────

    FileView {
        id: stateFile

        path: root.stateFilePath

        printErrors: false
        blockLoading: false
    }

    function readSavedState() {
        const raw = stateFile.text()

        if (!raw || raw.trim() === "")
            return null

        try {
            return JSON.parse(raw)
        } catch (error) {
            console.warn(
                "CaffeineService: failed to parse saved state:",
                error
            )

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

    // ─────────────────────────────────────────────────────────────────────────
    // Timers
    // ─────────────────────────────────────────────────────────────────────────

    Timer {
        id: clockTimer

        interval: 250
        repeat: true
        running: true

        onTriggered: {
            root.nowMs = Date.now()

            if (
                root.caffeineActive &&
                !root.infinite &&
                root.expiresAtMs > 0 &&
                root.nowMs >= root.expiresAtMs
            ) {
                root.finishTimer()
            }
        }
    }

    Timer {
        id: inhibitorPollTimer

        interval: 1000
        repeat: true
        running: true

        onTriggered:
            root.refreshState()
    }

    Timer {
        id: presetStartTimer

        interval: 150
        repeat: false

        onTriggered:
            root.startPendingPreset()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // systemd-inhibit query
    // ─────────────────────────────────────────────────────────────────────────

    Process {
        id: inhibitorListProcess

        command: [
            "systemd-inhibit",
            "--list",
            "--no-legend",
            "--no-pager"
        ]

        stdout: StdioCollector {
            onStreamFinished:
                root.parseInhibitors(this.text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    console.warn(
                        "CaffeineService:",
                        this.text.trim()
                    )
                }
            }
        }
    }

    function refreshState() {
        if (inhibitorListProcess.running)
            return

        inhibitorListProcess.running = true
    }

    // systemd-inhibit --list has columns:
    //
    // WHO UID USER PID COMM WHAT WHY MODE
    //
    // Because WHO is the first column, our unique "Who" value
    // lets us identify our own inhibitor reliably.
    function parseInhibitors(output) {
        const lines = output
            .split(/\r?\n/)
            .map(line => line.trim())
            .filter(line => line.length > 0)

        let ownPids = []
        let otherCount = 0

        for (const line of lines) {
            const fields = line.split(/\s+/)

            if (fields.length < 8)
                continue

            const who = fields[0]
            const pid = Number(fields[3])

            if (who === "Quickshell-Caffeine") {
                if (
                    Number.isFinite(pid) &&
                    pid > 0
                ) {
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

        // ─────────────────────────────────────────────────────────────────────
        // During preset replacement:
        //
        // We intentionally ignore the temporary "no inhibitor" state.
        // Otherwise the polling loop can reset our selected preset between
        // killing the old inhibitor and starting the new one.
        // ─────────────────────────────────────────────────────────────────────

        if (root._changingPreset)
            return

        // ─────────────────────────────────────────────────────────────────────
        // Our Caffeine inhibitor exists
        // ─────────────────────────────────────────────────────────────────────

        if (ownActive) {
            root.caffeineActive = true

            // Startup recovery.
            //
            // The inhibitor survived a Quickshell restart, so recover the
            // corresponding timer from our saved state.
            if (root._startupSync) {
                const saved = root.readSavedState()

                if (saved) {
                    const savedIndex =
                        Math.max(
                            0,
                            Math.min(
                                6,
                                Number(saved.presetIndex) || 0
                            )
                        )

                    const savedExpiry =
                        Number(saved.expiresAtMs) || 0

                    const savedInfinite =
                        Boolean(saved.infinite)

                    // Timed preset still valid.
                    if (
                        !savedInfinite &&
                        savedExpiry > Date.now()
                    ) {
                        root.presetIndex = savedIndex
                        root.expiresAtMs = savedExpiry
                        root.infinite = false
                    }

                    // Infinite preset.
                    else if (savedInfinite) {
                        root.presetIndex = 6
                        root.expiresAtMs = 0
                        root.infinite = true
                    }

                    // The saved timer is dead, but the inhibitor still
                    // exists. Kill it rather than displaying stale state.
                    else {
                        root._stopOwnInhibitors()

                        root.presetIndex = 0
                        root.expiresAtMs = 0
                        root.infinite = false
                        root.caffeineActive = false

                        root.clearSavedState()
                    }
                }

                // If there was no saved state but our inhibitor exists,
                // treat it as an externally orphaned Caffeine inhibitor.
                //
                // We still show it as infinite instead of lying and showing
                // OFF.
                else {
                    root.presetIndex = 6
                    root.expiresAtMs = 0
                    root.infinite = true

                    root.saveState()
                }

                root._startupSync = false
            }

            // Normal runtime:
            // if our timer has expired but the systemd inhibitor is somehow
            // still present, clean it up immediately.
            if (
                !root.infinite &&
                root.expiresAtMs > 0 &&
                root.expiresAtMs <= Date.now()
            ) {
                root.finishTimer()
            }

            return
        }

        // ─────────────────────────────────────────────────────────────────────
        // No Caffeine inhibitor exists
        // ─────────────────────────────────────────────────────────────────────

        if (root._startupSync) {
            // Quickshell started and no Caffeine inhibitor exists.
            root._startupSync = false

            root.presetIndex = 0
            root.caffeineActive = false
            root.infinite = false
            root.expiresAtMs = 0

            root.clearSavedState()

            return
        }

        // If our inhibitor disappears unexpectedly, reflect that in the UI.
        if (root.caffeineActive) {
            root.presetIndex = 0
            root.caffeineActive = false
            root.infinite = false
            root.expiresAtMs = 0

            root.clearSavedState()
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Start / stop inhibitor
    // ─────────────────────────────────────────────────────────────────────────

    function startDetachedInhibitor(seconds) {
        const duration =
            seconds < 0
                ? "infinity"
                : String(seconds)

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

    // ─────────────────────────────────────────────────────────────────────────
    // Timer completion
    // ─────────────────────────────────────────────────────────────────────────

    function finishTimer() {
        if (!root.caffeineActive)
            return

        root._changingPreset = true

        root.stopOwnInhibitors()

        root.presetIndex = 0
        root.caffeineActive = false
        root.infinite = false
        root.expiresAtMs = 0

        root.clearSavedState()

        // Release protection after the inhibitor process has had time
        // to terminate.
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

    // ─────────────────────────────────────────────────────────────────────────
    // Preset selection
    // ─────────────────────────────────────────────────────────────────────────

    function setPreset(index) {
        index = Math.max(
            0,
            Math.min(
                6,
                Number(index)
            )
        )

        // ─────────────────────────────────────────────────────────────────────
        // OFF
        // ─────────────────────────────────────────────────────────────────────

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

        // ─────────────────────────────────────────────────────────────────────
        // Timed / infinite preset
        // ─────────────────────────────────────────────────────────────────────

        root._changingPreset = true

        root.stopOwnInhibitors()

        root.presetIndex = index
        root.caffeineActive = true
        root.infinite = index === 6

        const minutes = Number(root.presets[index])

        root.expiresAtMs =
            index === 6
                ? 0
                : Date.now() + (minutes * 60 * 1000)

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

        if (
            index < 1 ||
            index > 6
        ) {
            root._changingPreset = false
            return
        }

        const seconds =
            index === 6
                ? -1
                : Number(root.presets[index]) * 60

        root.startDetachedInhibitor(seconds)

        // Keep _changingPreset true long enough for the detached process
        // to appear in systemd-inhibit --list.
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

    // ─────────────────────────────────────────────────────────────────────────
    // Right-click cycling
    // ─────────────────────────────────────────────────────────────────────────

    function cyclePreset() {
        let next = root.presetIndex + 1

        if (next > 6)
            next = 0

        root.setPreset(next)
    }

    function selectPreset(index) {
        root.setPreset(index)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Startup
    // ─────────────────────────────────────────────────────────────────────────

    Component.onCompleted: {
        root.nowMs = Date.now()
        root.refreshState()
    }
}

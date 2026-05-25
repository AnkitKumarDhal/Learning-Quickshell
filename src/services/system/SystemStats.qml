pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.src.state

Singleton {
    id: root

    // ── CPU ───────────────────────────────────────────────────────────────────
    property real cpuUsage: 0.0
    property var  _cpuPrev: ({})

    // ── Memory ────────────────────────────────────────────────────────────────
    property real memUsage: 0.0   // 0.0 - 1.0
    property real memUsedGb:  0.0
    property real memTotalGb: 0.0

    // ── GPU ───────────────────────────────────────────────────────────────────
    property real gpuUsage: 0.0
    property bool hasGpu:   false

    // ── Disk ──────────────────────────────────────────────────────────────────
    // Array of { mount, used, total }
    property var diskPartitions: []

    // ── Network ───────────────────────────────────────────────────────────────
    property string activeInterface: ""
    property real   netUpRate:    0.0
    property real   netDownRate:  0.0
    property var    netUpHistory:   []
    property var    netDownHistory: []
    property var    _netPrev: ({})

    readonly property int maxNetHistory: 60

    // ── Temperature ───────────────────────────────────────────────────────────
    property int temperature: 0

    // ── Helpers ───────────────────────────────────────────────────────────────
    function formatBytes(bps) {
        if (bps >= 1e9) return (bps / 1e9).toFixed(1) + " GB/s"
        if (bps >= 1e6) return (bps / 1e6).toFixed(1) + " MB/s"
        if (bps >= 1e3) return (bps / 1e3).toFixed(1) + " KB/s"
        return bps.toFixed(0) + " B/s"
    }

    // ── Combined stats reader (single process call for CPU+Mem+Net) ──────────
    Process {
        id: statsProc
        command: ["sh", "-c", "cat /proc/stat /proc/meminfo /proc/net/dev"]
        running: false

        stdout: SplitParser {
            property string _section: ""
            property int _memTotal: 0
            property int _memAvailable: 0
            property var _netCache: ({})

            onRead: (line) => {
                if (line.startsWith("cpu ")) {
                    _section = "cpu"
                    const parts = line.slice(4).trim().split(/\s+/).map(Number)
                    const idle  = parts[3] + parts[4]
                    const total = parts.reduce((a, b) => a + b, 0)
                    const prev  = root._cpuPrev
                    const dIdle  = idle  - (prev.idle  || idle)
                    const dTotal = total - (prev.total || total)
                    root._cpuPrev = { idle, total }
                    root.cpuUsage = dTotal > 0
                        ? Math.min((1.0 - dIdle / dTotal), 1.0)
                        : 0.0
                }
                else if (line.startsWith("MemTotal:")) {
                    _section = "mem"
                    _memTotal = parseInt(line.split(/\s+/)[1])
                }
                else if (line.startsWith("MemAvailable:") && _section === "mem") {
                    const available = parseInt(line.split(/\s+/)[1])
                    const usedKb    = _memTotal - available
                    root.memTotalGb = _memTotal   / 1024 / 1024
                    root.memUsedGb  = usedKb      / 1024 / 1024
                    root.memUsage   = _memTotal > 0 ? usedKb / _memTotal : 0
                }
                else if (line.match(/^\s*\w+:/)) {
                    // Network section
                    const m = line.match(/^\s*(\w+):\s+(\d+).*\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)/)
                    if (!m) return
                    const iface = m[1]
                    if (iface === "lo" || iface.startsWith("vir") ||
                        iface.startsWith("docker") || iface.startsWith("br-")) return

                    const rx = parseInt(m[2])
                    const tx = parseInt(m[4])
                    _netCache[iface] = { rx, tx }
                }
            }
        }

        onExited: {
            // Process network deltas
            let bestRate = 0
            let bestIface = ""
            let bestDown = 0
            let bestUp = 0

            for (const [iface, curr] of Object.entries(_netCache)) {
                const prev = root._netPrev[iface]
                if (prev) {
                    const downRate = Math.max(0, curr.rx - prev.rx)
                    const upRate   = Math.max(0, curr.tx - prev.tx)
                    const total    = downRate + upRate

                    if (total > bestRate) {
                        bestRate = total
                        bestIface = iface
                        bestDown = downRate
                        bestUp = upRate
                    }
                }
                root._netPrev[iface] = curr
            }

            if (bestIface) {
                root.activeInterface = bestIface
                root.netDownRate = bestDown
                root.netUpRate = bestUp

                // Update history
                let dHist = root.netDownHistory.slice()
                let uHist = root.netUpHistory.slice()
                dHist.push(bestDown)
                uHist.push(bestUp)
                if (dHist.length > root.maxNetHistory) dHist.shift()
                if (uHist.length > root.maxNetHistory) uHist.shift()
                root.netDownHistory = dHist
                root.netUpHistory = uHist
            } else if (bestRate === 0 && root._netPrev._bestRate) {
                // Hysteresis reset
                root._netPrev._bestRate = 0
            }
            root._netPrev._bestRate = bestRate
        }
    }

    // ── GPU polling ───────────────────────────────────────────────────────────
    // Checks for AMD gpu_busy_percent. If file doesn't exist, hasGpu = false.
    Process {
        id: gpuCheckProc
        command: ["sh", "-c",
            "f=$(ls /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1); " +
            "[ -n \"$f\" ] && echo $f || echo NONE"]
        running: true

        stdout: SplitParser {
            onRead: (line) => {
                const path = line.trim()
                if (path === "NONE" || path === "") {
                    root.hasGpu = false
                } else {
                    root.hasGpu    = true
                    gpuReadProc.command = ["cat", path]
                }
            }
        }
    }

    Process {
        id: gpuReadProc
        command: []
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                const v = parseInt(line.trim())
                if (!isNaN(v)) root.gpuUsage = v / 100.0
            }
        }
    }

    // ── Disk polling ──────────────────────────────────────────────────────────
    // df -B1 excludes tmpfs/devtmpfs/overlay/squashfs
    Process {
        id: diskProc
        command: ["sh", "-c",
            "df -B1 --output=target,used,size -x tmpfs -x devtmpfs -x overlay -x squashfs " +
            "| tail -n +2"]
        running: false

        property var _diskLines: []

        stdout: SplitParser {
            onRead: (line) => {
                const parts = line.trim().split(/\s+/)
                if (parts.length < 3) return
                const mount = parts[0]
                const used  = parseInt(parts[1])
                const total = parseInt(parts[2])
                if (isNaN(used) || isNaN(total) || total === 0) return

                // Only show root and physical mounts (skip snap, boot etc.)
                const skip = ["/boot", "/boot/efi", "/snap", "/sys/firmware/efi/efivars", "/.snapshots", "/var/cache", "/home", "/var/log"]
                if (skip.some(s => mount.startsWith(s))) return

                diskProc._diskLines.push({ mount, used, total })
            }
        }

        onExited: {
            root.diskPartitions = diskProc._diskLines.slice()
            diskProc._diskLines = []
        }
    }

    // ── Temperature polling ───────────────────────────────────────────────────
    Process {
        id: tempProc
        command: ["sh", "-c",
            "cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                const v = parseInt(line.trim())
                if (!isNaN(v)) root.temperature = Math.round(v / 1000)
            }
        }
    }

    // ── Main poll timer — 1s interval ─────────────────────────────────────────
    Timer {
        id: mainTimer
        interval:        1000
        running:         true
        repeat:          true
        triggeredOnStart: true

        onTriggered: {
            statsProc.running = true
            if (Popups.systemOpen) {
                tempProc.running = true
                if (root.hasGpu) gpuReadProc.running = true
            }
        }
    }

    Connections {
        target: Popups
        function onSystemOpenChanged() {
            if (Popups.systemOpen) diskProc.running = true
        }
    }
}

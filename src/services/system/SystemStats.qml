pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

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

    // ── CPU polling ───────────────────────────────────────────────────────────
    Process {
        id: cpuProc
        command: ["cat", "/proc/stat"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                const m = line.match(/^cpu\s+(.+)/)
                if (!m) return
                const parts = m[1].trim().split(/\s+/).map(Number)
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
        }
    }

    // ── Memory polling ────────────────────────────────────────────────────────
    Process {
        id: memProc
        command: ["cat", "/proc/meminfo"]
        running: false

        stdout: SplitParser {
            property int _total: 0

            onRead: (line) => {
                const val = parseInt(line.split(/\s+/)[1])
                if      (line.startsWith("MemTotal:"))     _total = val
                else if (line.startsWith("MemAvailable:")) {
                    const usedKb      = _total - val
                    root.memTotalGb   = _total   / 1024 / 1024
                    root.memUsedGb    = usedKb   / 1024 / 1024
                    root.memUsage     = _total > 0 ? usedKb / _total : 0
                }
            }
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
                const skip = ["/boot", "/boot/efi", "/snap"]
                if (skip.some(s => mount.startsWith(s))) return

                diskProc._diskLines.push({ mount, used, total })
            }
        }

        onExited: {
            root.diskPartitions = diskProc._diskLines.slice()
            diskProc._diskLines = []
        }
    }

    // ── Network polling ───────────────────────────────────────────────────────
    Process {
        id: netProc
        command: ["cat", "/proc/net/dev"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                const m = line.match(/^\s*(\w+):\s+(\d+).*\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)/)
                if (!m) return
                const iface = m[1]

                // Skip loopback and virtual interfaces
                if (iface === "lo" || iface.startsWith("vir") ||
                    iface.startsWith("docker") || iface.startsWith("br-")) return

                const rx = parseInt(m[2])
                const tx = parseInt(m[4])

                const prev = root._netPrev[iface]
                if (prev) {
                    const downRate = Math.max(0, rx - prev.rx)
                    const upRate   = Math.max(0, tx - prev.tx)

                    // Use the interface with the highest traffic as active
                    if (downRate + upRate > (root._netPrev._bestRate || 0)) {
                        root._netPrev._bestRate   = downRate + upRate
                        root.activeInterface      = iface
                        root.netDownRate          = downRate
                        root.netUpRate            = upRate

                        // Append to history, cap at maxNetHistory
                        let dHist = root.netDownHistory.slice()
                        let uHist = root.netUpHistory.slice()
                        dHist.push(downRate)
                        uHist.push(upRate)
                        if (dHist.length > root.maxNetHistory) dHist.shift()
                        if (uHist.length > root.maxNetHistory) uHist.shift()
                        root.netDownHistory = dHist
                        root.netUpHistory   = uHist
                    }
                }

                root._netPrev[iface] = { rx, tx }
            }
        }

        onExited: {
            root._netPrev._bestRate = 0  // reset best rate each poll cycle
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
        interval:        1000
        running:         true
        repeat:          true
        triggeredOnStart: true

        onTriggered: {
            cpuProc.running  = true
            memProc.running  = true
            netProc.running  = true
            tempProc.running = true
            if (root.hasGpu) gpuReadProc.running = true

            // Disk polls less frequently — every 10s
            if (_diskTick % 10 === 0) diskProc.running = true
            _diskTick++
        }

        property int _diskTick: 0
    }
}

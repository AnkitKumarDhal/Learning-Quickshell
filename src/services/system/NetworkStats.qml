pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string activeInterface: root._activeInterface
    readonly property real upRate: root._upRate
    readonly property real downRate: root._downRate
    readonly property var upHistory: root._upHistory
    readonly property var downHistory: root._downHistory
    readonly property real totalUpBytes: root._totalUpBytes
    readonly property real totalDownBytes: root._totalDownBytes

    property string _activeInterface: ""
    property real _upRate: 0.0
    property real _downRate: 0.0
    property var _upHistory: []
    property var _downHistory: []
    property var _prev: ({})
    property real _totalUpBytes: 0.0
    property real _totalDownBytes: 0.0

    readonly property int maxHistory: 60

    Process {
        id: netProc
        command: ["sh", "-c",
            "iface=$(awk 'NR > 1 && $2 == \"00000000\" && $3 == \"00000000\" {print $1; exit}' /proc/net/route); " +
            "if [ -z \"$iface\" ]; then " +
            "for d in /sys/class/net/*; do i=${d##*/}; " +
            "[ \"$i\" = lo ] && continue; " +
            "case \"$i\" in vir*|docker*|br-*|veth*|tun*|tap*|wg*|tailscale*) continue;; esac; " +
            "[ \"$(cat $d/operstate 2>/dev/null)\" = up ] || continue; iface=$i; break; done; fi; " +
            "if [ -z \"$iface\" ]; then echo NONE; exit; fi; " +
            "awk -v i=\"$iface\" '$1 == i \":\" {print i, $2, $10; found=1} END {if (!found) print \"NONE\"}' /proc/net/dev"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                const text = line.trim()
                if (!text || text === "NONE") {
                    root._activeInterface = ""
                    root._upRate = 0.0
                    root._downRate = 0.0
                    root._appendHistory(0.0, 0.0)
                    return
                }

                const parts = text.split(/\s+/)
                if (parts.length < 3) return

                const iface = parts[0]
                const rx = Number(parts[1])
                const tx = Number(parts[2])
                if (isNaN(rx) || isNaN(tx)) return

                const now = Date.now()
                const prev = root._prev[iface]
                const changed = root._activeInterface !== iface

                let downRate = 0.0
                let upRate = 0.0

                if (prev && now > prev.time && rx >= prev.rx && tx >= prev.tx) {
                    const elapsed = (now - prev.time) / 1000.0
                    downRate = Math.max(0, (rx - prev.rx) / elapsed)
                    upRate = Math.max(0, (tx - prev.tx) / elapsed)
                }

                if (changed) {
                    downRate = 0.0
                    upRate = 0.0
                }

                root._activeInterface = iface
                root._downRate = downRate
                root._upRate = upRate
                root._totalDownBytes = rx
                root._totalUpBytes = tx
                root._prev[iface] = { rx, tx, time: now }
                root._appendHistory(upRate, downRate)
            }
        }
    }

    function _appendHistory(up, down) {
        let uHist = root._upHistory.slice()
        let dHist = root._downHistory.slice()

        uHist.push(up)
        dHist.push(down)

        if (uHist.length > root.maxHistory) uHist.shift()
        if (dHist.length > root.maxHistory) dHist.shift()

        root._upHistory = uHist
        root._downHistory = dHist
    }

    Timer {
        interval:        1000
        running:         true
        repeat:          true
        triggeredOnStart: true

        onTriggered: netProc.running = true
    }
}

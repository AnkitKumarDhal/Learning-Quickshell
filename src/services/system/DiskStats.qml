pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var partitions: root._partitions

    property var _partitions: []
    property var _currentPartitions: []

    Process {
        id: diskProc
        command: ["sh", "-c",
            "df -B1 --output=target,fstype,used,size -x tmpfs -x devtmpfs -x overlay -x squashfs 2>/dev/null | tail -n +2"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                const match = line.match(/^(.*)\s+(\S+)\s+(\d+)\s+(\d+)\s*$/)
                if (!match) return

                const mount = match[1].trim()
                const fsType = match[2]
                const used = Number(match[3])
                const total = Number(match[4])

                if (!mount || !total || isNaN(used) || isNaN(total)) return
                if (/^(proc|sysfs|devfs|devpts|cgroup.*|pstore|debugfs|securityfs|tracefs|configfs|fusectl|mqueue)$/.test(fsType)) return

                root._currentPartitions.push({ mount, fsType, used, total })
            }
        }

        onExited: {
            root._partitions = root._currentPartitions
                .slice()
                .sort((a, b) => {
                    if (a.mount === "/") return -1
                    if (b.mount === "/") return 1
                    return (b.used / b.total) - (a.used / a.total)
                })
                .slice(0, 6)
            root._currentPartitions = []
        }
    }

    Timer {
        interval:        10000
        running:         true
        repeat:          true
        triggeredOnStart: true

        onTriggered: diskProc.running = true
    }
}

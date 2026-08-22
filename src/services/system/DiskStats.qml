pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var partitions: root._partitions

    property var _partitions: []

    Process {
        id: diskProc
        command: ["sh", "-c",
            "lsblk -J -b -o NAME,TYPE,FSTYPE,LABEL,PARTLABEL,SIZE,FSUSED,FSAVAIL,FSUSE%,MOUNTPOINTS -e 1,7,11 2>/dev/null | tr -d '\\n'"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                try {
                    const data = JSON.parse(line)
                    const devices = []

                    function collect(nodes) {
                        for (const node of (nodes || [])) {
                            const type = node.type || ""
                            const name = node.name || ""
                            const fsUse = node["fsuse%"] || ""
                            const size = Number(node.size || 0)
                            const fsUsed = Number(node.fsused || 0)
                            const fsAvail = Number(node.fsavail || 0)

                            const ignored =
                                name.startsWith("zram") ||
                                name.startsWith("loop") ||
                                type === "rom" ||
                                type === "ram"

                            if (!ignored && size > 0 && fsUse !== "") {
                                const percentage = parseInt(String(fsUse).replace("%", ""))

                                if (!isNaN(percentage)) {
                                    let mountPoint = ""

                                    if (Array.isArray(node.mountpoints) && node.mountpoints.length > 0)
                                        mountPoint = node.mountpoints.find(point => point && point !== "null") || ""

                                    devices.push({
                                        name,
                                        type,
                                        fsType: node.fstype || "",
                                        size,
                                        used: fsUsed,
                                        available: fsAvail,
                                        percentage,
                                        mountPoint
                                    })
                                }
                            }

                            if (node.children)
                                collect(node.children)
                        }
                    }

                    collect(data.blockdevices)

                    root._partitions = devices
                        .sort((a, b) => {
                            if (a.mountPoint === "/" && b.mountPoint !== "/") return -1
                            if (b.mountPoint === "/" && a.mountPoint !== "/") return 1
                            return b.percentage - a.percentage
                        })
                        .slice(0, 6)
                } catch (error) {
                    root._partitions = []
                }
            }
        }
    }

    function refresh() {
        if (!diskProc.running)
            diskProc.running = true
    }
}

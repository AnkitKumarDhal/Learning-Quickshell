pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var temperatures: root._temperatures
    readonly property var displayTemperatures: root._displayTemperatures
    readonly property int primaryTemperature: root._primaryTemperature

    property var _temperatures: []
    property var _displayTemperatures: []
    property int _primaryTemperature: 0
    property var _currentTemperatures: []

    Process {
        id: tempProc
        command: ["sh", "-c",
            "for f in /sys/class/hwmon/hwmon*/temp*_input; do " +
            "[ -r $f ] || continue; " +
            "d=${f%/*}; n=${f##*/}; idx=${n#temp}; idx=${idx%_input}; " +
            "label=$(cat $d/temp${idx}_label 2>/dev/null); " +
            "[ -n \"$label\" ] || label=$(cat $d/name 2>/dev/null); " +
            "value=$(cat $f 2>/dev/null); " +
            "[ -n \"$value\" ] && echo \"$label|$value\"; " +
            "done"]
        running: false

        stdout: SplitParser {
            onRead: (line) => {
                const parts = line.trim().split("|")
                if (parts.length < 2) return

                const value = parseInt(parts[parts.length - 1])
                const name = parts.slice(0, -1).join("|").trim() || "Temperature"
                if (isNaN(value)) return

                const celsius = value > 1000 ? value / 1000 : value
                if (celsius < 0 || celsius > 150) return

                root._currentTemperatures.push({
                    name,
                    value: Math.round(celsius)
                })
            }
        }

        onExited: {
            const unique = []
            const seen = ({})

            for (const item of root._currentTemperatures) {
                const key = item.name + ":" + item.value
                if (seen[key]) continue
                seen[key] = true
                unique.push(item)
            }

            root._temperatures = unique

            const interesting = ["cpu", "package", "tctl", "tdie", "core", "gpu", "edge", "hotspot", "nvme"]
            const selected = unique.filter(item => {
                const name = item.name.toLowerCase()
                return interesting.some(word => name.includes(word))
            })

            root._displayTemperatures = selected.concat(unique)
                .filter((item, index, array) => array.findIndex(other => other.name === item.name) === index)
                .slice(0, 4)

            root._primaryTemperature = 0

            for (const item of unique) {
                const name = item.name.toLowerCase()
                if (name.includes("cpu") || name.includes("package") ||
                    name.includes("tctl") || name.includes("tdie")) {
                    root._primaryTemperature = item.value
                    break
                }
            }

            if (root._primaryTemperature === 0 && unique.length > 0)
                root._primaryTemperature = unique[0].value

            root._currentTemperatures = []
        }
    }

    Timer {
        interval:        3000
        running:         true
        repeat:          true
        triggeredOnStart: true

        onTriggered: {
            root._currentTemperatures = []
            tempProc.running = true
        }
    }
}

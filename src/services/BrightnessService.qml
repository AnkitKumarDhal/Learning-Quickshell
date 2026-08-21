pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int brightness: 0
    property bool available: false
    property bool setting: false

    Timer {
        id: refreshTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Process {
        id: readProcess
        stdout: StdioCollector { onStreamFinished: root._parse(this.text) }
        stderr: StdioCollector {}
    }

    Process {
        id: setProcess
        onStarted: root.setting = true
        onExited: {
            root.setting = false
            root.refresh()
        }
    }

    function refresh() {
        if (readProcess.running) return
        readProcess.exec({
            command: [
                "brightnessctl",
                "-m",
                "-c",
                "backlight"
            ]
        })
    }

    function _parse(output) {
        const lines = output
            .split(/\r?\n/)
            .map(line => line.trim())
            .filter(line => line.length > 0)

        if (lines.length === 0) {
            root.available = false
            return
        }

        const fields = lines[0].split(",")

        if (fields.length < 4) {
            root.available = false
            return
        }

        const value = Number(String(fields[3]).replace("%", ""))

        if (!Number.isFinite(value)) {
            root.available = false
            return
        }

        root.brightness = Math.max(0, Math.min(100, Math.round(value)))
        root.available = true
    }

    function setBrightness(percent) {
        if (!root.available || setProcess.running) return

        const value = Math.max(1, Math.min(100, Math.round(Number(percent))))

        setProcess.exec({
            command: [
                "brightnessctl",
                "-q",
                "-c",
                "backlight",
                "set",
                value + "%"
            ]
        })
    }

    Component.onCompleted: root.refresh()
}

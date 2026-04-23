import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    property int usage: 0
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

    // 1. "Glass" Pill Styling
    color: Qt.alpha(Theme.bg, 0.5)
    // Very transparent background
    radius: 10
    // Rounded corners
    border.color: Qt.alpha(Theme.fg, 0.2)
    // Subtle, faint border
    border.width: 1
    // 2. Padding/Sizing
    implicitWidth: cpuLabel.implicitWidth + 24
    implicitHeight: 24

    Text {
        id: cpuLabel

        anchors.centerIn: parent
        text: "CPU " + root.usage + "%"
        color: Theme.color1 // Keep the Pywal color for the text

        font {
            family: "JetBrainsMono Nerd Font"
            pixelSize: 13
            bold: true
        }

    }

    Process {
        id: cpuProc

        command: ["sh", "-c", "head -1 /proc/stat"]

        stdout: SplitParser {
            onRead: (data) => {
                var p = data.trim().split(/\s+/);
                var idle = parseInt(p[4]) + parseInt(p[5]);
                var total = p.slice(1, 8).reduce((a, b) => {
                    return a + parseInt(b);
                }, 0);
                if (lastCpuTotal > 0)
                    usage = Math.round(100 * (1 - (idle - lastCpuIdle) / (total - lastCpuTotal)));

                lastCpuTotal = total;
                lastCpuIdle = idle;
            }
        }

    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: cpuProc.running = true
        Component.onCompleted: cpuProc.running = true
    }

}

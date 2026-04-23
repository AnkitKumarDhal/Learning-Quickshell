import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    property int usage: 0

    // 1. "Glass" Pill Styling (matching your CPU widget)
    color: Qt.alpha(Theme.bg, 0.5)
    radius: 10
    border.color: Qt.alpha(Theme.fg, 0.2)
    border.width: 1
    
    // 2. Padding/Sizing
    implicitWidth: memLabel.implicitWidth + 24
    implicitHeight: 24

    Text {
        id: memLabel
        anchors.centerIn: parent
        text: "MEM " + root.usage + "%"
        color: Theme.color6 // Using Pywal color6 for Memory
        font {
            family: "JetBrainsMono Nerd Font"
            pixelSize: 13
            bold: true
        }
    }

    Process {
        id: memProc
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: (data) => {
                var parts = data.trim().split(/\s+/);
                var total = parseInt(parts[1]);
                var used = parseInt(parts[2]);
                root.usage = Math.round(100 * used / total);
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: memProc.running = true
        Component.onCompleted: memProc.running = true
    }
}

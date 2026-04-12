import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root

    // Theme Properties
    property color colActive: "#89b4fa"
    property color colUsed: "#7f849c"
    property color colEmpty: "#313244"
    property color colBg: "#1a090a"
    property color colFg: "#f4eac0"

    property color color0: "#1a090a";
    property color color1: "#DC5438";
    property color color2: "#9D3A41";
    property color color3: "#D55444";
    property color color4: "#EC7046";
    property color color5: "#F99850";
    property color color6: "#FBCB62";
    property color color7: "#f4eac0";
    property color color8: "#aaa386";
    property color color9: "#DC5438";
    property color color10: "#9D3A41";
    property color color11: "#D55444";
    property color color12: "#EC7046";
    property color color13: "#F99850";
    property color color14: "#FBCB62";
    property color color15: "#f4eac0";

    property string fontFamily: "JetBrainsMono Nerd Font"

    // System Data
    property int cpuUsage: 0
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

    property int memUsage: 0

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 30
    color: "#1e1e2e"

    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]

        stdout: SplitParser {
            onRead: data => {
                var p = data.trim().split(/\s+/)
                var idle = parseInt(p[4]) + parseInt(p[5])
                var total = p.slice(1, 8).reduce((a,b) => a + parseInt(b), 0)
                if (lastCpuTotal > 0) {
                    cpuUsage = Math.round(100 * (1 - (idle - lastCpuIdle) / (total - lastCpuTotal)))
                }
                lastCpuTotal = total
                lastCpuIdle = idle
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: memProc
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(/\s+/)
                var total = parseInt(parts[1])
                var used = parseInt(parts[2])
                memUsage = Math.round(100 * used / total)
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
        } 
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 5

        Repeater {
            model: 10
            delegate: Text {
                property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                property bool active: Hyprland.focusedWorkspace?.id === (index + 1)

                text : index + 1
                color: active ? root.colActive : ws ? root.colUsed : root.colEmpty
                font { pixelSize: 18; bold: active }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace" + (index + 1))
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            text: "CPU: " + cpuUsage + "%"
            color: root.color1
            font { family: root.fontFamily; pixelSize: 18; bold: true }
        }

        Rectangle {
            width: 10
            height: parent.height * 0.6
            color: "#1e1e2e"
        } 

        Text {
            text: "MEM: " + memUsage + "%"
            color: root.color6
            font { family: root.fontFamily; pixelSize: 18; bold: true }
        }
    }


}

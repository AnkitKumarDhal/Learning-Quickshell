import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import "./components"

PanelWindow {
    id: root
    property string fontFamily: "JetBrainsMono Nerd Font"

    // System Data
    property int memUsage: 0

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 30
    color: "transparent"

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
            memProc.running = true
        } 
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 8 // Gap between pills

        Repeater {
            model: 10
            delegate: Text {
                property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                property bool active: Hyprland.focusedWorkspace?.id === (index + 1)

                text : index + 1
                color: active ? Theme.color4 : ws ? Theme.fg : Theme.color8
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

        CpuWidget {}

        Rectangle {
            width: 10
            height: parent.height * 0.6
            color: Theme.bg
        } 

        Text {
            text: "MEM: " + memUsage + "%"
            color: Theme.color6
            font { family: root.fontFamily; pixelSize: 18; bold: true }
        }
    }
}
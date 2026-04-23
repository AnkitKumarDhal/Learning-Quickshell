import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Rectangle {
    id: root

    // "Glass" Pill Styling
    color: Qt.alpha(Theme.bg, 0.5)
    radius: 10
    border.color: Qt.alpha(Theme.fg, 0.2)
    border.width: 1
    
    // Padding/Sizing
    implicitWidth: wsRow.implicitWidth + 24
    implicitHeight: 24

    RowLayout {
        id: wsRow
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: 10
            delegate: Text {
                property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                property bool active: Hyprland.focusedWorkspace?.id === (index + 1)

                text: index + 1
                color: active ? Theme.color4 : ws ? Theme.fg : Theme.color8
                font { 
                    family: "JetBrainsMono Nerd Font"
                    pixelSize: 14
                    bold: active 
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace" + (index + 1))
                }
            }
        }
    }
}

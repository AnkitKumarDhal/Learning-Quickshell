import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root
    
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    property int maxWs: {
        let max = 5;
        for (let i = 0; i < Hyprland.workspaces.length; i++) {
            if (Hyprland.workspaces[i].id > max) {
                max = Hyprland.workspaces[i].id;
            }
        }

        if (Hyprland.focusedWorkspace?.id > max) {
            max = Hyprland.focusedWorkspace.id;
        }

        return max;
    }

    Pill {
        id: pill
        anchors.fill: parent

        Row {
            spacing: 6

            Repeater {
                model: root.maxWs

                Rectangle {
                    property int wsId: index + 1
                    property bool isActive: Hyprland.focusedWorkspace?.id === wsId

                    width: isActive ? 20 : 8
                    height: 8
                    radius: 4

                    color: isActive ? Colors.accent : Colors.pillBorder

                    Behavior on width {
                        NumberAnimation { duration: 200; easing.type: Easing.OutQuint }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -5

                        onClicked: {
                            Hyprland.dispatch("workspace" + " " + wsId)
                        }
                    }
                }
            }
        }
    }
}

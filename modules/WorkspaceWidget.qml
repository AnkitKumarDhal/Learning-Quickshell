import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root
    
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    Pill {
        id: pill
        anchors.fill: parent

        Row {
            spacing: 6

            Repeater {
                model: 5

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
                }
            }
        }
    }
}

import "../../../settings"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Rectangle {
    id: workspaces

    implicitWidth: layout.implicitWidth + 28
    implicitHeight: 30
    radius: 15
    color: Colors.background

    Row {
        id: layout

        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: Hyprland.workspaces

            delegate: Rectangle {
                required property var modelData

                visible: modelData.id > 0
                width: modelData.active ? 30 : 12
                height: 12
                radius: 6
                color: modelData.active ? Colors.primary : Colors.outline

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        modelData.activate();
                    }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutExpo
                    }

                }

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }

                }

            }

        }

    }

}

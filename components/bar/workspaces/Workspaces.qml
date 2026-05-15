import QtQuick
import Quickshell
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../../settings"

Rectangle {
    id: workspaces

    implicitWidth: layout.implicitWidth + 32
    implicitHeight: 30
    radius: 15
    color: Colors.background

    property int dotCount: {
        let highest = 3;
        let wss = Hyprland.workspaces.values;

        for (let i = 0; i < wss.length; i++) {
            if (wss[i].id > highest) {
                highest = wss[i].id;
            }
        }
        return highest;
    }

    Row {
        id: layout

        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: workspaces.dotCount
            delegate: Rectangle {
                readonly property int wsId: index + 1
                property var hyprWs: {
                    let wss = Hyprland.workspaces.values;
                    for (let i = 0; i < wss.length; i++) {
                        if (wss[i].id === wsId) {
                            return wss[i];
                        }
                    }
                    return null;
                }

                readonly property bool isActive: hyprWs ? hyprWs.active : false
                readonly property bool isOccupied: hyprWs !== null

                width: isActive ? 30 : 12
                height: 12
                radius: 6
                color: isActive ? Colors.primary : Colors.outline
                opacity: (isActive || isOccupied) ? 1.0 : 0.3

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsId + " })")
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

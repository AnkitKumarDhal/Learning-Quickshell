import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "modules"

PanelWindow {
    id: barWindow

    implicitHeight: 40
    exclusiveZone: implicitHeight
    color: "transparent"

    //Layer Shell config
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        left: true
        right: true
        top: true
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 0

        //Left
        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            WorkspaceWidget {}
        }

        // Spacer
        Item { Layout.fillWidth: true }

        //Center
        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            ClockWidget { parentWindow: barWindow }
        }

        // Spacer
        Item { Layout.fillWidth: true }

        // Right
        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            Pill {
                Text {
                    text: "Right"
                    color: "white"
                    font.pixelSize: 14
                }
            }
        }
    }
}

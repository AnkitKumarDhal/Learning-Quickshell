import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "modules"

PanelWindow {
    id: root

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

        Rectangle {
            width: 60
            height: 24
            radius: 12
            color: Colors.color8
        }

        //Left
        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Left"
                color: "white"
                font.pixelSize: 14
            }

        }

        // Spacer
        Item {
            Layout.fillWidth: true
        }

        //Center
        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Center"
                color: "white"
                font.pixelSize: 14
            }

        }

        // Spacer
        Item {
            Layout.fillWidth: true
        }

        // Right
        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Right"
                color: "white"
                font.pixelSize: 14
            }

        }

    }

}

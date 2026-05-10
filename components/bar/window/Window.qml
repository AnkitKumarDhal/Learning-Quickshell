import QtQuick
import Quickshell
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../../settings"

Rectangle {
    id: windowPill

    property string windowTitle: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "Desktop"

    implicitWidth: layout.implicitWidth + 32
    implicitHeight: 30
    radius: height / 2
    color: Colors.background

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 10

        Text {
            text: "󰣇"
            color: Colors.primary
            font.pointSize: 14
        }

        Text {
            text: windowPill.windowTitle
            color: Colors.primary
            font.pointSize: 11
            font.bold: true

            elide: Text.ElideRight
            Layout.maximumWidth: 350
        }
    }
}

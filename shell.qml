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

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 30
    color: "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 8

        WorkspacesWidget {}

        Item {
            Layout.fillWidth: true
        }

        CpuWidget {}

        MemWidget {}
    }
}
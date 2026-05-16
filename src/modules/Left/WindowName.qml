import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.src.components
import qs.src.theme

PillBase {
    id: root

    hoverExpand: false  // spec says clicking does nothing, no hover needed

    property string windowTitle: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "Desktop"

    Text {
        text: root.windowTitle
        color: Colors.primary
        font.pointSize: 11
        font.bold: true
        font.family: Fonts.font
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 350)
        anchors.verticalCenter: parent.verticalCenter
    }
}

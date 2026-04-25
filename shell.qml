import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

import qs.Osd
import qs.colors
import qs.core
import qs.services


ShellRoot {
    id: root

    PanelWindow {
        id: rootPanel
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: screen.width
        implicitHeight: screen.height

        anchors {
            top: true
            bottom: true
            right: true
            left: true
        }

        color: "transparent"
        focusable: false

        OsdWindow {}
    }
}

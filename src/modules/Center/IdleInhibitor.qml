import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.src.components
import qs.src.theme
import qs.src.state

PillBase {
    id: root

    hoverExpand: true

    WaylandIdleInhibitor {
        id: inhibitor
        active: false
    }

    property bool inhibiting: inhibitor.active

    Text {
        text: root.inhibiting ? "󰛨" : "󰾪"
        color: root.inhibiting ? Colors.tertiary : Colors.primary
        font.pointSize: 12
        font.family: Fonts.font
        verticalAlignment: Text.AlignVCenter

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    onClicked: {
        inhibitor.active = !inhibitor.active
        Popups.idleInhibitorOpen = !Popups.idleInhibitorOpen
    }
}

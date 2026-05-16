import QtQuick
import Quickshell
import Quickshell.Io
import qs.src.components
import qs.src.theme
import qs.src.state

PillBase {
    id: root

    hoverExpand: true

    property bool inhibiting: false

    Process {
        id: inhibitProc
        command: ["systemd-inhibit",
                  "--what=idle",
                  "--who=Quickshell",
                  "--why=User requested",
                  "--mode=block",
                  "sleep", "infinity"]
        running: false

        onExited: root.inhibiting = false
    }

    Text {
        text:  root.inhibiting ? "󰛨" : "󰾪"
        color: root.inhibiting ? Colors.tertiary : Colors.primary
        font.pixelSize: 12
        font.family:    Fonts.font
        verticalAlignment: Text.AlignVCenter

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    onClicked: {
        if (root.inhibiting) {
            inhibitProc.running  = false
        } else {
            inhibitProc.running  = true
        }
        root.inhibiting          = !root.inhibiting
        Popups.idleInhibitorOpen = !Popups.idleInhibitorOpen
    }
}

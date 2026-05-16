import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.src.state

// Transparent fullscreen overlay that dismisses all popups when:
//   - User clicks anywhere outside a popup
//   - User presses Escape
//
// Only active when at least one popup is open.

PanelWindow {
    id: root

    color: "transparent"

    anchors {
        top:    true
        left:   true
        right:  true
        bottom: true
    }

    // Carve out the bar and notch regions so clicks pass through to the bar
    mask: Region {
        // Main screen area below the bar
        Region {
            x:      0
            y:      Theme.barHeight
            width:  root.width
            height: root.height - Theme.barHeight
        }
        // Gap between left notch and center
        Region {
            x:      ShellState.topBarLWidth
            y:      0
            width:  (root.width - ShellState.topBarCWidth) / 2 - ShellState.topBarLWidth
            height: Theme.barHeight
        }
        // Gap between center and right notch
        Region {
            x:      (root.width + ShellState.topBarCWidth) / 2
            y:      0
            width:  (root.width - ShellState.topBarCWidth) / 2 - ShellState.topBarRWidth
            height: Theme.barHeight
        }
    }

    // Don't push windows away
    exclusionMode: ExclusionMode.Ignore

    // Only grab input when a popup is open
    visible: Popups.anyOpen

    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Click outside → close all
    MouseArea {
        anchors.fill: parent
        onClicked:    Popups.closeAll()
    }

    // Escape → close all
    Item {
        anchors.fill: parent
        focus:        root.visible

        Keys.onEscapePressed: Popups.closeAll()
    }

    // Workspace/window change → close all
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const triggers = ["workspace", "activemonitor", "activespecial", "openwindow"]
            if (triggers.includes(event.name))
                Popups.closeAll()
        }
    }
}

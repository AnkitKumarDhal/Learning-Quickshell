import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.src.theme
import qs.src.state
import qs.src.services

// Fixed-size PanelWindow — surface never resizes, only content animates
PanelWindow {
    id: root

    property var screen

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        bottom: true
        right:  true
    }

    // Fixed dimensions — large enough for max 5 toasts stacked
    // Never bind these to content or the surface will jump
    implicitWidth:  380
    implicitHeight: 500

    mask: Region {
        Region {
            x: root.width - 360 - 12
            y: root.height - 2 - (NotificationService.activeToasts.length * 88)
            width: 360
            height: NotificationService.activeToasts.length * 88
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay

    // ── Toast stack ───────────────────────────────────────────────────────────
    // Toasts anchor to the bottom, stack upward
    // New toast slides in from the right, existing ones animate upward

    Item {
        anchors {
            bottom: parent.bottom
            right:  parent.right
            bottomMargin: 12
            rightMargin:  12
        }
        width:  360
        height: parent.height - 24

        Repeater {
            id: toastRepeater
            model: NotificationService.activeToasts

            delegate: ToastItem {
                required property var modelData
                required property int index

                notifId:     modelData
                toastIndex:  index
                totalToasts: NotificationService.activeToasts.length
            }
        }
    }
}

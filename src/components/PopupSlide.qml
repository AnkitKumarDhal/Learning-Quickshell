import QtQuick
import qs.src.state

// Slide-in/out animation container for all popups.
//
// Click-open usage:
//   PopupSlide {
//       edge: "right"
//       open: Popups.systemOpen
//       // content
//   }
//
// Hover-open usage:
//   PopupSlide {
//       edge: "right"
//       open:            Popups.audioOpen
//       hoverEnabled:    true
//       triggerHovered:  someTriggerRegion.containsMouse
//       onCloseRequested: Popups.audioOpen = false
//       // content
//   }
//
// Always bind your PopupWindow.visible to slide.windowVisible

Item {
    id: root

    // ── Required ──────────────────────────────────────────────────────────────
    property string edge:         "top"   // "top" | "bottom" | "left" | "right"
    property bool   open:         false

    // ── Hover-to-open (optional) ──────────────────────────────────────────────
    property bool hoverEnabled:   false
    property bool triggerHovered: false

    // ── Timing ───────────────────────────────────────────────────────────────
    property int slideDuration:   Popups.slideDuration
    property int closeDelay:      Popups.hoverCloseDelay

    // ── Output ────────────────────────────────────────────────────────────────
    // Bind your PopupWindow.visible to this
    property bool windowVisible:  false

    signal closeRequested()

    // ── Internal ──────────────────────────────────────────────────────────────
    property bool _selfHovered:   false

    readonly property bool _effectiveOpen:
        open || (hoverEnabled && (triggerHovered || _selfHovered))

    default property alias content: inner.data

    clip: true

    on_EffectiveOpenChanged: {
        if (_effectiveOpen) {
            hoverCloseTimer.stop()
            windowVisible = true
        } else {
            if (hoverEnabled)
                hoverCloseTimer.restart()
            else
                slideCloseTimer.restart()
        }
    }

    // Wait for slide animation to finish before hiding the window
    Timer {
        id:          slideCloseTimer
        interval:    root.slideDuration + 20
        onTriggered: root.windowVisible = false
    }

    // Hover leave — wait then emit closeRequested
    Timer {
        id:          hoverCloseTimer
        interval:    root.closeDelay
        onTriggered: {
            if (!root.triggerHovered && !root._selfHovered) {
                root.windowVisible = false
                root.closeRequested()
            }
        }
    }

    // ── Sliding item ──────────────────────────────────────────────────────────
    Item {
        id:     inner
        width:  parent.width
        height: parent.height

        x: root._effectiveOpen ? 0 : (root.edge === "left"  ? -width :
                                       root.edge === "right" ?  width : 0)

        y: root._effectiveOpen ? 0 : (root.edge === "top"    ? -height :
                                       root.edge === "bottom" ?  height : 0)

        Behavior on x { NumberAnimation { duration: root.slideDuration; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: root.slideDuration; easing.type: Easing.OutCubic } }

        HoverHandler {
            onHoveredChanged: root._selfHovered = hovered
        }
    }
}

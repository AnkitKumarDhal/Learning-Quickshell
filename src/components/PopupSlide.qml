import QtQuick
import qs.src.state
import qs.src.theme

Item {
    id: root

    property string edge: "top" // "top" | "bottom" | "left" | "right"
    property bool   open: false

    property bool hoverEnabled:   false
    property bool triggerHovered: false

    property int slideDuration: Theme.slideInDuration
    property int closeDelay:    Theme.hoverCloseDelay

    property bool windowVisible: false

    signal closeRequested()

    property bool _selfHovered: false
    property bool _ready: false

    readonly property bool _effectiveOpen: _ready && ( open || (hoverEnabled && (triggerHovered || _selfHovered)) )

    Component.onCompleted: root._ready = true

    default property alias content: inner.data

    clip: true

    on_EffectiveOpenChanged: {
        if (_effectiveOpen) { hoverCloseTimer.stop(); windowVisible = true }
        else { hoverEnabled ? hoverCloseTimer.restart() : slideCloseTimer.restart() }
    }

    Timer {
        id:          slideCloseTimer
        interval:    root.slideDuration + 20
        onTriggered: root.windowVisible = false
    }

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

    Item {
        id:     inner
        width:  parent.width
        height: parent.height

        x: root._effectiveOpen ? 0 : (root.edge === "left" ? -width : root.edge === "right" ? width : 0)
        y: root._effectiveOpen ? 0 : (root.edge === "top" ? -height : root.edge === "bottom" ? height : 0)

        Behavior on x { NumberAnimation { duration: root.slideDuration; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: root.slideDuration; easing.type: Easing.OutCubic } }

        HoverHandler {
            onHoveredChanged: root._selfHovered = hovered
        }
    }
}

import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    // ── Content ───────────────────────────────────────────────────────────────
    default property alias content: innerLayout.data

    // ── Behaviour flags ───────────────────────────────────────────────────────
    property bool hoverExpand:  true   // +10px width on hover
    property bool hoverEnabled: true   // show bg highlight on hover

    // ── Signals ───────────────────────────────────────────────────────────────
    signal clicked(var mouse)
    signal rightClicked(var mouse)
    signal scrolled(var wheel)

    // ── Geometry ──────────────────────────────────────────────────────────────
    implicitWidth:  innerLayout.implicitWidth + Theme.pillPadding + (hoverExpand && hov.containsMouse ? Theme.hoverWidthGain : 0)
    implicitHeight: Theme.pillHeight
    radius:         Theme.pillRadius
    color:          Colors.background

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.hoverFadeDuration; easing.type: Easing.OutCubic }
    }

    // ── Hover highlight ───────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius:       parent.radius
        color:        Colors.primary
        opacity:      hoverEnabled && hov.containsMouse ? Theme.hoverOpacity : 0
        Behavior on opacity { NumberAnimation { duration: Theme.hoverFadeDuration } }
    }

    // ── Content layout ────────────────────────────────────────────────────────
    RowLayout {
        id: innerLayout
        anchors.centerIn: parent
        spacing: 8
    }

    // ── Input ─────────────────────────────────────────────────────────────────
    MouseArea {
        id:              hov
        anchors.fill:    parent
        hoverEnabled:    true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape:     Qt.PointingHandCursor

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked(mouse)
            else
                root.clicked(mouse)
        }

        onWheel: (wheel) => root.scrolled(wheel)
    }
}

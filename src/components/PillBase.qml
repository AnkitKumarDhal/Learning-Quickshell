import QtQuick
import QtQuick.Layouts
import qs.src.theme

Rectangle {
    id: root

    // ── Content ───────────────────────────────────────────────────────────────
    default property alias contentData: innerLayout.data

    // ── Behaviour Flags ───────────────────────────────────────────────────────
    property bool hoverExpand:  true // +10px width on hover
    property bool hoverEnabled: true // show bg highlight on hover
    property bool mouseEnabled: true

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

    // ── Hover Highlight ───────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius:       parent.radius
        color:        Colors.primary
        opacity:      hoverEnabled && hov.containsMouse ? Theme.hoverOpacity : 0
        
        Behavior on opacity { NumberAnimation { duration: Theme.hoverFadeDuration } }
    }

    // ── Content Layout ────────────────────────────────────────────────────────
    RowLayout {
        id: innerLayout
        anchors.centerIn: parent
        spacing:          8
    }

    // ── Input ─────────────────────────────────────────────────────────────────
    MouseArea {
        id:              hov
        anchors.fill:    parent
        enabled:         root.mouseEnabled
        hoverEnabled:    true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape:     Qt.PointingHandCursor

        onClicked: (mouse) => mouse.button === Qt.RightButton ? root.rightClicked(mouse) : root.clicked(mouse)
        onWheel:   (wheel) => root.scrolled(wheel)
    }
}

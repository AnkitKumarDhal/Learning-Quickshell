import QtQuick
import QtQuick.Layouts
import qs.src.theme

Rectangle {
    id: root

    default property alias contentData: innerLayout.data

    property bool hoverExpand:  true
    property bool hoverEnabled: true
    property bool mouseEnabled: true

    signal clicked(var mouse)
    signal rightClicked(var mouse)
    signal scrolled(var wheel)

    implicitWidth:  innerLayout.implicitWidth + Theme.pillPadding + (hoverExpand && hov.containsMouse ? Theme.hoverWidthGain : 0)
    implicitHeight: Theme.pillHeight
    radius:         Theme.pillRadius
    color:          Colors.background

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.hoverFadeDuration; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius:       parent.radius
        color:        Colors.primary
        opacity:      hoverEnabled && hov.containsMouse ? Theme.hoverOpacity : 0

        Behavior on opacity { NumberAnimation { duration: Theme.hoverFadeDuration } }
    }

    RowLayout {
        id: innerLayout
        anchors.centerIn: parent
        spacing:          8
    }

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

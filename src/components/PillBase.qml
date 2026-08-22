import QtQuick
import QtQuick.Layouts
import qs.src.theme

Rectangle {
    id: root

    default property alias contentData: innerLayout.data

    property bool hoverExpand:  true
    property bool hoverEnabled: true
    property bool mouseEnabled: true
    readonly property bool hovered: hov.containsMouse
    property int horizontalPadding: Theme.pillPadding
    property alias hoverArea: hov
    property alias backgroundData: backgroundContent.data

    signal clicked(var mouse)
    signal rightClicked(var mouse)
    signal scrolled(var wheel)

    implicitWidth:  innerLayout.implicitWidth + horizontalPadding + (hoverExpand && hov.containsMouse ? Theme.hoverWidthGain : 0)
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
        z:            2

        Behavior on opacity { NumberAnimation { duration: Theme.hoverFadeDuration } }
    }

    Item {
        id: backgroundContent
        anchors.fill: parent
        z: 1
    }

    RowLayout {
        id: innerLayout
        anchors.centerIn: parent
        spacing:          8
        z:                3
    }

    MouseArea {
        id:              hov
        anchors.fill:    parent
        enabled:         root.mouseEnabled
        hoverEnabled:    true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape:     Qt.PointingHandCursor
        z:               4

        onClicked: (mouse) => mouse.button === Qt.RightButton ? root.rightClicked(mouse) : root.clicked(mouse)
        onWheel:   (wheel) => root.scrolled(wheel)
    }
}

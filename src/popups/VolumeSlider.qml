import QtQuick
import qs.src.theme

// Horizontal volume slider
// Emits onMoved(value) when user drags or clicks

Item {
    id: root

    property real value: 0.0
    property bool muted: false

    signal moved(real value)

    implicitHeight: 36

    // Track
    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width:  parent.width
        height: 4
        radius: 2
        color:  Colors.surfaceContainerHighest

        // Fill
        Rectangle {
            width:  Math.max(handle.width / 2, track.width * root.value)
            height: parent.height
            radius: parent.radius
            color:  root.muted ? Colors.error : Colors.primary
            Behavior on width { NumberAnimation { duration: 80 } }
            Behavior on color { ColorAnimation  { duration: 120 } }
        }
    }

    // Handle
    Rectangle {
        id: handle
        width:  16
        height: 16
        radius: 8
        color:  root.muted ? Colors.error : Colors.primary
        anchors.verticalCenter: parent.verticalCenter
        x: Math.min(track.width - width, Math.max(0, track.width * root.value - width / 2))

        Behavior on color { ColorAnimation { duration: 120 } }

        // Glow when dragging
        Rectangle {
            anchors.centerIn: parent
            width:   parent.width + 8
            height:  parent.height + 8
            radius:  width / 2
            color:   Colors.primary
            opacity: dragArea.pressed ? 0.2 : 0
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }
    }

    // Input
    MouseArea {
        id:           dragArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor

        function valueFromMouse(mouseX) {
            return Math.max(0.0, Math.min(1.0, mouseX / track.width))
        }

        onPressed:      (mouse) => root.moved(valueFromMouse(mouse.x))
        onPositionChanged: (mouse) => {
            if (pressed) root.moved(valueFromMouse(mouse.x))
        }

        onWheel: (wheel) => {
            root.moved(Math.max(0.0, Math.min(1.0,
                root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }
}

import QtQuick
import Quickshell

Rectangle {
    id: root

    signal clicked()

    default property alias content: container.data

    implicitHeight: 32
    implicitWidth: container.implicitWidth + 28
    radius: height / 2
    // Coloring
    color: mouseArea.containsMouse ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15) : Colors.pillBackground
    border.color: mouseArea.containsMouse ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.5) : Colors.pillBorder
    border.width: 1

    Row {
        id: container

        anchors.centerIn: parent
        spacing: 8
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }

    Behavior on color {
        ColorAnimation {
            duration: 150
        }

    }

    Behavior on border.color {
        ColorAnimation {
            duration: 150
        }

    }

    transform: Translate {
        y: mouseArea.containsMouse ? -2 : 0

        Behavior on y {
            SpringAnimation {
                spring: 3
                damping: 0.2
            }

        }

    }

}

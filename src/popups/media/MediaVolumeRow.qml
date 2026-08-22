import QtQuick
import QtQuick.Layouts
import qs.src.theme

Item {
    id: root

    required property var player

    Layout.preferredWidth: 30
    Layout.preferredHeight: 24

    visible: root.player !== null && root.player.volumeSupported
    property bool expanded: false

    Timer {
        id: hideTimer
        interval: 250
        onTriggered: root.expanded = false
    }

    Rectangle {
        id: sliderPopup

        x: -100
        y: 1
        width: 100
        height: 22
        radius: 11
        color: Colors.surfaceContainerHigh
        border.color: Colors.outlineVariant
        border.width: 1
        opacity: root.expanded ? 1 : 0
        scale: root.expanded ? 1 : 0.92
        transformOrigin: Item.Right
        z: 10

        Behavior on opacity {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutBack
            }
        }

        Item {
            id: sliderContent

            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            property real volume: Math.max(0, Math.min(1, root.player?.volume ?? 0))

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 4
                radius: 2
                color: Colors.surfaceContainerHighest
            }
            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * parent.volume
                height: 4
                radius: 2
                color: Colors.secondary
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width * parent.volume - width / 2
                width: 8
                height: 8
                radius: 4
                color: Colors.secondary
            }
        }
    }

    Loader {
        id: sliderMouseLoader

        active: root.expanded
        x: sliderPopup.x + sliderContent.x
        y: sliderPopup.y + sliderContent.y
        z: 50
        width: sliderContent.width
        height: sliderContent.height

        sourceComponent: Component {
            MouseArea {
                id: sliderMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    hideTimer.stop()
                    root.expanded = true
                }
                onExited: hideTimer.restart()

                function volumeFromX(x) {
                    return Math.max(0, Math.min( x / width, 1))
                }

                onPressed: (mouse) => {
                    if (!root.player) return
                    root.player.volume = volumeFromX(mouse.x)
                }
                onPositionChanged: (mouse) => {
                    if (pressed && root.player) {
                        root.player.volume = volumeFromX(mouse.x)
                    }
                }
            }
        }
    }

    Text {
        id: volumeIcon

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: {
            const volume = root.player?.volume ?? 0

            if (volume <= 0) return "󰝟"
            if (volume < 0.4) return "󰕿"
            if (volume < 0.75) return "󰖀"
            return "󰕾"
        }
        font.family: Fonts.fontM
        font.pointSize: 14
        color: root.expanded ? Colors.primary : Colors.on_SurfaceVariant
        Behavior on color {
            ColorAnimation {
                duration: Theme.hoverFadeDuration
            }
        }
        z: 100
    }

    MouseArea {
        id: iconMouse

        anchors.fill: volumeIcon
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: 110
        onEntered: {
            hideTimer.stop()
            root.expanded = true
        }
        onExited: hideTimer.restart()
        onClicked: {
            if (!root.player) return
            if (root.player.volume <= 0) {
                root.player.volume = 0.5
            } else {
                root.player.volume = 0
            }
        }
    }
}

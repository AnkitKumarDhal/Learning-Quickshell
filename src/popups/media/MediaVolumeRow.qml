import QtQuick
import QtQuick.Layouts
import qs.src.theme

Item {
    id: root

    required property var player

    Layout.preferredWidth: 30
    Layout.preferredHeight: 24

    visible:
        root.player !== null &&
        root.player.volumeSupported

    property bool expanded:
        hoverZone.containsMouse

    /*
     * Covers both the speaker and the popup slider.
     *
     * acceptedButtons: NoButton means it only tracks hover;
     * the actual controls underneath still receive clicks.
     */
    MouseArea {
        id: hoverZone

        x: -100
        y: 0

        width: 130
        height: 28

        hoverEnabled: true

        acceptedButtons:
            Qt.NoButton

        z: -1
    }

    Rectangle {
        id: sliderPopup

        x: -100
        y: 2

        width: 100
        height: 22

        radius: 11

        color:
            Colors.surfaceContainerHigh

        border.color:
            Colors.outlineVariant

        border.width: 1

        opacity:
            root.expanded
            ? 1
            : 0

        scale:
            root.expanded
            ? 1
            : 0.92

        transformOrigin:
            Item.Right

        z: 1

        Behavior on opacity {
            NumberAnimation {
                duration: 140
                easing.type:
                    Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type:
                    Easing.OutBack
            }
        }

        Item {
            anchors.fill: parent

            anchors.leftMargin: 10
            anchors.rightMargin: 10

            property real volume:
                Math.max(
                    0,
                    Math.min(
                        1,
                        root.player?.volume ??
                        0
                    )
                )

            Rectangle {
                anchors.left:
                    parent.left

                anchors.right:
                    parent.right

                anchors.verticalCenter:
                    parent.verticalCenter

                height: 4
                radius: 2

                color:
                    Colors.surfaceContainerHighest
            }

            Rectangle {
                anchors.left:
                    parent.left

                anchors.verticalCenter:
                    parent.verticalCenter

                width:
                    parent.width *
                    parent.volume

                height: 4

                radius: 2

                color:
                    Colors.secondary
            }

            Rectangle {
                anchors.verticalCenter:
                    parent.verticalCenter

                x:
                    parent.width *
                    parent.volume -
                    width / 2

                width: 8
                height: 8

                radius: 4

                color:
                    Colors.secondary
            }

            MouseArea {
                id: sliderMouse

                anchors.fill:
                    parent

                enabled:
                    root.expanded

                hoverEnabled: true

                cursorShape:
                    Qt.PointingHandCursor

                function volumeFromX(x) {
                    return Math.max(
                        0,
                        Math.min(
                            x / width,
                            1
                        )
                    )
                }

                onPressed: (mouse) => {
                    if (root.player) {
                        root.player.volume =
                            volumeFromX(mouse.x)
                    }
                }

                onPositionChanged: (mouse) => {
                    if (
                        pressed &&
                        root.player
                    ) {
                        root.player.volume =
                            volumeFromX(mouse.x)
                    }
                }
            }
        }
    }

    Text {
        id: volumeIcon

        anchors.right:
            parent.right

        anchors.verticalCenter:
            parent.verticalCenter

        text: {
            const volume =
                root.player?.volume ??
                0

            if (volume <= 0)
                return "󰝟"

            if (volume < 0.4)
                return "󰕿"

            if (volume < 0.75)
                return "󰖀"

            return "󰕾"
        }

        font.family:
            Fonts.fontM

        font.pointSize: 14

        color:
            root.expanded
            ? Colors.primary
            : Colors.on_SurfaceVariant

        Behavior on color {
            ColorAnimation {
                duration:
                    Theme.hoverFadeDuration
            }
        }

        z: 2
    }

    MouseArea {
        id: iconMouse

        anchors.fill:
            volumeIcon

        hoverEnabled: true

        cursorShape:
            Qt.PointingHandCursor

        z: 3

        onClicked: {
            if (!root.player)
                return

            if (
                root.player.volume <= 0
            ) {
                root.player.volume = 0.5
            } else {
                root.player.volume = 0
            }
        }
    }
}

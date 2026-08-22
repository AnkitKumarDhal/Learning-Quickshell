import QtQuick
import QtQuick.Layouts
import qs.src.theme

RowLayout {
    id: root

    required property var player

    Layout.fillWidth: true

    spacing: 8

    visible:
        root.player !== null &&
        root.player.volumeSupported

    property bool muted:
        (root.player?.volume ?? 0) <= 0

    Text {
        id: volumeIcon

        text: {
            const volume =
                root.player?.volume ?? 0

            if (volume <= 0)
                return "󰝟"

            if (volume < 0.4)
                return "󰕿"

            if (volume < 0.75)
                return "󰖀"

            return "󰕾"
        }

        font.family: Fonts.fontM
        font.pointSize: 13

        color:
            volumeMouse.containsMouse
            ? Colors.primary
            : Colors.on_SurfaceVariant

        Behavior on color {
            ColorAnimation {
                duration: Theme.hoverFadeDuration
            }
        }
    }

    MouseArea {
        id: volumeMouse

        width: volumeIcon.implicitWidth
        height: volumeIcon.implicitHeight

        hoverEnabled: true

        cursorShape: Qt.PointingHandCursor

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

    Item {
        Layout.fillWidth: true

        Layout.preferredHeight: 18

        property real volume:
            Math.max(
                0,
                Math.min(
                    1,
                    root.player?.volume ?? 0
                )
            )

        property bool hovered:
            sliderMouse.containsMouse

        Rectangle {
            anchors.verticalCenter:
                parent.verticalCenter

            width: parent.width

            height:
                parent.hovered
                ? 5
                : 4

            radius:
                height / 2

            color:
                Colors.surfaceContainerHighest

            Behavior on height {
                NumberAnimation {
                    duration: 120
                }
            }
        }

        Rectangle {
            anchors.left:
                parent.left

            anchors.verticalCenter:
                parent.verticalCenter

            width:
                parent.width *
                parent.volume

            height:
                parent.hovered
                ? 5
                : 4

            radius:
                height / 2

            color: Colors.secondary

            Behavior on width {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 120
                }
            }
        }

        Rectangle {
            anchors.verticalCenter:
                parent.verticalCenter

            x:
                parent.width *
                parent.volume -
                width / 2

            width:
                parent.hovered
                ? 12
                : 8

            height:
                width

            radius:
                width / 2

            color: Colors.secondary

            Behavior on x {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on width {
                NumberAnimation {
                    duration: 120
                }
            }
        }

        MouseArea {
            id: sliderMouse

            anchors.fill: parent

            hoverEnabled: true

            cursorShape: Qt.PointingHandCursor

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
                if (root.player)
                    root.player.volume =
                        volumeFromX(mouse.x)
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

    Text {
        text:
            Math.round(
                (root.player?.volume ?? 0) * 100
            ) + "%"

        color: Colors.on_SurfaceVariant

        font.family: Fonts.font
        font.pointSize: 8

        horizontalAlignment:
            Text.AlignRight

        Layout.preferredWidth: 30
    }
}

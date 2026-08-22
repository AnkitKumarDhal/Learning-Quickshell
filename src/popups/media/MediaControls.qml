import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.src.theme

RowLayout {
    id: root

    required property var player
    required property bool isPlaying

    Layout.fillWidth: true

    spacing: 2

    component IconButton: Item {
        id: button

        property string icon: ""
        property color iconColor:
            Colors.on_SurfaceVariant

        property int iconSize: 16

        property bool enabledState: true

        signal clicked()

        Layout.preferredWidth: 32
        Layout.preferredHeight: 32

        opacity:
            enabledState
            ? 1
            : 0.35

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }

        Rectangle {
            anchors.centerIn: parent

            width:
                mouse.containsMouse
                ? 30
                : 26

            height: width

            radius:
                width / 2

            color:
                mouse.containsMouse
                ? Qt.rgba(
                      Colors.primary.r,
                      Colors.primary.g,
                      Colors.primary.b,
                      0.12
                  )
                : "transparent"

            Behavior on width {
                NumberAnimation {
                    duration: 120
                    easing.type:
                        Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 120
                    easing.type:
                        Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration:
                        Theme.hoverFadeDuration
                }
            }
        }

        Text {
            anchors.centerIn: parent

            text:
                button.icon

            font.family:
                Fonts.fontM

            font.pointSize:
                button.iconSize

            color:
                button.iconColor
        }

        MouseArea {
            id: mouse

            anchors.fill:
                parent

            hoverEnabled: true

            enabled:
                button.enabledState

            cursorShape:
                enabled
                ? Qt.PointingHandCursor
                : Qt.ArrowCursor

            onClicked:
                button.clicked()
        }
    }

    Item {
        Layout.fillWidth: true
    }

    // Shuffle
    IconButton {
        icon: "󰒞"

        iconSize: 13

        iconColor:
            root.player?.shuffle
            ? Colors.primary
            : Colors.on_SurfaceVariant

        enabledState:
            root.player?.shuffleSupported ??
            false

        onClicked: {
            if (
                root.player &&
                root.player.shuffleSupported
            ) {
                root.player.shuffle =
                    !root.player.shuffle
            }
        }
    }

    // Previous
    IconButton {
        icon: "󰒮"

        iconSize: 16

        enabledState:
            root.player?.canGoPrevious ??
            false

        onClicked: {
            if (
                root.player?.canGoPrevious
            ) {
                root.player.previous()
            }
        }
    }

    // Play / Pause
    Item {
        Layout.preferredWidth: 44
        Layout.preferredHeight: 44

        property bool hovered:
            playMouse.containsMouse

        Rectangle {
            anchors.centerIn:
                parent

            width:
                parent.hovered
                ? 42
                : 38

            height: width

            radius:
                width / 2

            color:
                parent.hovered
                ? Qt.rgba(
                      Colors.primary.r,
                      Colors.primary.g,
                      Colors.primary.b,
                      0.28
                  )
                : Qt.rgba(
                      Colors.primary.r,
                      Colors.primary.g,
                      Colors.primary.b,
                      0.18
                  )

            Behavior on width {
                NumberAnimation {
                    duration: 130
                    easing.type:
                        Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration:
                        Theme.hoverFadeDuration
                }
            }
        }

        Text {
            anchors.centerIn:
                parent

            text:
                root.isPlaying
                ? "󰏤"
                : "󰐊"

            font.family:
                Fonts.fontM

            font.pointSize: 18

            color:
                Colors.primary
        }

        MouseArea {
            id: playMouse

            anchors.fill:
                parent

            hoverEnabled: true

            enabled:
                root.player?.canTogglePlaying ??
                false

            cursorShape:
                enabled
                ? Qt.PointingHandCursor
                : Qt.ArrowCursor

            onClicked: {
                if (
                    root.player?.canTogglePlaying
                ) {
                    root.player.togglePlaying()
                }
            }
        }
    }

    // Next
    IconButton {
        icon: "󰒭"

        iconSize: 16

        enabledState:
            root.player?.canGoNext ??
            false

        onClicked: {
            if (
                root.player?.canGoNext
            ) {
                root.player.next()
            }
        }
    }

    // Repeat
    IconButton {
        icon: {
            const loop =
                root.player?.loopState ??
                MprisLoopState.None

            return loop ===
                   MprisLoopState.Track
                   ? "󰑘"
                   : "󰑖"
        }

        iconSize: 13

        iconColor: {
            const loop =
                root.player?.loopState ??
                MprisLoopState.None

            return loop !==
                   MprisLoopState.None
                   ? Colors.primary
                   : Colors.on_SurfaceVariant
        }

        enabledState:
            root.player?.loopSupported ??
            false

        onClicked: {
            if (
                !root.player ||
                !root.player.loopSupported
            ) {
                return
            }

            const loop =
                root.player.loopState

            if (
                loop ===
                MprisLoopState.None
            ) {
                root.player.loopState =
                    MprisLoopState.Playlist
            } else if (
                loop ===
                MprisLoopState.Playlist
            ) {
                root.player.loopState =
                    MprisLoopState.Track
            } else {
                root.player.loopState =
                    MprisLoopState.None
            }
        }
    }

    Item {
        Layout.fillWidth: true
    }
}

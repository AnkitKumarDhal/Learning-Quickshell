import QtQuick
import QtQuick.Layouts
import qs.src.theme

// Scrubber + time labels.
// Parent owns _position and _seeking; we communicate back via signals.

ColumnLayout {
    id: root

    required property var  player
    required property real position    // seconds (float)
    required property bool seeking

    signal seekStarted(real pos)
    signal seekMoved(real pos)
    signal seekReleased(real pos)

    Layout.fillWidth: true
    spacing:          4

    visible: root.player !== null && (root.player.positionSupported ?? false)

    // ── Scrubber ──────────────────────────────────────────────────────────────
    Item {
        Layout.fillWidth:       true
        Layout.preferredHeight: 16

        readonly property real trackLen: root.player?.length ?? 0
        readonly property real fraction: trackLen > 0
                                         ? Math.min(root.position / trackLen, 1.0)
                                         : 0

        // Track bg
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width:  parent.width
            height: 4; radius: 2
            color:  Colors.surfaceContainerHighest
        }

        // Fill
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left:           parent.left
            width:  parent.width * parent.fraction
            height: 4; radius: 2
            color:  Colors.primary

            Behavior on width {
                enabled: !root.seeking
                NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
            }
        }

        // Thumb
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x:      parent.width * parent.fraction - width / 2
            width:  12; height: 12; radius: 6
            color:  Colors.primary

            Behavior on x {
                enabled: !root.seeking
                NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled:      root.player?.canSeek ?? false
            cursorShape:  enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

            onPressed: (mouse) => {
                root.seekStarted((mouse.x / width) * (root.player?.length ?? 0))
            }
            onPositionChanged: (mouse) => {
                if (pressed)
                    root.seekMoved(Math.max(0,
                        Math.min(mouse.x / width, 1.0) * (root.player?.length ?? 0)))
            }
            onReleased: (mouse) => {
                root.seekReleased(Math.max(0,
                    Math.min(mouse.x / width, 1.0) * (root.player?.length ?? 0)))
            }
        }
    }

    // ── Time labels ───────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true

        Text {
            text: {
                const s = Math.floor(root.position)   // position is already seconds
                return "%1:%2".arg(Math.floor(s / 60))
                              .arg(String(s % 60).padStart(2, "0"))
            }
            color:          Colors.on_SurfaceVariant
            font.family:    Fonts.font
            font.pointSize: 9
        }

        Item { Layout.fillWidth: true }

        Text {
            text: {
                const s = Math.floor(root.player?.length ?? 0)
                return "%1:%2".arg(Math.floor(s / 60))
                              .arg(String(s % 60).padStart(2, "0"))
            }
            color:          Colors.on_SurfaceVariant
            font.family:    Fonts.font
            font.pointSize: 9
        }
    }
}

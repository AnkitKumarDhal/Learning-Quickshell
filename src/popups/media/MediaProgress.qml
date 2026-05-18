import QtQuick
import QtQuick.Layouts
import qs.src.theme
import qs.src.state

ColumnLayout {
    id: root

    property var  player:   null
    property bool isPlaying: false

    property bool seeking: false

    spacing: 4

    // ── Scrubber ──────────────────────────────────────────────────────────────
    Item {
        id:                     scrubber
        Layout.fillWidth:       true
        Layout.preferredHeight: 16

        // Quickshell's `length` is in seconds. `position` is also in seconds.
        property real trackLen: (root.player?.lengthSupported ?? false)
                                      ? (root.player?.length ?? 0)
                                      : 0
        property real fraction: scrubber.trackLen > 0
                                  ? Math.min((root.player?.position ?? 0) / scrubber.trackLen, 1.0)
                                  : 0

        // Track background
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width:  parent.width
            height: 4
            radius: 2
            color:  Colors.surfaceContainerHighest
        }

        // Fill
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left:           parent.left
            width:                  scrubber.width * scrubber.fraction
            height:                 4
            radius:                 2
            color:                  Colors.primary

            Behavior on width {
                enabled: !root.seeking
                NumberAnimation { duration: 800; easing.type: Easing.Linear }
            }
        }

        // Thumb
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x:      scrubber.width * scrubber.fraction - width / 2
            width:  10; height: 10; radius: 5
            color:  Colors.primary

            Behavior on x {
                enabled: !root.seeking
                NumberAnimation { duration: 800; easing.type: Easing.Linear }
            }
        }

        // Seek mouse area
        MouseArea {
            anchors.fill: parent
            enabled:      root.player?.canSeek ?? false
            cursorShape:  enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

            onPressed: (mouse) => {
                root.seeking   = true
                if (root.player)
                    root.player.position = (mouse.x / scrubber.width) * scrubber.trackLen
            }
            onPositionChanged: (mouse) => {
                if (pressed && root.player)
                    root.player.position = Math.max(0,
                        Math.min(mouse.x / scrubber.width, 1.0) * scrubber.trackLen)
            }
            onReleased: {
                root.seeking = false
            }
        }
    }

    // ── Time labels ───────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true

        Text {
            text: {
                const pos = root.player?.position ?? 0
                const s = Math.floor(pos)
                return "%1:%2".arg(Math.floor(s / 60))
                              .arg(String(s % 60).padStart(2, "0"))
            }
            color:          Colors.on_SurfaceVariant
            font.family:    Fonts.font
            font.pointSize: 8
        }

        Item { Layout.fillWidth: true }

        Text {
            text: {
                const s = Math.floor(scrubber.trackLen)
                return "%1:%2".arg(Math.floor(s / 60))
                              .arg(String(s % 60).padStart(2, "0"))
            }
            color:          Colors.on_SurfaceVariant
            font.family:    Fonts.font
            font.pointSize: 8
        }
    }
}

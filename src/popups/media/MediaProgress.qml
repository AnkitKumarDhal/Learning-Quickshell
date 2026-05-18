import QtQuick
import QtQuick.Layouts
import qs.src.theme
import qs.src.state

ColumnLayout {
    id: root

    property var  player:   null
    property bool isPlaying: false

    // Exposed so MediaPopup can bind seeking state if needed
    property bool seeking: false

    // Internal normalized position in ms
    property real _position: 0

    spacing: 4

    // ── Position polling ──────────────────────────────────────────────────────
    Timer {
        interval: 1000
        repeat:   true
        running:  root.isPlaying && !root.seeking
        onTriggered: {
            if (!root.player) return
            const raw = root.player.position
            // Normalize: if value looks like µs (> 10 million for a >10s track), convert
            root._position = raw > 10000000 ? raw / 1000 : raw
        }
    }

    Connections {
        target:  root.player ?? null
        function onTrackTitleChanged() { root._position = 0 }
    }

    // ── Scrubber ──────────────────────────────────────────────────────────────
    Item {
        id:                     scrubber
        Layout.fillWidth:       true
        Layout.preferredHeight: 16

        property real trackLen: {
            if (!root.player) return 0
            const raw = root.player.trackLength ?? 0
            return raw > 10000000 ? raw / 1000 : raw
        }
        property real fraction: trackLen > 0
                                 ? Math.min(root._position / trackLen, 1.0)
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
                root._position = (mouse.x / scrubber.width) * scrubber.trackLen
            }
            onPositionChanged: (mouse) => {
                if (pressed)
                    root._position = Math.max(0,
                        Math.min(mouse.x / scrubber.width, 1.0) * scrubber.trackLen)
            }
            onReleased: {
                if (root.player)
                    root.player.position = root._position
                root.seeking = false
            }
        }
    }

    // ── Time labels ───────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true

        Text {
            text: {
                const s = Math.floor(root._position / 1000)
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
                const s = Math.floor(scrubber.trackLen / 1000)
                return "%1:%2".arg(Math.floor(s / 60))
                              .arg(String(s % 60).padStart(2, "0"))
            }
            color:          Colors.on_SurfaceVariant
            font.family:    Fonts.font
            font.pointSize: 8
        }
    }
}

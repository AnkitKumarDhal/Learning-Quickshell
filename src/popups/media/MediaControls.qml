import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.src.theme
import qs.src.state

RowLayout {
    id: root

    property var  player:    null
    property bool isPlaying: false

    spacing: 4

    // ── Helper component for icon buttons ─────────────────────────────────────
    component MediaBtn: Item {
        property string icon:      ""
        property color  iconColor: Colors.on_Surface
        property real   iconSize:  13
        property bool   active:    false

        signal clicked()

        Layout.preferredWidth:  30
        Layout.preferredHeight: 30

        Rectangle {
            anchors.centerIn: parent
            width: 26; height: 26; radius: 13
            color: hov.containsMouse
                   ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                   : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
        }

        Text {
            anchors.centerIn: parent
            text:             parent.icon
            font.family:      Fonts.fontM
            font.pointSize:   parent.iconSize
            color:            parent.active ? Colors.primary : parent.iconColor
        }

        MouseArea {
            id:           hov
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            onClicked:    parent.clicked()
        }
    }

    // Shuffle
    MediaBtn {
        icon:      "󰒞"
        iconColor: Colors.on_SurfaceVariant
        active:    root.player?.shuffle ?? false
        onClicked: if (root.player) root.player.shuffle = !root.player.shuffle
    }

    Item { Layout.fillWidth: true }

    // Prev
    MediaBtn {
        icon:      "󰒮"
        iconSize:  14
        onClicked: if (root.player) root.player.previous()
    }

    Item { Layout.fillWidth: true }

    // Play / Pause — larger
    Item {
        Layout.preferredWidth:  42
        Layout.preferredHeight: 42

        Rectangle {
            anchors.centerIn: parent
            width: 36; height: 36; radius: 18
            color: playHov.containsMouse
                   ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.25)
                   : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
            Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
        }

        Text {
            anchors.centerIn: parent
            text:             root.isPlaying ? "󰏤" : "󰐊"
            font.family:      Fonts.fontM
            font.pointSize:   16
            color:            Colors.primary
        }

        MouseArea {
            id:           playHov
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            onClicked:    if (root.player) root.player.togglePlaying()
        }
    }

    Item { Layout.fillWidth: true }

    // Next
    MediaBtn {
        icon:      "󰒭"
        iconSize:  14
        onClicked: if (root.player) root.player.next()
    }

    Item { Layout.fillWidth: true }

    // Loop
    MediaBtn {
        icon: (root.player?.loopState ?? MprisLoopState.None) === MprisLoopState.Track
              ? "󰑘" : "󰑖"
        iconColor: Colors.on_SurfaceVariant
        active:    (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
        onClicked: {
            if (!root.player) return
            const ls = root.player.loopState
            if      (ls === MprisLoopState.None)     root.player.loopState = MprisLoopState.Playlist
            else if (ls === MprisLoopState.Playlist) root.player.loopState = MprisLoopState.Track
            else                                     root.player.loopState = MprisLoopState.None
        }
    }
}

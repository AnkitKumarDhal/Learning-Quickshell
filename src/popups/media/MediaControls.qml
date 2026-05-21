import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.src.theme

RowLayout {
    id: root

    required property var  player
    required property bool isPlaying

    Layout.fillWidth: true
    spacing:          0

    // ── Helper: icon button ───────────────────────────────────────────────────
    component IconBtn: Item {
        property string icon:      ""
        property color  iconColor: Colors.on_Surface
        property int    iconSize:  16
        property int    btnSize:   36
        property int    bgSize:    28

        signal clicked()

        Layout.preferredWidth:  btnSize
        Layout.preferredHeight: btnSize

        Rectangle {
            anchors.centerIn: parent
            width: bgSize; height: bgSize; radius: bgSize / 2
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
            color:            parent.iconColor
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
    IconBtn {
        icon:      "󰒞"
        iconSize:  13
        iconColor: (root.player?.shuffle ?? false) ? Colors.primary : Colors.on_SurfaceVariant
        onClicked: if (root.player) root.player.shuffle = !root.player.shuffle
    }

    Item { Layout.fillWidth: true }

    // Prev
    IconBtn {
        icon:      "󰒮"
        iconSize:  16
        onClicked: if (root.player) root.player.previous()
    }

    Item { Layout.fillWidth: true }

    // Play / Pause — bigger
    Item {
        Layout.preferredWidth:  52
        Layout.preferredHeight: 52

        Rectangle {
            anchors.centerIn: parent
            width: 44; height: 44; radius: 22
            color: playHov.containsMouse
                   ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.25)
                   : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
            Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
        }

        Text {
            anchors.centerIn: parent
            text:             root.isPlaying ? "󰏤" : "󰐊"
            font.family:      Fonts.fontM
            font.pointSize:   20
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
    IconBtn {
        icon:      "󰒭"
        iconSize:  16
        onClicked: if (root.player) root.player.next()
    }

    Item { Layout.fillWidth: true }

    // Loop
    IconBtn {
        icon: {
            const ls = root.player?.loopState ?? MprisLoopState.None
            return ls === MprisLoopState.Track ? "󰑘" : "󰑖"
        }
        iconSize:  13
        iconColor: {
            const ls = root.player?.loopState ?? MprisLoopState.None
            return ls !== MprisLoopState.None ? Colors.primary : Colors.on_SurfaceVariant
        }
        onClicked: {
            if (!root.player) return
            const ls = root.player.loopState
            if      (ls === MprisLoopState.None)     root.player.loopState = MprisLoopState.Playlist
            else if (ls === MprisLoopState.Playlist) root.player.loopState = MprisLoopState.Track
            else                                     root.player.loopState = MprisLoopState.None
        }
    }
}

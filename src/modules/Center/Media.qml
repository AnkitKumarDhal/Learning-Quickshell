import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
import qs.src.components
import qs.src.theme
import qs.src.state

Row {
    id: root

    spacing: 6

    property var players:      Mpris.players.values
    property var activePlayer: players.length > 0 ? players[0] : null
    property bool hasArt:      activePlayer && activePlayer.trackArtUrl !== ""
    property bool isPlaying:   activePlayer?.playbackState === MprisPlaybackState.Playing ?? false

    visible: activePlayer !== null

    // ── Prev button ───────────────────────────────────────────────────────────
    PillBase {
        hoverExpand: true
        implicitWidth: Theme.pillHeight  // square pill

        Text {
            text: "󰒮"
            color: Colors.primary
            font.pointSize: 12
            font.family: Fonts.font
            anchors.centerIn: parent
        }

        onClicked: if (root.activePlayer) root.activePlayer.previous()
    }

    // ── Center pill — art + title ─────────────────────────────────────────────
    PillBase {
        hoverExpand: false

        onClicked:      Popups.mediaOpen = !Popups.mediaOpen
        onRightClicked: if (root.activePlayer) root.activePlayer.togglePlaying()

        Row {
            spacing: 8
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            // Rotating disc
            Item {
                visible: root.hasArt
                width:  20
                height: 20
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    id: artMask
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                }

                Image {
                    anchors.fill: parent
                    source: root.activePlayer ? root.activePlayer.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true
                    layer.effect: OpacityMask { maskSource: artMask }

                    NumberAnimation on rotation {
                        from: 0; to: 360
                        duration: 5000
                        loops: Animation.Infinite
                        running: true
                        paused: !root.isPlaying
                    }
                }
            }

            Text {
                text: root.activePlayer
                    ? (root.activePlayer.trackTitle || "Unknown Track")
                    : ""
                color: Colors.primary
                font.pointSize: 11
                font.bold: true
                font.italic: root.isPlaying
                font.family: Fonts.font
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 150)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // ── Next button ───────────────────────────────────────────────────────────
    PillBase {
        hoverExpand: true
        implicitWidth: Theme.pillHeight  // square pill

        Text {
            text: "󰒭"
            color: Colors.primary
            font.pointSize: 12
            font.family: Fonts.font
            anchors.centerIn: parent
        }

        onClicked: if (root.activePlayer) root.activePlayer.next()
    }
}

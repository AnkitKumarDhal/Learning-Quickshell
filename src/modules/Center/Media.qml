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

    property var players: Mpris.players.values
    property var activePlayer: {
        if (players.length === 0) return null

        let bestMatch = null
        
        // We loop through ALL players intentionally. 
        // This forces QML to register a visual dependency on EVERY player's playback state.
        for (let i = 0; i < players.length; i++) {
            let state = players[i].playbackState
            
            // If we find a playing player, mark it as the best match
            if (state === MprisPlaybackState.Playing && bestMatch === null) {
                bestMatch = players[i]
            }
        }
        
        // Return the playing source, or fallback to the first available if everything is paused
        return bestMatch || players[0]
    }
    property bool hasArt:       activePlayer && activePlayer.trackArtUrl !== ""
    property bool isPlaying:    activePlayer?.playbackState === MprisPlaybackState.Playing ?? false

    visible: activePlayer !== null

    // ── Prev button ───────────────────────────────────────────────────────────
    PillBase {
        hoverExpand:   true
        implicitWidth: Theme.pillHeight

        Text {
            text:             "󰒮"
            color:            Colors.primary
            font.pointSize:   12
            font.family:      Fonts.font
            Layout.alignment: Qt.AlignVCenter
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

            // Rotating disc
            Item {
                visible: root.hasArt
                width:   20
                height:  20

                Rectangle {
                    id:           artMask
                    anchors.fill: parent
                    radius:       width / 2
                    visible:      false
                }

                Image {
                    anchors.fill: parent
                    source:       root.activePlayer ? root.activePlayer.trackArtUrl : ""
                    fillMode:     Image.PreserveAspectCrop
                    layer.enabled: true
                    layer.effect: OpacityMask { maskSource: artMask }

                    NumberAnimation on rotation {
                        from:     0
                        to:       360
                        duration: 5000
                        loops:    Animation.Infinite
                        running:  true
                        paused:   !root.isPlaying
                    }
                }
            }

            Text {
                text:          root.activePlayer
                                   ? (root.activePlayer.trackTitle || "Unknown Track")
                                   : ""
                color:         Colors.primary
                font.pointSize: 11
                font.bold:     true
                font.italic:   root.isPlaying
                font.family:   Fonts.font
                elide:         Text.ElideRight
                width:         Math.min(implicitWidth, 150)
            }
        }
    }

    // ── Next button ───────────────────────────────────────────────────────────
    PillBase {
        hoverExpand:   true
        implicitWidth: Theme.pillHeight

        Text {
            text:             "󰒭"
            color:            Colors.primary
            font.pointSize:   12
            font.family:      Fonts.font
            Layout.alignment: Qt.AlignVCenter
        }

        onClicked: if (root.activePlayer) root.activePlayer.next()
    }
}

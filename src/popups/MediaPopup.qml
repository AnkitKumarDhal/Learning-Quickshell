import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import qs.src.components
import qs.src.theme
import qs.src.state
import "media"

PanelWindow {
    id: win

    property var screen

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors.top: true

    implicitWidth:  win.screen ? win.screen.width : 1920
    implicitHeight: win.screen ? win.screen.height : 1080

    WlrLayershell.layer: WlrLayer.Overlay
    visible: slide.windowVisible

    // ── Player resolution ─────────────────────────────────────────────────────
    property var _players:    Mpris.players.values
    property var _lastActive: null

    property var _currentlyPlaying: {
        for (let i = 0; i < _players.length; i++) {
            if (_players[i].playbackState === MprisPlaybackState.Playing)
                return _players[i]
        }
        return null
    }

    on_CurrentlyPlayingChanged: {
        if (_currentlyPlaying) _lastActive = _currentlyPlaying
    }

    property var player: {
        if (_players.length === 0) return null
        if (_currentlyPlaying)     return _currentlyPlaying
        if (_lastActive) {
            for (let i = 0; i < _players.length; i++)
                if (_players[i] === _lastActive) return _lastActive
        }
        return _players[0]
    }

    property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing ?? false

    // ── Slide ─────────────────────────────────────────────────────────────────
    PopupSlide {
        id:           slide
        anchors.fill: parent
        edge:         "top"
        open:         Popups.mediaOpen
        onCloseRequested: Popups.mediaOpen = false
    }

    // ── Card ──────────────────────────────────────────────────────────────────
    Rectangle {
        id: card

        anchors {
            top:              parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin:        Theme.barHeight + 8
        }

        width:        340
        height:       cardCol.implicitHeight + 16
        radius:       Theme.popupRadius
        color:        Colors.surfaceContainer
        border.color: Colors.outlineVariant
        border.width: Theme.popupBorder
        clip:         true

        ColumnLayout {
            id: cardCol
            anchors {
                top:         parent.top
                left:        parent.left
                right:       parent.right
                topMargin:   12
                leftMargin:  12
                rightMargin: 12
            }
            spacing: 10

            // ── Art + Info row ────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing:          10

                MediaArt {
                    player:                win.player
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 100
                }

                MediaInfo {
                    player:           win.player
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // ── Progress ──────────────────────────────────────────────────────
            MediaProgress {
                player:           win.player
                isPlaying:        win.isPlaying
                Layout.fillWidth: true
                visible:          win.player !== null
            }

            // ── Controls ──────────────────────────────────────────────────────
            MediaControls {
                player:           win.player
                isPlaying:        win.isPlaying
                Layout.fillWidth: true
            }

            // ── Volume ────────────────────────────────────────────────────────
            MediaVolume {
                player:           win.player
                Layout.fillWidth: true
                visible:          win.player !== null
                Layout.bottomMargin: 4
            }
        }
    }

    Timer {
    interval: 2000; repeat: true; running: win.player !== null
    onTriggered: console.log("pos:", win.player?.position, "len:", win.player?.trackLength, "supported:", win.player?.positionSupported)
}
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.popups.media

PanelWindow {
    id: win

    property var screen

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top:   true
        // right: true
    }

    implicitWidth:  380
    implicitHeight: win.screen ? win.screen.height : 800

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

    // ── Position tracking ─────────────────────────────────────────────────────
    // Quickshell doesn't auto-emit positionChanged; we must drive it ourselves.
    FrameAnimation {
        running: win.isPlaying && (win.player?.positionSupported ?? false)
        onTriggered: win.player?.positionChanged()
    }

    // ── Slide ─────────────────────────────────────────────────────────────────
    PopupSlide {
        id:           slide
        anchors.fill: parent
        edge:         "top"
        open:         Popups.mediaOpen
        onCloseRequested: Popups.mediaOpen = false
    }

    // ── Card — row layout: art on left, everything else on right ──────────────
    Rectangle {
        id: card

        anchors {
            top:              parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin:        Theme.barHeight + 8
        }

        implicitWidth:  row.implicitWidth + 32
        implicitHeight: Math.max(100, row.implicitHeight) + 32
        radius:         Theme.popupRadius
        color:          Colors.surfaceContainer
        border.color:   Colors.outlineVariant
        border.width:   Theme.popupBorder
        clip:           true

        RowLayout {
            id: row
            anchors {
                fill:    parent
                margins: 16
            }
            spacing: 16

            // ── Album art ─────────────────────────────────────────────────────
            MediaArt {
                player:                 win.player
                Layout.preferredWidth:  100
                Layout.preferredHeight: 100
            }

            // ── Info + progress + controls + volume ───────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                MediaInfo {
                    player:           win.player
                    Layout.fillWidth: true
                }

                MediaProgress {
                    player:           win.player
                    isPlaying:        win.isPlaying
                    Layout.fillWidth: true
                    visible:          win.player !== null
                }

                MediaControls {
                    player:           win.player
                    isPlaying:        win.isPlaying
                    Layout.fillWidth: true
                }

                MediaVolume {
                    player:           win.player
                    Layout.fillWidth: true
                    visible:          win.player !== null
                }
            }
        }
    }
}

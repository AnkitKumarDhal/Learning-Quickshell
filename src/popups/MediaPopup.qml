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

    //property var screen
    WlrLayershell.screen:        screen
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.top:   true

    implicitHeight: win.screen ? win.screen.height : 800
    implicitWidth:  340
    color:          "transparent"
    exclusionMode:  ExclusionMode.Ignore
    visible:        slide.windowVisible
    mask: Region {
        x:      (win.implicitWidth - mediaCard.width) / 2
        y:      Theme.barHeight + 8
        width:  mediaCard.width
        height: mediaCard.height
    }

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
    property bool hasArt:    player !== null && player.trackArtUrl !== ""

    // ── Position tracking (seconds, float) ───────────────────────────────────
    property real _position: 0.0
    property bool _seeking:  false

    Timer {
        interval: 1000
        repeat:   true
        running:  win.isPlaying && !win._seeking
        onTriggered: {
            if (win.player && win.player.positionSupported)
                win.player.positionChanged()   // nudge the binding per docs
            win._position = win.player?.position ?? 0
        }
    }

    Connections {
        target: win.player ?? null
        function onTrackTitleChanged() { win._position = 0 }
    }

    // ── Slide ─────────────────────────────────────────────────────────────────
    PopupSlide {
        id:           slide
        anchors.fill: parent
        open:         Popups.mediaOpen
        edge:         "top"
        onCloseRequested: Popups.mediaOpen = false

        // ── Card ──────────────────────────────────────────────────────────────────
        Rectangle {
            id: mediaCard
            width:  340
            anchors.top:              parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin:        Theme.barHeight + 8

            implicitHeight: cardLayout.implicitHeight + 24
            radius:         Theme.popupRadius
            color:          Colors.surfaceContainer
            border.color:   Colors.outlineVariant
            border.width:   Theme.popupBorder

            ColumnLayout {
                id: cardLayout
                anchors {
                    top:          parent.top
                    left:         parent.left
                    right:        parent.right
                    topMargin:    12
                    leftMargin:   16
                    rightMargin:  16
                    bottomMargin: 12
                }
                spacing: 12

                MediaArt {
                    player: win.player
                    hasArt: win.hasArt
                }

                MediaTrackInfo {
                    player: win.player
                }

                MediaProgress {
                    player:   win.player
                    position: win._position
                    seeking:  win._seeking

                    onSeekStarted: (pos) => { win._seeking = true;  win._position = pos }
                    onSeekMoved:   (pos) => { win._position = pos }
                    onSeekReleased: (pos) => {
                        if (win.player) win.player.position = pos
                        win._seeking = false
                    }
                }

                MediaControls {
                    player:    win.player
                    isPlaying: win.isPlaying
                }

                MediaVolumeRow {
                    player: win.player
                }
            }
        }
    }
}

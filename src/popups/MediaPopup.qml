import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
import qs.src.components
import qs.src.theme
import qs.src.state

PanelWindow {
    id: win

    property var screen

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top:   true
        left:  true
        right: true
    }

    implicitWidth:  380
    implicitHeight: win.screen ? win.screen.height : 800

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    visible: slide.windowVisible

    PopupSlide {
        id: slide
        anchors.fill: parent
        edge: "top"
        open: Popups.mediaOpen
        onCloseRequested: Popups.mediaOpen = false
    }

    // ── Player resolution (mirrors Media.qml logic) ───────────────────────────
    property var _players:       Mpris.players.values
    property var _lastActive:    null

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
        if (_currentlyPlaying)    return _currentlyPlaying
        if (_lastActive) {
            for (let i = 0; i < _players.length; i++)
                if (_players[i] === _lastActive) return _lastActive
        }
        return _players[0]
    }

    property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing ?? false
    property bool hasArt:    player && player.trackArtUrl !== ""

    // ── Position polling ──────────────────────────────────────────────────────
    property real _position: 0
    property bool _seeking:  false

    Timer {
        interval: 1000
        repeat:   true
        running:  win.isPlaying && !win._seeking
        onTriggered: {
            if (win.player && win.player.positionSupported)
                win._position = win.player.position
        }
    }

    Connections {
        target: win.player ?? null
        function onTrackTitleChanged() { win._position = 0 }
    }

    // ── Card ──────────────────────────────────────────────────────────────────
    Rectangle {
        id: card

        anchors {
            top:          parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin:    Theme.barHeight + 8
        }

        width:  340
        implicitHeight: cardCol.implicitHeight + 16
        radius:         Theme.popupRadius
        color:          Colors.surfaceContainer
        border.color:   Colors.outlineVariant
        border.width:   Theme.popupBorder
        clip:           true

        ColumnLayout {
            id: cardCol
            anchors {
                top:    parent.top
                left:   parent.left
                right:  parent.right
                margins: 8
            }
            spacing: 8

            // ── Art + Info row ────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Square album art
                Rectangle {
                    Layout.preferredWidth:  64
                    Layout.preferredHeight: 64
                    Layout.alignment: Qt.AlignTop
                    radius: 8
                    color:  Colors.surfaceContainerHigh
                    clip:   true

                    visible: win.hasArt

                    Image {
                        anchors.fill: parent
                        source:       win.player ? win.player.trackArtUrl : ""
                        fillMode:     Image.PreserveAspectCrop
                        smooth:       true
                    }
                }

                // Placeholder
                Rectangle {
                    Layout.preferredWidth:  64
                    Layout.preferredHeight: 64
                    Layout.alignment: Qt.AlignTop
                    radius: 8
                    color:  Colors.surfaceContainerHigh
                    visible: !win.hasArt

                    Text {
                        anchors.centerIn: parent
                        text:             "󰎆"
                        font.family:      Fonts.fontM
                        font.pointSize:   24
                        color:            Colors.on_SurfaceVariant
                    }
                }

                // Track info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    // Title with disc icon
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text:             "󰎈"
                            font.family:      Fonts.fontM
                            font.pixelSize:   12
                            color:            Colors.primary
                        }

                        Text {
                            Layout.fillWidth: true
                            text:             win.player?.trackTitle ?? "Nothing Playing"
                            color:            Colors.on_Surface
                            font.family:      Fonts.font
                            font.pointSize:   11
                            font.bold:        true
                            elide:            Text.ElideRight
                        }
                    }

                    // Artist with person icon
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: win.player?.trackArtist !== ""

                        Text {
                            text:             "󰈠"
                            font.family:      Fonts.fontM
                            font.pixelSize:   10
                            color:            Colors.on_SurfaceVariant
                        }

                        Text {
                            Layout.fillWidth: true
                            text:             win.player?.trackArtist ?? ""
                            color:            Colors.on_SurfaceVariant
                            font.family:      Fonts.font
                            font.pointSize:   9
                            elide:            Text.ElideRight
                        }
                    }

                    // Album
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: win.player?.trackAlbum !== ""

                        Text {
                            text:             "󰀥"
                            font.family:      Fonts.fontM
                            font.pixelSize:   10
                            color:            Colors.on_SurfaceVariant
                            opacity:          0.7
                        }

                        Text {
                            Layout.fillWidth: true
                            text:             win.player?.trackAlbum ?? ""
                            color:            Colors.on_SurfaceVariant
                            font.family:      Fonts.font
                            font.pointSize:   9
                            elide:            Text.ElideRight
                            opacity:          0.7
                        }
                    }
                }
            }

            // ── Progress bar ──────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                visible: win.player !== null && win.player.positionSupported

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16

                    // Track background
                    Rectangle {
                        id: trackBg
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
                        width:  {
                            const len = win.player?.trackLength ?? 0
                            return len > 0 ? parent.width * (win._position / len) : 0
                        }
                        height: 4
                        radius: 2
                        color:  Colors.primary

                        Behavior on width {
                            enabled: !win._seeking
                            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                    }

                    // Seek area
                    MouseArea {
                        anchors.fill: parent
                        enabled:      win.player?.canSeek ?? false
                        cursorShape:  enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onPressed: (mouse) => {
                            win._seeking = true
                            const len = win.player?.trackLength ?? 0
                            win._position = (mouse.x / trackBg.width) * len
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                const len = win.player?.trackLength ?? 0
                                win._position = Math.max(0, Math.min(mouse.x / trackBg.width, 1.0) * len)
                            }
                        }
                        onReleased: {
                            if (win.player)
                                win.player.position = win._position
                            win._seeking = false
                        }
                    }
                }

                // Time labels
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: {
                            const s = Math.floor(win._position / 1000)
                            return "%1:%2".arg(Math.floor(s / 60)).arg(String(s % 60).padStart(2, "0"))
                        }
                        color:       Colors.on_SurfaceVariant
                        font.family: Fonts.font
                        font.pointSize: 8
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: {
                            const s = Math.floor((win.player?.trackLength ?? 0) / 1000)
                            return "%1:%2".arg(Math.floor(s / 60)).arg(String(s % 60).padStart(2, "0"))
                        }
                        color:       Colors.on_SurfaceVariant
                        font.family: Fonts.font
                        font.pointSize: 8
                    }
                }
            }

            // ── Controls ──────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                // Shuffle
                Item {
                    Layout.preferredWidth:  32
                    Layout.preferredHeight: 32

                    Rectangle {
                        anchors.centerIn: parent
                        width:  26; height: 26; radius: 13
                        color:  shuffleHover.containsMouse
                                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text:             "󰒞"
                        font.family:      Fonts.fontM
                        font.pointSize:   11
                        color:            (win.player?.shuffle ?? false) ? Colors.primary : Colors.on_SurfaceVariant
                    }

                    MouseArea {
                        id:           shuffleHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    if (win.player) win.player.shuffle = !win.player.shuffle
                    }
                }

                // Prev
                Item {
                    Layout.preferredWidth:  32
                    Layout.preferredHeight: 32

                    Rectangle {
                        anchors.centerIn: parent
                        width:  26; height: 26; radius: 13
                        color:  prevHover.containsMouse
                                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text:             "󰒮"
                        font.family:      Fonts.fontM
                        font.pointSize:   13
                        color:            Colors.on_Surface
                    }

                    MouseArea {
                        id:           prevHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    if (win.player) win.player.previous()
                    }
                }

                // Play / Pause
                Item {
                    Layout.preferredWidth:  44
                    Layout.preferredHeight: 44

                    Rectangle {
                        anchors.centerIn: parent
                        width:  38; height: 38; radius: 19
                        color:  playHover.containsMouse
                                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.25)
                                : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text:             win.isPlaying ? "󰏤" : "󰐊"
                        font.family:      Fonts.fontM
                        font.pointSize:   16
                        color:            Colors.primary
                    }

                    MouseArea {
                        id:           playHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    if (win.player) win.player.togglePlaying()
                    }
                }

                // Next
                Item {
                    Layout.preferredWidth:  32
                    Layout.preferredHeight: 32

                    Rectangle {
                        anchors.centerIn: parent
                        width:  26; height: 26; radius: 13
                        color:  nextHover.containsMouse
                                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text:             "󰒭"
                        font.family:      Fonts.fontM
                        font.pointSize:   13
                        color:            Colors.on_Surface
                    }

                    MouseArea {
                        id:           nextHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    if (win.player) win.player.next()
                    }
                }

                // Loop
                Item {
                    Layout.preferredWidth:  32
                    Layout.preferredHeight: 32

                    Rectangle {
                        anchors.centerIn: parent
                        width:  26; height: 26; radius: 13
                        color:  loopHover.containsMouse
                                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: {
                            const ls = win.player?.loopState ?? MprisLoopState.None
                            return ls === MprisLoopState.Track ? "󰑘" : "󰑖"
                        }
                        font.family: Fonts.fontM
                        font.pointSize: 11
                        color: {
                            const ls = win.player?.loopState ?? MprisLoopState.None
                            return ls !== MprisLoopState.None ? Colors.primary : Colors.on_SurfaceVariant
                        }
                    }

                    MouseArea {
                        id:           loopHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: {
                            if (!win.player) return
                            const ls = win.player.loopState
                            if      (ls === MprisLoopState.None)     win.player.loopState = MprisLoopState.Playlist
                            else if (ls === MprisLoopState.Playlist) win.player.loopState = MprisLoopState.Track
                            else                                     win.player.loopState = MprisLoopState.None
                        }
                    }
                }
            }
        }
    }
}

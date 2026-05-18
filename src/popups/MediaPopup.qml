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
    property real _position: 0   // ms, polled
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

    // Reset position when track changes
    Connections {
        target: win.player ?? null
        function onTrackTitleChanged() { win._position = 0 }
    }

    // ── Card ──────────────────────────────────────────────────────────────────
    Rectangle {
        id: card

        anchors {
            top:    parent.top
            right:  parent.right
            topMargin: Theme.barHeight + 8
        }

        width:  340
        implicitHeight: cardLayout.implicitHeight + 24
        radius:         Theme.popupRadius
        color:          Colors.surfaceContainer
        border.color:   Colors.outlineVariant
        border.width:   Theme.popupBorder
        clip:           true

        ColumnLayout {
            id:            cardLayout
            anchors {
                top:              parent.top
                left:             parent.left
                right:            parent.right
                topMargin:        12
                leftMargin:       16
                rightMargin:      16
                bottomMargin:     12
            }
            spacing: 12

            // ── Album art ─────────────────────────────────────────────────────
            Item {
                Layout.fillWidth:   true
                Layout.preferredHeight: width   // square

                visible: win.hasArt

                Rectangle {
                    id:           artMask
                    anchors.fill: parent
                    radius:       10
                    visible:      false
                }

                Image {
                    id:           artImage
                    anchors.fill: parent
                    source:       win.player ? win.player.trackArtUrl : ""
                    fillMode:     Image.PreserveAspectCrop
                    smooth:       true
                    layer.enabled: true
                    layer.effect:  OpacityMask { maskSource: artMask }
                }
            }

            // Placeholder when no art
            Rectangle {
                Layout.fillWidth:       true
                Layout.preferredHeight: width
                visible:                !win.hasArt
                radius:                 10
                color:                  Colors.surfaceContainerHigh

                Text {
                    anchors.centerIn: parent
                    text:             "󰎆"
                    font.family:      Fonts.fontM
                    font.pointSize:   48
                    color:            Colors.on_SurfaceVariant
                }
            }

            // ── Track info ────────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing:          2

                Text {
                    Layout.fillWidth:  true
                    text:              win.player?.trackTitle  ?? "Nothing Playing"
                    color:             Colors.on_Surface
                    font.family:       Fonts.font
                    font.pointSize:    12
                    font.bold:         true
                    elide:             Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text:             win.player?.trackArtist ?? ""
                    color:            Colors.on_SurfaceVariant
                    font.family:      Fonts.font
                    font.pointSize:   10
                    elide:            Text.ElideRight
                    visible:          text !== ""
                }

                Text {
                    Layout.fillWidth: true
                    text:             win.player?.trackAlbum  ?? ""
                    color:            Colors.on_SurfaceVariant
                    font.family:      Fonts.font
                    font.pointSize:   9
                    elide:            Text.ElideRight
                    visible:          text !== ""
                    opacity:          0.7
                }
            }

            // ── Progress bar ──────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing:          4
                visible:          win.player !== null && win.player.positionSupported

                // Scrubber
                Item {
                    Layout.fillWidth:    true
                    Layout.preferredHeight: 16   // hit area taller than visual track

                    property real _trackLen: win.player?.trackLength ?? 0
                    property real _fraction: _trackLen > 0
                                             ? Math.min(win._position / _trackLen, 1.0)
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
                        id: progressFill
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left:           parent.left
                        width:  parent.width * parent._fraction
                        height: 4
                        radius: 2
                        color:  Colors.primary

                        Behavior on width {
                            enabled: !win._seeking
                            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                    }

                    // Thumb
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x:      parent.width * parent._fraction - width / 2
                        width:  12
                        height: 12
                        radius: 6
                        color:  Colors.primary

                        Behavior on x {
                            enabled: !win._seeking
                            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                    }

                    // Seek mouse area
                    MouseArea {
                        anchors.fill: parent
                        enabled:      win.player?.canSeek ?? false
                        cursorShape:  enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onPressed: (mouse) => {
                            win._seeking  = true
                            win._position = (mouse.x / width) * (win.player?.trackLength ?? 0)
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed)
                                win._position = Math.max(0,
                                    Math.min(mouse.x / width, 1.0) * (win.player?.trackLength ?? 0))
                        }
                        onReleased: (mouse) => {
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
                            return "%1:%2".arg(Math.floor(s / 60))
                                         .arg(String(s % 60).padStart(2, "0"))
                        }
                        color:          Colors.on_SurfaceVariant
                        font.family:    Fonts.font
                        font.pointSize: 9
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: {
                            const s = Math.floor((win.player?.trackLength ?? 0) / 1000)
                            return "%1:%2".arg(Math.floor(s / 60))
                                         .arg(String(s % 60).padStart(2, "0"))
                        }
                        color:          Colors.on_SurfaceVariant
                        font.family:    Fonts.font
                        font.pointSize: 9
                    }
                }
            }

            // ── Playback controls ─────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing:          0

                // Shuffle
                Item {
                    Layout.preferredWidth:  36
                    Layout.preferredHeight: 36

                    Rectangle {
                        anchors.centerIn: parent
                        width:  28; height: 28; radius: 14
                        color:  shuffleHover.containsMouse
                                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text:             "󰒞"
                        font.family:      Fonts.fontM
                        font.pointSize:   13
                        color:            (win.player?.shuffle ?? false)
                                          ? Colors.primary
                                          : Colors.on_SurfaceVariant
                    }

                    MouseArea {
                        id:           shuffleHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    if (win.player) win.player.shuffle = !win.player.shuffle
                    }
                }

                Item { Layout.fillWidth: true }

                // Prev
                Item {
                    Layout.preferredWidth:  36
                    Layout.preferredHeight: 36

                    Rectangle {
                        anchors.centerIn: parent
                        width:  28; height: 28; radius: 14
                        color:  prevHover.containsMouse
                                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text:             "󰒮"
                        font.family:      Fonts.fontM
                        font.pointSize:   16
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

                Item { Layout.fillWidth: true }

                // Play / Pause  — larger, primary-colored
                Item {
                    Layout.preferredWidth:  52
                    Layout.preferredHeight: 52

                    Rectangle {
                        anchors.centerIn: parent
                        width:  44; height: 44; radius: 22
                        color:  playHover.containsMouse
                                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.25)
                                : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text:             win.isPlaying ? "󰏤" : "󰐊"
                        font.family:      Fonts.fontM
                        font.pointSize:   20
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

                Item { Layout.fillWidth: true }

                // Next
                Item {
                    Layout.preferredWidth:  36
                    Layout.preferredHeight: 36

                    Rectangle {
                        anchors.centerIn: parent
                        width:  28; height: 28; radius: 14
                        color:  nextHover.containsMouse
                                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text:             "󰒭"
                        font.family:      Fonts.fontM
                        font.pointSize:   16
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

                Item { Layout.fillWidth: true }

                // Loop
                Item {
                    Layout.preferredWidth:  36
                    Layout.preferredHeight: 36

                    Rectangle {
                        anchors.centerIn: parent
                        width:  28; height: 28; radius: 14
                        color:  loopHover.containsMouse
                                ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: {
                            const ls = win.player?.loopState ?? MprisLoopState.None
                            if (ls === MprisLoopState.Track)    return "󰑘"  // repeat-one
                            return "󰑖"                                        // repeat (playlist or none — color tells them apart)
                        }
                        font.family:      Fonts.fontM
                        font.pointSize:   13
                        color: {
                            const ls = win.player?.loopState ?? MprisLoopState.None
                            return ls !== MprisLoopState.None
                                   ? Colors.primary
                                   : Colors.on_SurfaceVariant
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
                            else if (ls === MprisLoopState.Playlist)  win.player.loopState = MprisLoopState.Track
                            else                                       win.player.loopState = MprisLoopState.None
                        }
                    }
                }
            }

            // ── Volume slider ─────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing:          8
                visible:          win.player !== null

                Text {
                    text: {
                        const v = win.player?.volume ?? 0
                        if (v === 0)    return "󰝟"
                        if (v < 0.4)    return "󰕿"
                        if (v < 0.75)   return "󰖀"
                        return "󰕾"
                    }
                    font.family:    Fonts.fontM
                    font.pointSize: 13
                    color:          Colors.on_SurfaceVariant
                }

                // Track bg
                Item {
                    Layout.fillWidth:       true
                    Layout.preferredHeight: 16

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width:  parent.width
                        height: 4
                        radius: 2
                        color:  Colors.surfaceContainerHighest
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left:           parent.left
                        width:  parent.width * (win.player?.volume ?? 0)
                        height: 4
                        radius: 2
                        color:  Colors.secondary

                        Behavior on width {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x:      parent.width * (win.player?.volume ?? 0) - width / 2
                        width:  12
                        height: 12
                        radius: 6
                        color:  Colors.secondary

                        Behavior on x {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor

                        onPressed: (mouse) => {
                            if (win.player)
                                win.player.volume = Math.max(0, Math.min(mouse.x / width, 1.0))
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed && win.player)
                                win.player.volume = Math.max(0, Math.min(mouse.x / width, 1.0))
                        }
                    }
                }

                Text {
                    text:           Math.round((win.player?.volume ?? 0) * 100) + "%"
                    color:          Colors.on_SurfaceVariant
                    font.family:    Fonts.font
                    font.pointSize: 9
                    Layout.preferredWidth: 30
                    horizontalAlignment: Text.AlignRight
                }
            }

        } // ColumnLayout
    } // card
} // PanelWindow

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services
import qs.src.popups.media

PanelWindow {
    id: win

    WlrLayershell.screen: screen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.top: true

    implicitHeight: win.screen ? win.screen.height : 800
    implicitWidth: 600

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore

    visible: slide.windowVisible

    mask: Region {
        x: (win.implicitWidth - mediaCard.width) / 2
        y: Theme.barHeight + 8
        width: mediaCard.width
        height: mediaCard.height
    }

    property var player:
        MediaService.activePlayer

    property bool isPlaying:
        MediaService.isPlaying

    property bool hasArt:
        MediaService.hasArt

    property real _position: 0
    property bool _seeking: false

    Timer {
        interval: 1000
        repeat: true

        running:
            win.player !== null &&
            win.isPlaying &&
            !win._seeking &&
            win.player.positionSupported

        onTriggered: {
            if (!win.player)
                return

            win.player.positionChanged()
            win._position = win.player.position
        }
    }

    Connections {
        target: win.player ?? null

        function onTrackChanged() {
            win._position = 0
        }

        function onPostTrackChanged() {
            win._position = 0
        }

        function onPositionChanged() {
            if (!win._seeking)
                win._position = win.player?.position ?? 0
        }
    }

    PopupSlide {
        id: slide

        anchors.fill: parent

        open: Popups.mediaOpen

        edge: "top"

        onCloseRequested: {
            Popups.mediaOpen = false
        }

        Rectangle {
            id: mediaCard

            width: 560

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: Theme.barHeight + 8

            implicitHeight: 270

            radius: Theme.popupRadius

            color: Colors.surfaceContainer

            border.color: Colors.outlineVariant
            border.width: Theme.popupBorder

            clip: true

            // ─────────────────────────────────────────────────────────────
            // Artwork glow layer
            // ─────────────────────────────────────────────────────────────

            Item {
                anchors.fill: parent

                opacity: win.hasArt ? 0.14 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutCubic
                    }
                }

                Image {
                    id: backgroundArt

                    anchors.fill: parent

                    source:
                        win.hasArt
                        ? win.player.trackArtUrl
                        : ""

                    fillMode: Image.PreserveAspectCrop

                    asynchronous: true

                    smooth: true
                }

                Rectangle {
                    anchors.fill: parent

                    color: Colors.surfaceContainer

                    opacity: 0.82
                }
            }

            // ─────────────────────────────────────────────────────────────
            // Main content
            // ─────────────────────────────────────────────────────────────

            RowLayout {
                anchors.fill: parent

                anchors.margins: 16

                spacing: 16

                // Album artwork
                MediaArt {
                    id: art

                    player: win.player
                    hasArt: win.hasArt

                    Layout.preferredWidth: 192
                    Layout.preferredHeight: 192
                }

                // Right side
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    spacing: 8

                    // Player identity
                    RowLayout {
                        Layout.fillWidth: true

                        Item {
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 7
                            height: 7
                            radius: 3.5

                            color:
                                win.isPlaying
                                ? Colors.primary
                                : Colors.on_SurfaceVariant

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                        }

                        Text {
                            text: MediaService.playerIdentity

                            color: Colors.on_SurfaceVariant

                            font.family: Fonts.font
                            font.pointSize: 8.5
                            font.bold: true

                            elide: Text.ElideRight
                        }
                    }

                    // Track information
                    MediaTrackInfo {
                        player: win.player

                        Layout.fillWidth: true
                    }

                    // Progress
                    MediaProgress {
                        player: win.player

                        position: win._position

                        seeking: win._seeking

                        Layout.fillWidth: true

                        onSeekStarted: (pos) => {
                            win._seeking = true
                            win._position = pos
                        }

                        onSeekMoved: (pos) => {
                            win._position = pos
                        }

                        onSeekReleased: (pos) => {
                            if (win.player && win.player.canSeek)
                                win.player.position = pos

                            win._seeking = false
                        }
                    }

                    // Main transport controls
                    MediaControls {
                        player: win.player

                        isPlaying: win.isPlaying

                        Layout.fillWidth: true
                    }

                    // Volume
                    MediaVolumeRow {
                        player: win.player

                        Layout.fillWidth: true
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}

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

    implicitHeight:
        win.screen
        ? win.screen.height
        : 800

    implicitWidth: 600

    color: "transparent"

    exclusionMode:
        ExclusionMode.Ignore

    visible:
        slide.windowVisible

    mask: Region {
        x:
            (win.implicitWidth -
             mediaCard.width) / 2

        y:
            Theme.barHeight + 8

        width:
            mediaCard.width

        height:
            mediaCard.height
    }

    property var player:
        MediaService.activePlayer

    property bool isPlaying:
        MediaService.isPlaying

    property bool hasArt:
        MediaService.hasArt

    property real _position: 0

    property bool _seeking: false

    property int trackChangeToken: 0

    onPlayerChanged: {
        _position = 0
        trackChangeToken++
    }

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

            if (!win._seeking)
                win._position =
                    win.player.position
        }
    }

    Connections {
        target:
            win.player ?? null

        /*
         * Reset position as soon as MPRIS says
         * the track changed.
         */
        function onTrackChanged() {
            win._position = 0
        }

        /*
         * This is the important one for the visual transition.
         * postTrackChanged occurs after the new metadata/artwork
         * has propagated, so MediaArt won't grab the old cover.
         */
        function onPostTrackChanged() {
            win.trackChangeToken++
        }

        function onPositionChanged() {
            if (!win._seeking)
                win._position =
                    win.player?.position ?? 0
        }
    }

    PopupSlide {
        id: slide

        anchors.fill: parent

        open:
            Popups.mediaOpen

        edge: "top"

        onCloseRequested: {
            Popups.mediaOpen = false
        }

        Rectangle {
            id: mediaCard

            width: 560
            height: 230

            anchors.top: parent.top
            anchors.horizontalCenter:
                parent.horizontalCenter

            anchors.topMargin:
                Theme.barHeight + 8

            radius:
                Theme.popupRadius

            color:
                Colors.surfaceContainer

            border.color:
                Colors.outlineVariant

            border.width:
                Theme.popupBorder

            clip: true

            /*
             * Subtle blurred-art background.
             */
            Item {
                anchors.fill: parent

                opacity:
                    win.hasArt
                    ? 0.14
                    : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 350
                        easing.type:
                            Easing.OutCubic
                    }
                }

                Image {
                    anchors.fill: parent

                    source:
                        win.hasArt
                        ? win.player.trackArtUrl
                        : ""

                    fillMode:
                        Image.PreserveAspectCrop

                    asynchronous: true
                    smooth: true
                }

                Rectangle {
                    anchors.fill: parent

                    color:
                        Colors.surfaceContainer

                    opacity: 0.82
                }
            }

            RowLayout {
                anchors.fill: parent

                anchors.margins: 16

                spacing: 16

                /*
                 * Square artwork. No fillHeight/fillWidth here,
                 * otherwise RowLayout stretches it.
                 */
                MediaArt {
                    id: art

                    player:
                        win.player

                    hasArt:
                        win.hasArt

                    transitionKey:
                        win.trackChangeToken

                    Layout.preferredWidth: 196
                    Layout.preferredHeight: 196

                    Layout.alignment:
                        Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Layout.alignment:
                        Qt.AlignVCenter

                    spacing: 6

                    /*
                     * Player/device identity.
                     */
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18

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
                            text:
                                MediaService.playerIdentity

                            color:
                                Colors.on_SurfaceVariant

                            font.family:
                                Fonts.font

                            font.pointSize: 8.5
                            font.bold: true

                            elide:
                                Text.ElideRight

                            maximumLineCount: 1
                        }
                    }

                    /*
                     * Track metadata.
                     */
                    MediaTrackInfo {
                        player:
                            win.player

                        transitionKey:
                            win.trackChangeToken

                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                    }

                    /*
                     * Progress + timestamps.
                     */
                    MediaProgress {
                        player:
                            win.player

                        position:
                            win._position

                        seeking:
                            win._seeking

                        Layout.fillWidth: true
                        Layout.preferredHeight: 31

                        onSeekStarted: (pos) => {
                            win._seeking = true
                            win._position = pos
                        }

                        onSeekMoved: (pos) => {
                            win._position = pos
                        }

                        onSeekReleased: (pos) => {
                            if (
                                win.player &&
                                win.player.canSeek
                            ) {
                                win.player.position = pos
                            }

                            win._seeking = false
                        }
                    }

                    /*
                     * Shuffle / previous / play / next / repeat.
                     */
                    MediaControls {
                        player:
                            win.player

                        isPlaying:
                            win.isPlaying

                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    /*
                     * Only the speaker icon is visible normally.
                     * Hovering it expands the volume slider.
                     */
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28

                        Item {
                            Layout.fillWidth: true
                        }

                        MediaVolumeRow {
                            player:
                                win.player

                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 24
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects

import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services

Row {
    id: root

    spacing: 0
    visible: MediaService.hasPlayer

    property var player: MediaService.activePlayer
    property bool hasArt: player !== null && player.trackArtUrl !== ""
    property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing ?? false

    PillBase {
        hoverExpand: false
        implicitWidth: contentRow.implicitWidth + Theme.pillPadding

        onClicked: Popups.mediaOpen = !Popups.mediaOpen
        onRightClicked: {
            if (root.player?.canTogglePlaying)
                root.player.togglePlaying()
        }
        onScrolled: (wheel) => {
            if (!root.player?.volumeSupported) return

            const delta = wheel.angleDelta.y / 120
            const step = 0.05

            root.player.volume = Math.max(0, Math.min(1, root.player.volume + delta * step))
        }

        Row {
            id: contentRow

            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            Item {
                width: 20
                height: 20
                visible: root.hasArt

                Rectangle {
                    id: artMask
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                }

                Image {
                    anchors.fill: parent
                    source: root.hasArt ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: artMask
                    }

                    NumberAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 5000
                        loops: Animation.Infinite
                        running: root.isPlaying
                    }
                }
            }

            Text {
                id: trackTitle

                anchors.verticalCenter: parent.verticalCenter
                text: root.player ? (root.player.trackTitle || "Unknown Track") : ""
                color: Colors.primary

                font.pointSize: 10.5
                font.bold: true
                font.family: Fonts.font

                elide: Text.ElideRight
                width: Math.min(implicitWidth, 160)
            }
        }
    }

    Connections {
        target: root.player ?? null

        function onTrackChanged() {
            // intentionally empty
        }
    }
}

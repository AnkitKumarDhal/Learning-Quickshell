import QtQuick
import Quickshell
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Services.Mpris
import "../../../settings"

Rectangle {
    id: mediaPill

    property var players: Mpris.players.values
    property var activePlayer: players.length > 0 ? players[0] : null

    visible: activePlayer !== null

    implicitWidth: layout.implicitWidth + 32
    implicitHeight: 30
    radius: 15
    color: Colors.background

    property bool hasArt: activePlayer && activePlayer.trackArtUrl && activePlayer.trackArtUrl !== ""
    property bool isPlaying: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 10

        // Rotating disc thingy
        Item {
            visible: mediaPill.hasArt
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20

            Rectangle {
                id: mask
                anchors.fill: parent
                radius: width / 2
                visible: false
            }

            Image {
                id: artImage
                anchors.fill: parent
                source: mediaPill.activePlayer ? mediaPill.activePlayer.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: mask
                }

                NumberAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 5000
                    loops: Animation.Infinite
                    running: true
                    paused: !mediaPill.isPlaying
                }
            }
        }

        // Song name
        Text {
            text: mediaPill.activePlayer ? (mediaPill.activePlayer.trackTitle || "Unknown Track") : ""
            color: Colors.primary
            font.pointSize: 11
            font.bold: true
            font.family: Fonts.font

            Layout.maximumWidth: 150
            elide: Text.ElideRight
        }

        RowLayout {
            spacing: 8

            // Previous button
            Text {
                text: "󰒮"
                color: Colors.primary
                font.pointSize: 12
                font.family: Fonts.font
                opacity: prevMouse.containsMouse ? 0.6 : 1.0

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (mediaPill.activePlayer) mediaPill.activePlayer.previous()
                }
            }

            // Play-Pause button
            Text {
                text: mediaPill.isPlaying ? "󰏤" : "󰐊"
                color: Colors.primary
                font.pointSize: 12
                font.family: Fonts.font
                opacity: playMouse.containsMouse ? 0.6 : 1.0

                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (mediaPill.activePlayer) mediaPill.activePlayer.togglePlaying()
                }
            }

            // Next button
            Text {
                text: "󰒭"
                color: Colors.primary
                font.pointSize: 12
                font.family: Fonts.font
                opacity: nextMouse.containsMouse ? 0.6 : 1.0

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (mediaPill.activePlayer) mediaPill.activePlayer.next()
                }
            }
        }
    }
}

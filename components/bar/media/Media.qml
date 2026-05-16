import QtQuick
import QtQml
import Quickshell
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Services.Mpris
import "../../../settings"

RowLayout {
    id: mediaRoot
    spacing: 5

    property var trackedPlayer: null
    // Fallback to the first available player if none are explicitly tracked
    property var activePlayer: trackedPlayer || (Mpris.players.values.length > 0 ? Mpris.players.values[0] : null)

    Instantiator {
        model: Mpris.players
        
        Connections {
            required property var modelData
            target: modelData

            // Switch the tracked player whenever a player starts playing
            function onPlaybackStateChanged() {
                if (modelData.playbackState === MprisPlaybackState.Playing) {
                    mediaRoot.trackedPlayer = modelData
                }
            }

            // Check state immediately when a new player is registered on D-Bus
            Component.onCompleted: {
                if (modelData.playbackState === MprisPlaybackState.Playing) {
                    mediaRoot.trackedPlayer = modelData
                }
            }

            // Clean up the tracker if the active player process gets killed/closed
            Component.onDestruction: {
                if (mediaRoot.trackedPlayer === modelData) {
                    mediaRoot.trackedPlayer = null
                }
            }
        }
    }

    visible: activePlayer !== null

    property bool hasArt: activePlayer && activePlayer.trackArtUrl && activePlayer.trackArtUrl !== ""
    property bool isPlaying: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing

    Rectangle {
        Layout.preferredWidth: prevMouse.containsMouse ? 40 : 30
        Layout.preferredHeight: 30
        radius: 15
        color: Colors.background

        Behavior on Layout.preferredWidth {
            NumberAnimation {
                duration: 150
            }
        }

        Rectangle {
            implicitWidth: prevMouse.containsMouse ? 40 : 30 
            implicitHeight: 30
            radius: 15
            color: Colors.primary
            opacity: prevMouse.containsMouse ? 0.1 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        Text {
            text: "󰒮"
            color: Colors.primary
            anchors.centerIn: parent
            font.pointSize: 12
            font.family: Fonts.font
        }

        MouseArea {
            id: prevMouse
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (mediaRoot.activePlayer) mediaRoot.activePlayer.previous()
        }
    }

    Rectangle {
        Layout.preferredWidth: centerLayout.implicitWidth + 32
        Layout.preferredHeight: 30
        radius: 15
        color: Colors.background

        Rectangle {
            anchors.fill: parent
            implicitWidth: centerLayout.implicitWidth + 32
            implicitHeight: 30
            radius: 15
            color: Colors.primary
            opacity: centerMouse.containsMouse ? 0.05 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        RowLayout {
            id: centerLayout
            anchors.centerIn: parent
            spacing: 10

            // Rotating disc thingy
            Item {
                visible: mediaRoot.hasArt
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
                    source: mediaRoot.activePlayer ? mediaRoot.activePlayer.trackArtUrl : ""
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
                        paused: !mediaRoot.isPlaying
                    }
                }
            }

            // Song name
            Text {
                text: mediaRoot.activePlayer ? (mediaRoot.activePlayer.trackTitle || "Unknown Track") : ""
                color: Colors.primary
                font.pointSize: 11
                font.bold: true
                font.family: Fonts.font
                font.italic: mediaRoot.isPlaying

                Layout.maximumWidth: 150
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: centerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    if (mediaRoot.activePlayer) mediaRoot.activePlayer.togglePlaying()
                } else if (mouse.button === Qt.LeftButton) {
                    console.log("Left mosue button space reserved for dropdown")
                }
            }
        }
    }

    Rectangle {
        Layout.preferredWidth: nextMouse.containsMouse ? 40 : 30
        Layout.preferredHeight: 30
        radius: 15
        color: Colors.background

        Behavior on Layout.preferredWidth {
            NumberAnimation {
                duration: 150
            }
        }

        Rectangle {
            implicitWidth: nextMouse.containsMouse ? 40 : 30 
            implicitHeight: 30
            radius: 15
            color: Colors.primary
            opacity: nextMouse.containsMouse ? 0.1 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 150
                }
            }
        }

        // Next button
        Text {
            text: "󰒭"
            anchors.centerIn: parent
            color: Colors.primary
            font.pointSize: 12
            font.family: Fonts.font
        }

        MouseArea {
            id: nextMouse
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (mediaRoot.activePlayer) mediaRoot.activePlayer.next()
        }
    }
}

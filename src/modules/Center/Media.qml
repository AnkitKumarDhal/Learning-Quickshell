import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects

import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services

Item {
    id: root

    implicitWidth: mediaPill.implicitWidth + (mediaHover.hovered ? controlSize * 2 + controlSpacing * 2 : 0)
    implicitHeight: Theme.pillHeight
    visible: MediaService.hasPlayer

    property var player: MediaService.activePlayer
    property bool hasArt: player !== null && player.trackArtUrl !== ""
    property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing ?? false
    property int controlSize: 30
    property int controlSpacing: 6

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.hoverFadeDuration; easing.type: Easing.OutCubic }
    }

    HoverHandler {
        id: mediaHover
    }

    PillBase {
        id: mediaPill

        anchors.centerIn: parent
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
                    id: artImage
                    anchors.fill: parent
                    source: root.hasArt ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    layer.enabled: true
                    layer.effect: OpacityMask { maskSource: artMask }
                }

                Timer {
                    id: spinTimer
                    interval: 16
                    repeat: true
                    running: root.isPlaying
                    onTriggered: artImage.rotation = (artImage.rotation + (360 * interval / 5000)) % 360
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

    Rectangle {
        id: previousButton

        anchors.verticalCenter: parent.verticalCenter
        x: mediaPill.x - root.controlSpacing - width
        width: root.controlSize
        height: root.controlSize
        radius: width / 2
        color: Colors.background
        opacity: root.player?.canGoPrevious && mediaHover.hovered ? 1 : 0
        scale: root.player?.canGoPrevious && mediaHover.hovered ? 1 : 0.7
        z: 2

        Behavior on opacity { NumberAnimation { duration: Theme.hoverFadeDuration; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.hoverFadeDuration; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Colors.primary
            opacity: previousMouse.containsMouse ? Theme.hoverOpacity : 0

            Behavior on opacity { NumberAnimation { duration: Theme.hoverFadeDuration } }
        }

        Text {
            anchors.centerIn: parent
            text: "󰒮"
            font.family: Fonts.fontM
            font.pointSize: 16
            color: Colors.primary
        }

        MouseArea {
            id: previousMouse

            anchors.fill: parent
            enabled: root.player?.canGoPrevious ?? false
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

            onClicked: {
                if (root.player?.canGoPrevious)
                    root.player.previous()
            }
        }
    }

    Rectangle {
        id: nextButton

        anchors.verticalCenter: parent.verticalCenter
        x: mediaPill.x + mediaPill.width + root.controlSpacing
        width: root.controlSize
        height: root.controlSize
        radius: width / 2
        color: Colors.background
        opacity: root.player?.canGoNext && mediaHover.hovered ? 1 : 0
        scale: root.player?.canGoNext && mediaHover.hovered ? 1 : 0.7
        z: 2

        Behavior on opacity { NumberAnimation { duration: Theme.hoverFadeDuration; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.hoverFadeDuration; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Colors.primary
            opacity: nextMouse.containsMouse ? Theme.hoverOpacity : 0

            Behavior on opacity { NumberAnimation { duration: Theme.hoverFadeDuration } }
        }

        Text {
            anchors.centerIn: parent
            text: "󰒭"
            font.family: Fonts.fontM
            font.pointSize: 16
            color: Colors.primary
        }

        MouseArea {
            id: nextMouse

            anchors.fill: parent
            enabled: root.player?.canGoNext ?? false
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

            onClicked: {
                if (root.player?.canGoNext)
                    root.player.next()
            }
        }
    }
}

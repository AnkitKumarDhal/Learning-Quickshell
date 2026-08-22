import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.src.theme

Item {
    id: root

    required property var player
    required property bool hasArt
    readonly property string artUrl: root.player?.trackArtUrl || ""
    property string previousArt: ""

    property bool initialized: false

    Layout.preferredWidth: 178
    Layout.preferredHeight: 178

    Component.onCompleted: initialized = true

    onArtUrlChanged: {
        if (!root.initialized) return

        previousArt = currentImage.source
        previousImage.source = previousArt
        previousImage.opacity = previousArt !== "" ? 1 : 0

        currentImage.opacity = 0
        currentImage.x = root.width * 0.08

        artworkReadyTimer.restart()
    }

    Timer {
        id: artworkReadyTimer

        interval: 16
        repeat: true

        onTriggered: {
            if (currentImage.status === Image.Ready) {
                stop()
                artworkTransition.restart()
            }
        }
    }

    ParallelAnimation {
        id: artworkTransition

        NumberAnimation {
            target: previousImage
            property: "x"
            to: -root.width * 0.08
            duration: 300
            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            target: previousImage
            property: "opacity"
            to: 0
            duration: 240
            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            target: currentImage
            property: "x"
            to: 0
            duration: 350
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: currentImage
            property: "opacity"
            to: 1
            duration: 320
            easing.type: Easing.OutCubic
        }

        onFinished: {
            previousArt = ""
            previousImage.source = ""
            previousImage.opacity = 0
            previousImage.x = 0

            currentImage.x = 0
            currentImage.opacity = root.hasArt ? 1 : 0
        }
    }

    Rectangle {
        id: currentMask
        anchors.fill: parent
        radius: 12
        visible: false
    }

    Rectangle {
        id: previousMask
        anchors.fill: parent
        radius: 12
        visible: false
    }

    Image {
        id: currentImage

        anchors.fill: parent
        source: root.artUrl
        fillMode: Image.PreserveAspectCrop

        asynchronous: true
        smooth: true
        layer.enabled: true
        layer.effect: OpacityMask { maskSource: currentMask }
        opacity: root.hasArt ? 1 : 0

        x: 0
        z: 2
    }

    Image {
        id: previousImage

        anchors.fill: parent
        source: ""
        fillMode: Image.PreserveAspectCrop

        asynchronous: true
        smooth: true
        layer.enabled: true
        layer.effect: OpacityMask { maskSource: previousMask }
        opacity: 0

        x: 0
        z: 1
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        visible: !root.hasArt

        color: Colors.surfaceContainerHigh
        z: 0

        Text {
            anchors.centerIn: parent
            text: "󰎆"
            font.family: Fonts.fontM
            font.pointSize: 42
            color: Colors.on_SurfaceVariant
        }
    }
}

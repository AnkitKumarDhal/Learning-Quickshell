import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.src.theme

Item {
    id: root

    required property var player
    required property bool hasArt

    property string currentArt: ""

    property bool showingFront: true

    Layout.fillWidth: true
    Layout.fillHeight: true

    Component.onCompleted: {
        currentArt = root.hasArt
                ? root.player.trackArtUrl
                : ""
    }

    Connections {
        target: root.player ?? null

        function onTrackChanged() {
            root.updateArtwork()
        }

        function onPostTrackChanged() {
            root.updateArtwork()
        }
    }

    function updateArtwork() {
        const nextArt =
            root.player?.trackArtUrl ?? ""

        if (nextArt === root.currentArt)
            return

        root.currentArt = nextArt
        root.showingFront = !root.showingFront
    }

    Rectangle {
        id: frontMask

        anchors.fill: parent

        radius: 12

        visible: false
    }

    Rectangle {
        id: backMask

        anchors.fill: parent

        radius: 12

        visible: false
    }

    Image {
        id: frontImage

        anchors.fill: parent

        source:
            root.showingFront
            ? root.currentArt
            : ""

        fillMode: Image.PreserveAspectCrop

        smooth: true

        layer.enabled: true

        layer.effect: OpacityMask {
            maskSource: frontMask
        }

        opacity:
            root.showingFront && root.hasArt
            ? 1
            : 0

        x:
            root.showingFront
            ? 0
            : -18

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Behavior on x {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutCubic
            }
        }
    }

    Image {
        id: backImage

        anchors.fill: parent

        source:
            root.showingFront
            ? ""
            : root.currentArt

        fillMode: Image.PreserveAspectCrop

        smooth: true

        layer.enabled: true

        layer.effect: OpacityMask {
            maskSource: backMask
        }

        opacity:
            !root.showingFront && root.hasArt
            ? 1
            : 0

        x:
            root.showingFront
            ? 18
            : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Behavior on x {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        anchors.fill: parent

        radius: 12

        visible: !root.hasArt

        color: Colors.surfaceContainerHigh

        Text {
            anchors.centerIn: parent

            text: "󰎆"

            font.family: Fonts.fontM
            font.pointSize: 42

            color: Colors.on_SurfaceVariant
        }
    }
}

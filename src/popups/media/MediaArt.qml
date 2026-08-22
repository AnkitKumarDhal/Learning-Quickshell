import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.src.theme

Item {
    id: root

    required property var player
    required property bool hasArt

    property int transitionKey: 0

    property string displayedArt: ""
    property string incomingArt: ""

    property bool showingFront: true
    property bool initialized: false

    Layout.preferredWidth: 196
    Layout.preferredHeight: 196

    Component.onCompleted: {
        initializeArtwork()
        initialized = true
    }

    onPlayerChanged: {
        initializeArtwork()
    }

    onTransitionKeyChanged: {
        if (
            !root.initialized ||
            !root.player
        )
            return

        updateArtwork()
    }

    function initializeArtwork() {
        const nextArt =
            root.player?.trackArtUrl || ""

        artworkTransition.stop()

        displayedArt = nextArt
        incomingArt = ""

        showingFront = true

        frontImage.source = nextArt
        frontImage.opacity =
            nextArt !== ""
            ? 1
            : 0

        frontImage.x = 0

        backImage.opacity = 0
        backImage.x =
            root.width * 0.08
    }

    function updateArtwork() {
        const nextArt =
            root.player?.trackArtUrl || ""

        if (
            nextArt ===
            root.displayedArt
        )
            return

        root.incomingArt = nextArt

        const incoming =
            root.showingFront
            ? backImage
            : frontImage

        const outgoing =
            root.showingFront
            ? frontImage
            : backImage

        /*
         * The incoming layer always receives the newest
         * artwork before the animation starts.
         */
        incoming.source =
            nextArt

        incoming.x =
            root.width * 0.08

        incoming.opacity = 0

        /*
         * Reset the outgoing layer to its current visual
         * starting state in case a previous transition was
         * interrupted.
         */
        outgoing.x = 0
        outgoing.opacity = 1

        artworkTransition.restart()
    }

    ParallelAnimation {
        id: artworkTransition

        NumberAnimation {
            target:
                root.showingFront
                ? frontImage
                : backImage

            property: "x"

            to:
                -root.width * 0.08

            duration: 300

            easing.type:
                Easing.InOutCubic
        }

        NumberAnimation {
            target:
                root.showingFront
                ? frontImage
                : backImage

            property: "opacity"

            to: 0

            duration: 240

            easing.type:
                Easing.InOutCubic
        }

        NumberAnimation {
            target:
                root.showingFront
                ? backImage
                : frontImage

            property: "x"

            to: 0

            duration: 350

            easing.type:
                Easing.OutCubic
        }

        NumberAnimation {
            target:
                root.showingFront
                ? backImage
                : frontImage

            property: "opacity"

            to: 1

            duration: 320

            easing.type:
                Easing.OutCubic
        }

        onFinished: {
            root.showingFront =
                !root.showingFront

            root.displayedArt =
                root.incomingArt

            root.incomingArt = ""

            /*
             * Do NOT clear the previous image source.
             *
             * Both layers retain their last artwork. On the next
             * transition, the hidden layer is simply replaced with
             * the new artwork.
             */
            if (root.showingFront) {
                frontImage.x = 0
                frontImage.opacity =
                    root.hasArt
                    ? 1
                    : 0

                backImage.x =
                    root.width * 0.08

                backImage.opacity = 0
            } else {
                backImage.x = 0
                backImage.opacity =
                    root.hasArt
                    ? 1
                    : 0

                frontImage.x =
                    root.width * 0.08

                frontImage.opacity = 0
            }
        }
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

        fillMode:
            Image.PreserveAspectCrop

        asynchronous: true
        smooth: true

        layer.enabled: true

        layer.effect: OpacityMask {
            maskSource:
                frontMask
        }

        opacity:
            root.hasArt &&
            root.showingFront
            ? 1
            : 0

        x:
            root.showingFront
            ? 0
            : width * 0.08
    }

    Image {
        id: backImage

        anchors.fill: parent

        fillMode:
            Image.PreserveAspectCrop

        asynchronous: true
        smooth: true

        layer.enabled: true

        layer.effect: OpacityMask {
            maskSource:
                backMask
        }

        opacity:
            root.hasArt &&
            !root.showingFront
            ? 1
            : 0

        x:
            root.showingFront
            ? width * 0.08
            : 0
    }

    Rectangle {
        anchors.fill: parent

        radius: 12

        visible:
            !root.hasArt

        color:
            Colors.surfaceContainerHigh

        Text {
            anchors.centerIn:
                parent

            text: "󰎆"

            font.family:
                Fonts.fontM

            font.pointSize: 42

            color:
                Colors.on_SurfaceVariant
        }
    }
}

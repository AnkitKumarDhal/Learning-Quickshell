import QtQuick
import QtQuick.Layouts
import qs.src.theme

Item {
    id: root

    required property var player

    property int transitionKey: 0
    property bool initialized: false

    property string currentTitle: ""
    property string currentArtist: ""
    property string currentAlbum: ""

    property string incomingTitle: ""
    property string incomingArtist: ""
    property string incomingAlbum: ""

    Layout.fillWidth: true
    implicitHeight: 54

    Component.onCompleted: {
        loadCurrentMetadata()
        initialized = true
    }

    onPlayerChanged: {
        if (!root.player) return
        loadCurrentMetadata()
        incomingMetadata.opacity = 0
        incomingMetadata.x = width * 0.06
        currentMetadata.opacity = 1
        currentMetadata.x = 0
    }

    onTransitionKeyChanged: {
        if (!root.initialized || !root.player) return
        animateToCurrentMetadata()
    }

    function loadCurrentMetadata() {
        currentTitle = root.player?.trackTitle || "Nothing Playing"
        currentArtist = root.player?.trackArtist || "Unknown Artist"
        currentAlbum = root.player?.trackAlbum || "Unknown Album"
    }

    function animateToCurrentMetadata() {
        incomingTitle = root.player?.trackTitle || "Nothing Playing"
        incomingArtist = root.player?.trackArtist || "Unknown Artist"
        incomingAlbum = root.player?.trackAlbum || "Unknown Album"
        incomingMetadata.x = width * 0.06
        incomingMetadata.opacity = 0
        metadataTransition.restart()
    }

    ParallelAnimation {
        id: metadataTransition

        NumberAnimation {
            target: currentMetadata
            property: "x"
            to: -root.width * 0.06
            duration: 280
            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            target: currentMetadata
            property: "opacity"
            to: 0
            duration: 220
            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            target: incomingMetadata
            property: "x"
            to: 0
            duration: 330
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: incomingMetadata
            property: "opacity"
            to: 1
            duration: 300
            easing.type: Easing.OutCubic
        }

        onFinished: {
            currentTitle = incomingTitle
            currentArtist = incomingArtist
            currentAlbum = incomingAlbum
            currentMetadata.x = 0
            currentMetadata.opacity = 1
            incomingMetadata.x = width * 0.06
            incomingMetadata.opacity = 0
        }
    }

    ColumnLayout {
        id: currentMetadata

        anchors.fill: parent
        spacing: 1

        Text {
            Layout.fillWidth: true
            text: root.currentTitle

            color: Colors.on_Surface

            font.family: Fonts.font
            font.pointSize: 13
            font.bold: true

            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            Layout.fillWidth: true
            text: root.currentArtist

            color: Colors.on_SurfaceVariant

            font.family: Fonts.font
            font.pointSize: 10

            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            Layout.fillWidth: true
            text: root.currentAlbum

            color: Colors.on_SurfaceVariant

            font.family: Fonts.font
            font.pointSize: 8.5

            elide: Text.ElideRight
            maximumLineCount: 1
            opacity: 0.72
        }
    }

    ColumnLayout {
        id: incomingMetadata

        anchors.fill: parent
        spacing: 2
        x: width * 0.06
        opacity: 0

        Text {
            Layout.fillWidth: true
            text: root.incomingTitle

            color: Colors.on_Surface

            font.family: Fonts.font
            font.pointSize: 13
            font.bold: true

            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            Layout.fillWidth: true
            text: root.incomingArtist

            color: Colors.on_SurfaceVariant

            font.family: Fonts.font
            font.pointSize: 10

            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            Layout.fillWidth: true
            text: root.incomingAlbum

            color: Colors.on_SurfaceVariant

            font.family: Fonts.font
            font.pointSize: 8.5

            elide: Text.ElideRight
            maximumLineCount: 1
            opacity: 0.72
        }
    }
}

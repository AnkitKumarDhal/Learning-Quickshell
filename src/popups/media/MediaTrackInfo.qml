import QtQuick
import QtQuick.Layouts
import qs.src.theme

ColumnLayout {
    id: root

    required property var player

    Layout.fillWidth: true

    spacing: 2

    property int trackKey:
        root.player?.uniqueId ?? 0

    Text {
        id: title

        Layout.fillWidth: true

        text:
            root.player?.trackTitle ||
            "Nothing Playing"

        color: Colors.on_Surface

        font.family: Fonts.font
        font.pointSize: 13
        font.bold: true

        elide: Text.ElideRight

        maximumLineCount: 1
    }

    Text {
        Layout.fillWidth: true

        text:
            root.player?.trackArtist ||
            "Unknown Artist"

        color: Colors.on_SurfaceVariant

        font.family: Fonts.font
        font.pointSize: 10

        elide: Text.ElideRight

        maximumLineCount: 1

        visible: text !== ""
    }

    Text {
        Layout.fillWidth: true

        text:
            root.player?.trackAlbum ||
            "Unknown Album"

        color: Colors.on_SurfaceVariant

        font.family: Fonts.font
        font.pointSize: 8.5

        elide: Text.ElideRight

        maximumLineCount: 1

        opacity: 0.72

        visible: text !== ""
    }

    Connections {
        target: root.player ?? null

        function onPostTrackChanged() {
            root.opacity = 0

            root.x = 10

            metadataAnimation.restart()
        }
    }

    SequentialAnimation {
        id: metadataAnimation

        PropertyAnimation {
            target: root

            property: "opacity"

            from: 0
            to: 1

            duration: 220

            easing.type: Easing.OutCubic
        }

        PropertyAnimation {
            target: root

            property: "x"

            from: 10
            to: 0

            duration: 300

            easing.type: Easing.OutCubic
        }
    }
}

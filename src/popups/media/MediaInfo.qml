import QtQuick
import QtQuick.Layouts
import qs.src.theme
import qs.src.state

ColumnLayout {
    id: root

    property var player: null

    spacing: 1

    // Title
    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        Text {
            text:           "󰎈"
            font.family:    Fonts.fontM
            font.pixelSize: 11
            color:          Colors.primary
        }

        Text {
            Layout.fillWidth: true
            text:             root.player?.trackTitle ?? "Nothing Playing"
            color:            Colors.on_Surface
            font.family:      Fonts.font
            font.pointSize:   11
            font.bold:        true
            elide:            Text.ElideRight
        }
    }

    // Artist
    RowLayout {
        Layout.fillWidth: true
        spacing:          4
        visible:          (root.player?.trackArtist ?? "") !== ""

        Text {
            text:           "󰈠"
            font.family:    Fonts.fontM
            font.pixelSize: 9
            color:          Colors.on_SurfaceVariant
        }

        Text {
            Layout.fillWidth: true
            text:             root.player?.trackArtist ?? ""
            color:            Colors.on_SurfaceVariant
            font.family:      Fonts.font
            font.pointSize:   9
            elide:            Text.ElideRight
        }
    }

    // Album
    RowLayout {
        Layout.fillWidth: true
        spacing:          4
        visible:          (root.player?.trackAlbum ?? "") !== ""

        Text {
            text:           "󰀥"
            font.family:    Fonts.fontM
            font.pixelSize: 9
            color:          Colors.on_SurfaceVariant
            opacity:        0.7
        }

        Text {
            Layout.fillWidth: true
            text:             root.player?.trackAlbum ?? ""
            color:            Colors.on_SurfaceVariant
            font.family:      Fonts.font
            font.pointSize:   9
            elide:            Text.ElideRight
            opacity:          0.7
        }
    }
}

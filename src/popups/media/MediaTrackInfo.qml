import QtQuick
import QtQuick.Layouts
import qs.src.theme

ColumnLayout {
    id: root

    required property var player

    Layout.fillWidth: true
    spacing:          2

    Text {
        Layout.fillWidth: true
        text:             root.player?.trackTitle  || "Nothing Playing"
        color:            Colors.on_Surface
        font.family:      Fonts.font
        font.pointSize:   12
        font.bold:        true
        elide:            Text.ElideRight
    }

    Text {
        Layout.fillWidth: true
        text:             root.player?.trackArtist ?? ""
        color:            Colors.on_SurfaceVariant
        font.family:      Fonts.font
        font.pointSize:   10
        elide:            Text.ElideRight
        visible:          text !== ""
    }

    Text {
        Layout.fillWidth: true
        text:             root.player?.trackAlbum  ?? ""
        color:            Colors.on_SurfaceVariant
        font.family:      Fonts.font
        font.pointSize:   9
        elide:            Text.ElideRight
        visible:          text !== ""
        opacity:          0.7
    }
}

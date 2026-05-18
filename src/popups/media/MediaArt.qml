import QtQuick
import qs.src.theme
import qs.src.state

Rectangle {
    id: root

    property var player:  null
    property bool hasArt: player && player.trackArtUrl !== ""

    radius:       10
    color:        Colors.surfaceContainerHigh
    border.color: Colors.outlineVariant
    border.width: 1
    clip:         true

    Image {
        anchors.fill: parent
        source:       root.hasArt ? root.player.trackArtUrl : ""
        fillMode:     Image.PreserveAspectCrop
        smooth:       true
        visible:      root.hasArt
    }

    Text {
        anchors.centerIn: parent
        visible:          !root.hasArt
        text:             "󰎆"
        font.family:      Fonts.fontM
        font.pointSize:   36
        color:            Colors.on_SurfaceVariant
    }
}

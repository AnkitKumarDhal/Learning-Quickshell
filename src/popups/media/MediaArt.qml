import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.src.theme

Item {
    id: root

    required property var    player
    required property bool   hasArt

    Layout.fillWidth:       true
    Layout.preferredHeight: width   // always square

    Rectangle {
        id:           artMask
        anchors.fill: parent
        radius:       10
        visible:      false
    }

    Image {
        anchors.fill:  parent
        source:        root.hasArt ? root.player.trackArtUrl : ""
        fillMode:      Image.PreserveAspectCrop
        smooth:        true
        visible:       root.hasArt
        layer.enabled: true
        layer.effect:  OpacityMask { maskSource: artMask }
    }

    Rectangle {
        anchors.fill: parent
        visible:      !root.hasArt
        radius:       10
        color:        Colors.surfaceContainerHigh

        Text {
            anchors.centerIn: parent
            text:             "󰎆"
            font.family:      Fonts.fontM
            font.pointSize:   48
            color:            Colors.on_SurfaceVariant
        }
    }
}

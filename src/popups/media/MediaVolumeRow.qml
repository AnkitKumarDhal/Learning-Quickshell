import QtQuick
import QtQuick.Layouts
import qs.src.theme

RowLayout {
    id: root

    required property var player

    Layout.fillWidth: true
    spacing:          8
    visible:          root.player !== null

    Text {
        text: {
            const v = root.player?.volume ?? 0
            if (v === 0)  return "󰝟"
            if (v < 0.4)  return "󰕿"
            if (v < 0.75) return "󰖀"
            return "󰕾"
        }
        font.family:    Fonts.fontM
        font.pointSize: 13
        color:          Colors.on_SurfaceVariant
    }

    Item {
        Layout.fillWidth:       true
        Layout.preferredHeight: 16

        readonly property real vol: root.player?.volume ?? 0

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 4; radius: 2
            color: Colors.surfaceContainerHighest
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left:           parent.left
            width:  parent.width * parent.vol
            height: 4; radius: 2
            color:  Colors.secondary
            Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x:      parent.width * parent.vol - width / 2
            width:  12; height: 12; radius: 6
            color:  Colors.secondary
            Behavior on x { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onPressed: (mouse) => {
                if (root.player)
                    root.player.volume = Math.max(0, Math.min(mouse.x / width, 1.0))
            }
            onPositionChanged: (mouse) => {
                if (pressed && root.player)
                    root.player.volume = Math.max(0, Math.min(mouse.x / width, 1.0))
            }
        }
    }

    Text {
        text:           Math.round((root.player?.volume ?? 0) * 100) + "%"
        color:          Colors.on_SurfaceVariant
        font.family:    Fonts.font
        font.pointSize: 9
        Layout.preferredWidth:   30
        horizontalAlignment:     Text.AlignRight
    }
}

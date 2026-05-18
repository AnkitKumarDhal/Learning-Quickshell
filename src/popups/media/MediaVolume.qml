import QtQuick
import QtQuick.Layouts
import qs.src.theme
import qs.src.state

RowLayout {
    id: root

    property var player: null

    spacing: 8

    // Volume icon
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

    // Slider
    Item {
        Layout.fillWidth:       true
        Layout.preferredHeight: 16

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width:  parent.width
            height: 4; radius: 2
            color:  Colors.surfaceContainerHighest
        }

        Rectangle {
            id: volFill
            anchors.verticalCenter: parent.verticalCenter
            anchors.left:           parent.left
            width:  parent.width * (root.player?.volume ?? 0)
            height: 4; radius: 2
            color:  Colors.secondary

            Behavior on width { NumberAnimation { duration: 80 } }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x:      parent.width * (root.player?.volume ?? 0) - width / 2
            width:  10; height: 10; radius: 5
            color:  Colors.secondary

            Behavior on x { NumberAnimation { duration: 80 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor

            onPressed:         (m) => { if (root.player) root.player.volume = Math.max(0, Math.min(m.x / width, 1.0)) }
            onPositionChanged: (m) => { if (pressed && root.player) root.player.volume = Math.max(0, Math.min(m.x / width, 1.0)) }
        }
    }

    // Percentage
    Text {
        text:                Math.round((root.player?.volume ?? 0) * 100) + "%"
        color:               Colors.on_SurfaceVariant
        font.family:         Fonts.font
        font.pointSize:      9
        Layout.preferredWidth: 28
        horizontalAlignment: Text.AlignRight
    }
}

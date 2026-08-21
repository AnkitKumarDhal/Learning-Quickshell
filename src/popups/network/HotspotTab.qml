import QtQuick
import QtQuick.Layouts

import qs.src.theme

ColumnLayout {
    id: root

    Layout.fillWidth: true
    spacing: 6

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "󰀂"
        font.family: Fonts.fontM
        font.pixelSize: 32
        color: Colors.outline
        topPadding: 12
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Hotspot coming soon"
        font.family: Fonts.font
        font.pixelSize: 11
        color: Colors.outline
        bottomPadding: 12
    }
}

import QtQuick
import Quickshell
import qs.src.components
import qs.src.theme
import qs.src.state

PillBase {
    id: root

    hoverExpand: true
    contentItem: Text{
        text: "󰣇"
        color: Colors.primary
        font.pointSize: 14
        font.family: "JetBrains Mono"
        verticalAlignment: Text.AlignVCenter
    }

    onClicked: Popups.archMenuOpen = !Popups.archMenuOpen
}

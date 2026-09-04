import QtQuick
import Quickshell
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services

PillBase {
    id: root

    required property var screen

    hoverExpand: true

    border.color: Colors.primary
    border.width: Popups.volumeOpen ? 1 : 0
    Behavior on border.width { NumberAnimation { duration: 150 } }

    function getIcon(): string {
        if (VolumeService.muted || VolumeService.volume <= 0.0) return " "
        if (VolumeService.volume >= 0.7) return " "
        if (VolumeService.volume >= 0.3) return " "
        return " "
    }

    Text {
        text: root.getIcon() + " " + Math.round(VolumeService.volume * 100) + "%"
        color: VolumeService.muted ? Colors.error : Colors.primary
        font.pointSize: 11
        font.bold: true
        font.family: Fonts.fontM
        verticalAlignment: Text.AlignVCenter
    }

    onClicked: {
        const wasOpen = Popups.volumeOpen
        Popups.volumeScreen = root.screen
        Popups.volumeAnchorX = root.mapToItem(null, root.width / 2, 0).x
        Popups.volumeOpen = !wasOpen
    }
    onRightClicked: VolumeService.toggleMute()
    onScrolled: (wheel) => {
        VolumeService.changeVolume(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
    }
}

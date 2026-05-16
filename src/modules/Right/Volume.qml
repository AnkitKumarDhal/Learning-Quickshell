import QtQuick
import Quickshell
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services

PillBase {
    id: root

    hoverExpand: true

    function getIcon(): string {
        if (VolumeService.muted || VolumeService.volume <= 0.0) return "󰝟"
        if (VolumeService.volume >= 0.7) return "󰕾"
        if (VolumeService.volume >= 0.3) return "󰖀"
        return "󰕿"
    }

    Text {
        text: root.getIcon() + "  " + Math.round(VolumeService.volume * 100) + "%"
        color: VolumeService.muted ? Colors.error : Colors.primary
        font.pointSize: 11
        font.bold: true
        font.family: Fonts.font
        verticalAlignment: Text.AlignVCenter
    }

    onClicked:      Popups.volumeOpen = !Popups.volumeOpen
    onRightClicked: VolumeService.toggleMute()
    onScrolled: (wheel) => {
        VolumeService.changeVolume(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
    }
}

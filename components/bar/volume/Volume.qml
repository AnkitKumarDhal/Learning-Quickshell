import QtQuick
import Quickshell
import "../../../services"
import "../../../settings"

Rectangle {
    id: volumePill

    implicitWidth: volumeText.implicitWidth + 32
    implicitHeight: 30
    radius: 15
    color: Colors.background

    Rectangle {
        implicitWidth: volumeText.implicitWidth + 32
        implicitHeight: 30
        radius: 15
        color: Colors.primary
        opacity: mouseArea.containsMouse ? 0.10 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }
    }

    function getIcon() {
        if (VolumeService.muted || VolumeService.volume <= 0.0) return "󰝟 ";
        if (VolumeService.volume >= 0.7) return "󰕾 ";
        if (VolumeService.volume >= 0.3) return "󰖀 ";
        return "󰕿 ";
    }

    Text {
        id: volumeText
        anchors.centerIn: parent
        text: volumePill.getIcon() + Math.round(VolumeService.volume * 100) + "%"
        color: VolumeService.muted ? Colors.error : Colors.primary
        font.pixelSize: 15
        font.bold: true
        font.family: Fonts.font
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            VolumeService.toggleMute()
        }

        onWheel: (wheel) => {
            let step = 0.05
            VolumeService.changeVolume(wheel.angleDelta.y > 0 ? step : -step)
        }
    }
}

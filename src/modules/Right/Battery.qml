import QtQuick
import Quickshell
import qs.src.components
import qs.src.theme
import qs.src.services

PillBase {
    id: root

    visible: BatteryService.hasBattery
    hoverExpand: true

    function getIcon(): string {
        if (BatteryService.full)     return "󰁹 "
        if (BatteryService.charging) {
            if (BatteryService.capacity >= 90) return "󰂅 "
            if (BatteryService.capacity >= 80) return "󰂄 "
            if (BatteryService.capacity >= 70) return "󰂃 "
            if (BatteryService.capacity >= 60) return "󰂂 "
            if (BatteryService.capacity >= 50) return "󰂁 "
            if (BatteryService.capacity >= 40) return "󰂀 "
            if (BatteryService.capacity >= 30) return "󰁿 "
            if (BatteryService.capacity >= 20) return "󰁾 "
            if (BatteryService.capacity >= 10) return "󰁽 "
            return "󰁻 "
        }
        if (BatteryService.capacity >= 90) return "󰁹 "
        if (BatteryService.capacity >= 80) return "󰁺 "
        if (BatteryService.capacity >= 60) return "󰁿 "
        if (BatteryService.capacity >= 40) return "󰁼 "
        if (BatteryService.capacity >= 20) return "󰁻 "
        if (BatteryService.capacity >= 10) return "󰁺 "
        return "󰂎 "
    }

    function getColor(): string {
        if (BatteryService.charging || BatteryService.full) return Colors.tertiary
        if (BatteryService.capacity <= 10) return Colors.error
        return Colors.primary
    }

    Text {
        id: batteryText
        text: root.getIcon() + BatteryService.capacity + "%"
        color: root.getColor()
        font.pointSize: 11
        font.bold: true
        font.family: Fonts.font
        verticalAlignment: Text.AlignVCenter

        SequentialAnimation on opacity {
            running: BatteryService.capacity <= 10 && !BatteryService.charging
            loops:   Animation.Infinite

            NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
        }
    }
}

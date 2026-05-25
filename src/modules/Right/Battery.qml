import QtQuick
import Quickshell
import qs.src.components
import qs.src.theme
import qs.src.services

/**
 * Battery indicator pill for the top bar.
 * Displays battery capacity and charging status using Nerd Font icons.
 */
PillBase {
    id: root

    visible: BatteryService.hasBattery
    hoverExpand: true

    Text {
        id: batteryText
        text: BatteryService.getIcon() + BatteryService.capacity + "%"
        color: BatteryService.getColor()
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

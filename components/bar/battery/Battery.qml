import "../../../services"
import "../../../settings"
import QtQuick
import Quickshell

Rectangle {
    id: batteryPill

    visible: BatteryService.hasBattery
    function batteryIcon() : string {
        if (BatteryService.full) {
            return "󰁹 ";
        }
        if (BatteryService.charging) {
            if (BatteryService.capacity >= 90) {
                return "󰂅 ";
            }
            if (BatteryService.capacity >= 80) {
                return "󰂄 ";
            }
            if (BatteryService.capacity >= 70) {
                return "󰂃 ";
            }
            if (BatteryService.capacity >= 60) {
                return "󰂂 ";
            }
            if (BatteryService.capacity >= 50) {
                return "󰂁 ";
            }
            if (BatteryService.capacity >= 40) {
                return "󰂀 ";
            }
            if (BatteryService.capacity >= 30) {
                return "󰁿 ";
            }
            if (BatteryService.capacity >= 20) {
                return "󰁾 ";
            }
            if (BatteryService.capacity >= 10) {
                return "󰁽 ";
            }
            return "󰁻 ";
        }
        if (BatteryService.capacity >= 90) {
            return "󰁹 ";
        }
        if (BatteryService.capacity >= 80) {
            return "󰁺 ";
        }
        if (BatteryService.capacity >= 60) {
            return "󰁿 ";
        }
        if (BatteryService.capacity >= 40) {
            return "󰁼 ";
        }
        if (BatteryService.capacity >= 20) {
            return "󰁻 ";
        }
        if (BatteryService.capacity >= 10) {
            return "󰁺 ";
        }
        return "󰂎 ";
    }

    function batteryColor() : string {
        if (BatteryService.charging || BatteryService.full) {
            return Colors.tertiary;
        }
        if (BatteryService.capacity <= 10) {
            return Colors.error;
        }
        if (BatteryService.capacity <= 25) {
            return Colors.primary;
        }
        return Colors.primary;
    }

    implicitWidth: batteryText.implicitWidth + 32
    implicitHeight: 30
    radius: 15
    color: Colors.background

    Text {
        id: batteryText

        anchors.centerIn: parent
        text: batteryIcon() + BatteryService.capacity + "%"
        color: batteryColor()
        font.pointSize: 11
        font.bold: true
        font.family: Fonts.font

        SequentialAnimation on opacity {
            running: BatteryService.capacity <= 10 && !BatteryService.charging
            loops: Animation.Infinite

            NumberAnimation {
                to: 0.3
                duration: 600
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                to: 1
                duration: 600
                easing.type: Easing.InOutSine
            }
        }
    }
}

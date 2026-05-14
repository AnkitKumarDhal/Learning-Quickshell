import "../../../services"
import "../../../settings"
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    required property var barWindow

    // ── Icon ──────────────────────────────────────────────────────────────
    function batteryIcon() : string {
        if (BatteryService.full)
            return "󰁹";

        if (BatteryService.charging) {
            if (BatteryService.capacity >= 90)
                return "󰂅";

            if (BatteryService.capacity >= 80)
                return "󰂄";

            if (BatteryService.capacity >= 70)
                return "󰂃";

            if (BatteryService.capacity >= 60)
                return "󰂂";

            if (BatteryService.capacity >= 50)
                return "󰂁";

            if (BatteryService.capacity >= 40)
                return "󰂀";

            if (BatteryService.capacity >= 30)
                return "󰁿";

            if (BatteryService.capacity >= 20)
                return "󰁾";

            if (BatteryService.capacity >= 10)
                return "󰁽";

            return "󰁻";
        }
        if (BatteryService.capacity >= 90)
            return "󰁹";

        if (BatteryService.capacity >= 80)
            return "󰁺";

        if (BatteryService.capacity >= 60)
            return "󰁿";

        if (BatteryService.capacity >= 40)
            return "󰁼";

        if (BatteryService.capacity >= 20)
            return "󰁻";

        if (BatteryService.capacity >= 10)
            return "󰁺";

        return "󰂎";
    }

    // ── Colour ────────────────────────────────────────────────────────────
    function batteryColor() : string {
        if (BatteryService.charging || BatteryService.full)
            return Colors.tertiary;

        if (BatteryService.capacity <= 10)
            return Colors.error;

        if (BatteryService.capacity <= 25)
            return Colors.primary;

        return Colors.on_Surface;
    }

    implicitWidth: batteryRow.implicitWidth
    implicitHeight: batteryRow.implicitHeight

    // ── Layout ────────────────────────────────────────────────────────────
    RowLayout {
        id: batteryRow

        spacing: 4

        Text {
            text: root.batteryIcon()
            color: root.batteryColor()
            font.pixelSize: 14
            font.family: "Material Design Icons"

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

        Text {
            text: BatteryService.capacity + "%"
            color: root.batteryColor()
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
        }

    }

    // ── Hover popup ───────────────────────────────────────────────────────
    MouseArea {
        id: hoverArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    PopupWindow {
        anchor.window: root.barWindow
        anchor.rect.x: root.mapToItem(null, 0, 0).x
        anchor.rect.y: root.barWindow.height
        anchor.edges: Edges.Top | Edges.Left
        visible: hoverArea.containsMouse
        implicitWidth: tooltipText.implicitWidth + 16
        implicitHeight: tooltipText.implicitHeight + 10
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Colors.surfaceContainer
            radius: 6

            Text {
                id: tooltipText

                anchors.centerIn: parent
                color: Colors.on_Surface
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
                text: {
                    const state = BatteryService.full ? "Full" : BatteryService.charging ? "Charging" : "Discharging";
                    return BatteryService.capacity + "% — " + state;
                }
            }

        }

    }

}

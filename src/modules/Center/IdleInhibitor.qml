import QtQuick
import QtQuick.Layouts
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services

PillBase {
    id: root

    hoverExpand: true

    border.color: Popups.caffeineOpen ? Colors.primary : "transparent"
    border.width: Popups.caffeineOpen ? 1 : 0

    Behavior on border.width { NumberAnimation { duration: 150 } }

    readonly property string caffeineText: {
        if (!CaffeineService.caffeineActive) return "󰾪 Off"
        if (CaffeineService.infinite) return "󰛨 ∞"
        return "󰛨 " + formatRemaining(CaffeineService.remainingSeconds)
    }

    readonly property color caffeineColor: CaffeineService.caffeineActive ? Colors.tertiary : Colors.outline

    function formatRemaining(totalSeconds) {
        const seconds = Math.max(0, Number(totalSeconds))
        const minutes = Math.floor(seconds / 60)
        const remaining = seconds % 60

        return String(minutes).padStart(2, "0") + ":" + String(remaining).padStart(2, "0")
    }

    Text {
        text: root.caffeineText

        color: root.caffeineColor

        font.pointSize: 11
        font.bold: CaffeineService.caffeineActive
        font.family: Fonts.fontM

        verticalAlignment: Text.AlignVCenter

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 13

        radius: 1

        color: Colors.outlineVariant
        opacity: 0.8
    }

    Text {
        visible: BrightnessService.available
        text: "󰃠 " + BrightnessService.brightness + "%"

        color: Colors.primary

        font.pointSize: 11
        font.bold: true
        font.family: Fonts.fontM

        verticalAlignment: Text.AlignVCenter
    }

    onClicked: { Popups.caffeineOpen = !Popups.caffeineOpen }
    onRightClicked: CaffeineService.cyclePreset()
}

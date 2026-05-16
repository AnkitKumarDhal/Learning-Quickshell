import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.src.components
import qs.src.theme

PillBase {
    id: root

    hoverExpand: false  // fixed width, dots handle their own sizing
    hoverEnabled: false

    onClicked: (mouse) => {
        // find which dot was clicked by x position
        const dotWidth   = 12
        const activeDotW = 30
        let x = mouse.x - Theme.pillPadding / 2
        for (let i = 0; i < root.dotCount; i++) {
            const w = (dotsRow.itemAt(i)?.isActive ? activeDotW : dotWidth)
            if (x <= w + 4 || i == root.dotCount - 1) {
                Hyprland.dispatch("hl.dsp.focus({ workspace = " + (i + 1) + " })")
                return
            }
            x -= w + 8  // 8 = spacing
        }
    }

    property int dotCount: {
        let highest = 3
        let wss = Hyprland.workspaces.values
        for (let i = 0; i < wss.length; i++) {
            if (wss[i].id > highest) highest = wss[i].id
        }
        return highest
    }

    Row {
        id: dotsRow
        spacing: 8

        Repeater {
            model: root.dotCount

            delegate: Rectangle {
                readonly property int wsId: index + 1

                property var hyprWs: {
                    let wss = Hyprland.workspaces.values
                    for (let i = 0; i < wss.length; i++) {
                        if (wss[i].id === wsId) return wss[i]
                    }
                    return null
                }

                readonly property bool isActive:   hyprWs ? hyprWs.active : false
                readonly property bool isOccupied: hyprWs !== null

                width:   isActive ? 30 : 12
                height:  12
                radius:  6
                color:   isActive ? Colors.primary : Colors.outline
                opacity: (isActive || isOccupied) ? 1.0 : 0.3

                Behavior on width  { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                Behavior on color  { ColorAnimation  { duration: 200 } }
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
    }
}

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
                Hyprland.dispatch(`hl.dsp.focus({ workspace = ${i + 1} })`)
                return
            }
            x -= w + Theme.barSpacing  // 8 = spacing
        }
    }

    // Cache workspace data to avoid repeated array conversions
    property var _workspaces: Hyprland.workspaces.values
    on_WorkspacesChanged: _workspaces = Hyprland.workspaces.values

    property int dotCount: {
        let highest = 3
        for (let i = 0; i < _workspaces.length; i++) {
            if (_workspaces[i].id > highest) highest = _workspaces[i].id
        }
        return highest
    }

    Row {
        id: dotsRow
        spacing: Theme.barSpacing

        Repeater {
            model: root.dotCount

            delegate: Rectangle {
                readonly property int wsId: index + 1

                // Cache workspace lookup
                property var hyprWs: {
                    for (let i = 0; i < _workspaces.length; i++) {
                        if (_workspaces[i].id === wsId) return _workspaces[i]
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

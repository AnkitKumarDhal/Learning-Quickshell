import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.src.components
import qs.src.theme

PillBase {
    id: root

    property var screen
    property var monitor: screen ? Hyprland.monitorFor(screen) : null
    property var _cachedWorkspaces: Hyprland.workspaces.values

    property int inactiveWidth: 12
    property int activeWidth: 30
    property int pillHeight: 12
    property int slotSpacing: 4
    property int minimumWorkspaces: 3
    property int maximumWorkspaces: 10

    property int hoveredIndex: -1
    property var hoveredItem: null
    property bool previewVisible: false

    hoverExpand: false
    hoverEnabled: false
    mouseEnabled: false
    horizontalPadding: 24

    property int activeWorkspaceId: {
        if (root.monitor && root.monitor.activeWorkspace) {
            const id = root.monitor.activeWorkspace.id
            if (id >= 1 && id <= root.maximumWorkspaces) return id
        }

        for (let i = 0; i < root._cachedWorkspaces.length; i++) {
            const ws = root._cachedWorkspaces[i]

            if (ws.id >= 1 && ws.id <= root.maximumWorkspaces && ws.active) {
                if (!root.monitor || ws.monitor === root.monitor) return ws.id
            }
        }

        return 1
    }

    property var activeWorkspace: root.workspaceFor(root.activeWorkspaceId)

    property bool activeWorkspaceUrgent: root.activeWorkspace ? root.activeWorkspace.urgent : false
    property bool activeWorkspaceFullscreen: root.activeWorkspace ? root.activeWorkspace.hasFullscreen : false
    property bool activeMonitorFocused: root.monitor ? root.monitor.focused : true

    property int dotCount: {
        let highest = root.minimumWorkspaces

        if (root.activeWorkspaceId > highest) highest = root.activeWorkspaceId

        let wss = root._cachedWorkspaces
        let currentMonitor = root.monitor

        for (let i = 0; i < wss.length; i++) {
            const ws = wss[i]

            if (ws.id < 1 || ws.id > root.maximumWorkspaces) continue
            if (currentMonitor && ws.monitor !== currentMonitor) continue

            if (ws.id > highest) highest = ws.id
        }

        return Math.min(highest, root.maximumWorkspaces)
    }

    function workspaceFor(id) {
        let wss = root._cachedWorkspaces
        let currentMonitor = root.monitor

        for (let i = 0; i < wss.length; i++) {
            const ws = wss[i]

            if (ws.id !== id) continue
            if (currentMonitor && ws.monitor !== currentMonitor) continue

            return ws
        }

        return null
    }

    function remoteWorkspaceFor(id) {
        let wss = root._cachedWorkspaces
        let currentMonitor = root.monitor

        for (let i = 0; i < wss.length; i++) {
            const ws = wss[i]

            if (ws.id !== id) continue
            if (currentMonitor && ws.monitor === currentMonitor) continue

            return ws
        }

        return null
    }

    function windowCount(ws) {
        if (!ws || !ws.toplevels) return 0
        return ws.toplevels.values.length
    }

    function windowTitles(ws) {
        let result = []

        if (!ws || !ws.toplevels) return result

        const windows = ws.toplevels.values
        const limit = Math.min(windows.length, 5)

        for (let i = 0; i < limit; i++) {
            const title = windows[i].title || "Untitled"
            const marker = windows[i].activated ? "• " : "  "
            result.push(marker + title)
        }

        if (windows.length > 5) {
            result.push("  … +" + (windows.length - 5) + " more")
        }

        return result
    }

    function workspaceTooltip(id) {
        const ws = root.workspaceFor(id) || root.remoteWorkspaceFor(id)

        if (!ws) {
            return "Workspace " + id + "\nEmpty"
        }

        const count = root.windowCount(ws)
        const plural = count === 1 ? "window" : "windows"

        let text = "Workspace " + id + "\n"
        text += count + " " + plural

        const titles = root.windowTitles(ws)

        for (let i = 0; i < titles.length; i++) {
            text += "\n" + titles[i]
        }

        return text
    }

    function indexAt(x) {
        for (let i = 0; i < root.dotCount; i++) {
            const item = workspaceRepeater.itemAt(i)

            if (!item) continue

            if (x >= item.x && x <= item.x + item.width) {
                return i
            }
        }

        return -1
    }

    function activateIndex(index) {
        if (index < 0 || index >= root.dotCount) return

        const wsId = index + 1
        const ws = root.workspaceFor(wsId)

        if (ws) {
            ws.activate()
        } else {
            Hyprland.dispatch("workspace " + wsId)
        }
    }

    function switchRelative(direction) {
        if (root.dotCount < 1) return

        let next = root.activeWorkspaceId + direction

        if (next < 1) next = root.dotCount
        if (next > root.dotCount) next = 1

        root.activateIndex(next - 1)
    }

    function updateHover(x) {
        const index = root.indexAt(x)

        if (index === root.hoveredIndex) return

        root.hoveredIndex = index
        root.hoveredItem = index >= 0 ? workspaceRepeater.itemAt(index) : null

        if (index >= 0) {
            previewTimer.restart()
        } else {
            previewTimer.stop()
            root.previewVisible = false
            root.hoveredItem = null
        }
    }

    onDotCountChanged: {
        if (root.hoveredIndex >= root.dotCount) {
            root.hoveredIndex = -1
            root.hoveredItem = null
            root.previewVisible = false
            previewTimer.stop()
        }
    }

    Timer {
        id: previewTimer

        interval: 250
        repeat: false

        onTriggered: {
            if (root.hoveredIndex >= 0 && root.hoveredItem) {
                root.previewVisible = true
                workspaceTooltip.anchor.updateAnchor()
            }
        }
    }

    Item {
        id: workspaceArea

        implicitWidth: dotsRow.width
        implicitHeight: dotsRow.height

        Row {
            id: dotsRow

            spacing: root.slotSpacing
            height: root.pillHeight

            Repeater {
                id: workspaceRepeater

                model: root.dotCount

                delegate: Rectangle {
                    id: dot

                    readonly property int wsId: index + 1

                    property var hyprWs: root.workspaceFor(wsId)
                    property var remoteWs: root.remoteWorkspaceFor(wsId)

                    readonly property bool isActive: root.activeWorkspaceId === wsId
                    readonly property bool isOccupied: hyprWs !== null
                    readonly property bool isRemote: !isOccupied && remoteWs !== null
                    readonly property bool isUrgent: hyprWs ? hyprWs.urgent : false
                    readonly property bool isFullscreen: hyprWs ? hyprWs.hasFullscreen : false
                    readonly property int windows: root.windowCount(hyprWs)
                    readonly property bool isHovered: root.hoveredIndex === index

                    width: isActive ? root.activeWidth : root.inactiveWidth
                    height: root.pillHeight
                    radius: root.pillHeight / 2

                    color: isRemote
                        ? "transparent"
                        : isActive
                            ? Colors.primary
                            : Colors.outline

                    opacity: isRemote
                        ? 0.25
                        : isActive
                            ? (root.activeMonitorFocused ? 1.0 : 0.65)
                            : isOccupied
                                ? 0.65
                                : 0.3

                    border.width: isRemote ? 1 : isFullscreen ? 1 : 0
                    border.color: isRemote
                        ? Colors.outline
                        : Colors.primary

                    Behavior on width {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutExpo
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }

                    Behavior on border.width {
                        NumberAnimation {
                            duration: 150
                        }
                    }

                    scale: isHovered ? 1.05 : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -3

                        visible: dot.isUrgent

                        radius: height / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Colors.error
                        opacity: urgentPulse

                        property real urgentPulse: 0.2

                        SequentialAnimation on urgentPulse {
                            running: dot.isUrgent
                            loops: Animation.Infinite

                            NumberAnimation {
                                to: 0.75
                                duration: 550
                                easing.type: Easing.InOutSine
                            }

                            NumberAnimation {
                                to: 0.2
                                duration: 550
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }

        MouseArea {
            id: interactionArea

            anchors.fill: parent

            hoverEnabled: true
            acceptedButtons: Qt.LeftButton

            cursorShape: Qt.PointingHandCursor

            onEntered: root.updateHover(mouseX)
            onPositionChanged: root.updateHover(mouseX)

            onExited: {
                root.hoveredIndex = -1
                root.hoveredItem = null
                root.previewVisible = false
                previewTimer.stop()
            }

            onClicked: (mouse) => {
                const index = root.indexAt(mouse.x)

                if (index < 0 || index >= root.dotCount) return

                root.activateIndex(index)
            }

            onWheel: (wheel) => {
                const delta = wheel.angleDelta.y !== 0
                    ? wheel.angleDelta.y
                    : wheel.pixelDelta.y

                if (delta === 0) return

                root.switchRelative(delta > 0 ? -1 : 1)
            }
        }
    }

    PopupWindow {
        id: workspaceTooltip

        visible: root.previewVisible

        anchor {
            window: root.QsWindow.window
            adjustment: PopupAdjustment.None
            gravity: Edges.Bottom | Edges.Right

            onAnchoring: {
                if (!root.hoveredItem) return

                const pos = root.QsWindow.contentItem.mapFromItem(
                    root.hoveredItem,
                    root.hoveredItem.width / 2 - workspaceTooltip.width / 2,
                    root.height + 8
                )

                anchor.rect.x = Math.max(
                    8,
                    Math.min(
                        pos.x,
                        root.QsWindow.window.width - workspaceTooltip.width - 8
                    )
                )

                anchor.rect.y = pos.y
            }
        }

        implicitWidth: Math.min(
            300,
            Math.max(
                150,
                workspaceTooltipText.implicitWidth + 20
            )
        )

        implicitHeight: workspaceTooltipText.implicitHeight + 20

        color: "transparent"

        Rectangle {
            anchors.fill: parent

            radius: 8
            color: Colors.surfaceContainerHigh

            border.width: 1
            border.color: Colors.outlineVariant

            Text {
                id: workspaceTooltipText

                anchors.fill: parent
                anchors.margins: 10

                text: root.hoveredIndex >= 0
                    ? root.workspaceTooltip(root.hoveredIndex + 1)
                    : ""

                color: Colors.on_Surface

                font.family: Fonts.font
                font.pixelSize: 11

                wrapMode: Text.WordWrap
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}

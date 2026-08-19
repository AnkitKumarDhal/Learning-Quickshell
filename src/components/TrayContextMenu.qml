import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.src.theme

// Full-screen overlay for the custom tray menu. The visible menu is normal
// QML; nested submenus stay inside the same window via TrayMenuLevel.
PanelWindow {
    id: root

    property var menuHandle: null
    property string itemTitle: ""
    property int menuX: 0
    property int menuY: 0
    property bool menuOpen: false
    property bool closing: false

    readonly property int menuWidth: 272

    visible: menuOpen || closing
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus:
        menuOpen
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onCleared: root.close()
    }

    // The panel deliberately covers the screen while open. This background
    // MouseArea receives only clicks that are not consumed by the menu itself.
    MouseArea {
        id: dismissArea
        anchors.fill: parent
        enabled: root.menuOpen
        z: 0

        acceptedButtons:
            Qt.LeftButton |
            Qt.RightButton |
            Qt.MiddleButton

        onClicked: root.close()
    }

    Timer {
        id: focusTimer
        interval: 30

        onTriggered: {
            if (root.menuOpen)
                focusGrab.active = true
        }
    }

    Timer {
        id: closeTimer
        interval: Theme.animDuration

        onTriggered: {
            root.closing = false
            root.menuHandle = null
            root.itemTitle = ""
        }
    }

    function open(handle, x, y, title) {
        if (!handle)
            return

        closeTimer.stop()

        menuHandle = handle
        itemTitle = title || "Tray"
        menuX = x
        menuY = y + 4
        closing = false
        menuOpen = true

        focusTimer.restart()
    }

    function close() {
        if (!menuOpen && !closing)
            return

        focusTimer.stop()

        menuOpen = false
        closing = true

        focusGrab.active = false
        closeTimer.restart()
    }

    Item {
        id: keyboardHandler
        anchors.fill: parent
        focus: root.menuOpen

        Keys.onEscapePressed: root.close()
    }

    // The menu level owns its own recursive submenu hierarchy. x/y are kept
    // relative to this full-screen panel, which also makes multi-monitor use
    // predictable because the panel is explicitly bound to TopBar's screen.
    Item {
        id: menuContainer

        x: menuCard.x
        y: menuCard.y
        width: menuCard.width
        height: menuCard.height

        visible: root.menuOpen || root.closing

        TrayMenuLevel {
            id: menuCard

            x: 0
            y: 0

            menuHandle: root.menuHandle
            menuTitle: root.itemTitle
            menuWidth: root.menuWidth
            hostWidth: root.width
            hostHeight: root.height
            hostX: menuContainer.x

            property real targetScale:
                root.menuOpen ? 1 : 0.96

            scale: targetScale
            transformOrigin: Item.TopRight

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on targetScale {
                NumberAnimation {
                    duration: Theme.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            opacity: root.menuOpen ? 1 : 0

            onTriggered: root.close()
        }
    }

    // Position the root menu using a width-aware clamping strategy.
    Binding {
        target: menuContainer
        property: "x"

        value: Math.max(
            8,
            Math.min(
                root.menuX - root.menuWidth + 12,
                root.width - root.menuWidth - 8
            )
        )
    }

    Binding {
        target: menuContainer
        property: "y"

        value: Math.max(
            8,
            Math.min(
                root.menuY,
                root.height - menuContainer.height - 8
            )
        )
    }
}

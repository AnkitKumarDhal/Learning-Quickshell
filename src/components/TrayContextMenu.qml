import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.src.theme

PanelWindow {
    id: root

    property var menuHandle: null
    property string itemTitle: ""

    // Point at which the tray menu wants to open.
    property int menuX: 0
    property int menuY: 0

    property bool menuOpen: false
    property bool closing: false

    readonly property int menuWidth: 272
    readonly property int screenMargin: 8

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

        onCleared: {
            root.close()
        }
    }

    /*
     * Clicking anywhere outside the actual menu dismisses it.
     *
     * The menu itself has a higher z value, so its own MouseAreas receive
     * clicks first.
     */
    MouseArea {
        id: dismissArea

        anchors.fill: parent

        enabled: root.menuOpen

        z: 0

        acceptedButtons:
            Qt.LeftButton |
            Qt.RightButton |
            Qt.MiddleButton

        onClicked: {
            root.close()
        }
    }

    Timer {
        id: focusTimer

        interval: 30

        onTriggered: {
            if (root.menuOpen) {
                focusGrab.active = true
                menuCard.resetKeyboard()
                menuCard.forceActiveFocus()
            }
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

    /*
     * Gives QML one event loop turn to populate QsMenuOpener before the
     * initial keyboard selection is calculated.
     */
    Timer {
        id: menuReadyTimer

        interval: 0

        onTriggered: {
            if (!root.menuOpen)
                return

            menuCard.resetKeyboard()
            menuCard.forceActiveFocus()
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
        menuReadyTimer.restart()
    }

    function close() {
        if (!menuOpen && !closing)
            return

        focusTimer.stop()
        menuReadyTimer.stop()

        menuOpen = false
        closing = true

        focusGrab.active = false

        closeTimer.restart()
    }

    Item {
        id: menuContainer

        z: 10

        visible:
            root.menuOpen ||
            root.closing

        width: menuCard.width
        height: menuCard.height

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

            opacity:
                root.menuOpen
                    ? 1
                    : 0

            scale:
                root.menuOpen
                    ? 1
                    : 0.96

            transformOrigin:
                Item.TopRight

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            onTriggered: {
                root.close()
            }
        }
    }

    /*
     * Smart horizontal positioning.
     *
     * Tray is normally on the right side of the screen, so the menu should
     * open towards the left. If the tray/menu is on the other side, it opens
     * towards the right instead.
     */
    Binding {
        target: menuContainer
        property: "x"

        value: {
            const openLeft =
                root.menuX >
                root.width / 2

            const preferredX =
                openLeft
                    ? root.menuX - root.menuWidth + 12
                    : root.menuX - 12

            return Math.max(
                root.screenMargin,
                Math.min(
                    preferredX,
                    root.width -
                    root.menuWidth -
                    root.screenMargin
                )
            )
        }
    }

    /*
     * Smart vertical positioning.
     *
     * Normally the menu opens below the tray. If there isn't enough room,
     * it opens upwards instead.
     */
    Binding {
        target: menuContainer
        property: "y"

        value: {
            const belowY = root.menuY
            const aboveY =
                root.menuY -
                menuContainer.height -
                8

            const fitsBelow =
                belowY +
                menuContainer.height <=
                root.height -
                root.screenMargin

            const preferredY =
                fitsBelow
                    ? belowY
                    : aboveY

            return Math.max(
                root.screenMargin,
                Math.min(
                    preferredY,
                    root.height -
                    menuContainer.height -
                    root.screenMargin
                )
            )
        }
    }
}

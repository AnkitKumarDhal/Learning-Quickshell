import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

import qs.Osd
import qs.services as Services
import qs.modules.bar
import qs.modules.calendar
import qs.modules.network
import qs.modules.control
import qs.modules.media
import qs.modules.system
import qs.modules.launcher
import qs.components

ShellRoot {
    id: root
    NotificationToasts{}
    CalendarWindow{}
    PanelWindow {
        focusable: true
        WlrLayershell.layer: WlrLayer.Bottom
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }
    }
    PanelWindow {
        id: rootPanel
        exclusionMode: ExclusionMode.Ignore
        implicitHeight: screen.height
        implicitWidth: screen.width
        anchors {
            top: true
            bottom: true
            right: true
            left: true
        }
        color: "transparent"
        focusable: true

        Loader {
            id: mediaPanelLoader
            active: false
            anchors.horizontalCenter: parent.horizontalCenter
            sourceComponent: MediaPanel {
                id: mediaPanel
            }
            focus: true
        }

        SystemPanel{
            id: systemPanel
        }

        Loader {
            id: networkPanelLoader
            active: false
            anchors.fill: parent
            sourceComponent: NetworkPanel {
                id: networkPanel
            }
        }

        OsdWindow{}

        PanelWindow {
            implicitHeight: 42
            implicitWidth: 0
            anchors {
                top: true
            }
            color: "transparent"
            mask: rootPanel.mask
        }

        TopBar {
            id: topBar
        }

        LauncherWindow {
            id: launcherWindow
        }

        MouseArea {
            id: launcherTrigger
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: 2
            z: 100
            height: 600

            onEntered: {
                launcherWindow.toggle()
            }

            hoverEnabled: true

            Rectangle {
                anchors.fill: parent
                color: parent.containsMouse ? "#40FFFFFF" : "transparent"
                visible: parent.containsMouse
            }
        }

        Loader {
            active: false
            id: controlCenterLoader
            anchors.fill: parent
            sourceComponent: ControlCenter {
                id: controlCenter
            }
            focus: true
        }

        PowerMenu {
            id: powerMenu
        }

        AvatarPicker {
            id: avatarPicker
        }

        property bool altHeld: false

        mask: Region {
            Region{
                item: mediaPanelLoader.active ? mediaPanelLoader : null
            }
            Region {
                item: systemPanel
            }
            Region {
                item: topBar
            }
            Region {
                item: networkPanelLoader.item && networkPanelLoader.item.visible ? networkPanelLoader.item : null
            }
            Region {
                item: controlCenterLoader.item && controlCenterLoader.item.visible ? controlCenterLoader.item : null
            }
            Region {
                item: launcherTrigger
            }
            Region {
                item: launcherWindow.isOpen ? launcherWindow : null
            }
            Region {
                item: powerMenu.visible ? powerMenu : null
            }
            Region {
                item: avatarPicker
            }
        }
    }

    Connections {
        target: mediaPanelLoader.item
        function onOpenedChanged() {
            if (!mediaPanelLoader.item.opened) {
                closeTimer.start()
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 600
        onTriggered: mediaPanelLoader.active = false
    }

    Connections {
        target: networkPanelLoader.item
        function onOpenedChanged() {
            if (networkPanelLoader.item && !networkPanelLoader.item.opened) {
                closeNetworkTimer.start()
            }
        }
    }

    Timer {
        id: closeNetworkTimer
        interval: 600
        onTriggered: networkPanelLoader.active = false
    }

    Timer {
        id: closeControlCenterTimer
        interval: 600
        onTriggered: controlCenterLoader.active = false
    }

    Connections {
        target: controlCenterLoader.item
        function onOpenedChanged() {
            if (controlCenterLoader.item && !controlCenterLoader.item.opened) {
                closeControlCenterTimer.start()
            }
        }
    }

    IpcHandler {
        target: "mediaPanel"

        function toggle(): void {
            if (!mediaPanelLoader.active) {
                mediaPanelLoader.active = true
                mediaPanelLoader.item.opened = true
            } else {
                mediaPanelLoader.item.opened = !mediaPanelLoader.item.opened
            }
        }
    }

    IpcHandler {
        target: "networkPanel"

        function changeVisible(tab: string): void {
            if (!networkPanelLoader.active)
                networkPanelLoader.active = true

            const panel = networkPanelLoader.item
            if (!panel)
                return

            if (panel.opened) {
                panel.opened = false
                return
            }

            if (tab === "wifi")
                panel.currentTab = 0
            else if (tab === "bluetooth")
                panel.currentTab = 1

            if (tab !== undefined)
                panel.opened = true
            else
                panel.opened = !panel.opened
        }
    }

    IpcHandler {
        target: "controlCenter"
        function changeVisible(): void {
            if (!controlCenterLoader.active) {
                controlCenterLoader.active = true
                controlCenterLoader.item.opened = true
            } else {
                controlCenterLoader.item.opened = !controlCenterLoader.item.opened
            }
        }
    }

    IpcHandler {
        target: "launcherWindow"

        function toggle() {
            launcherWindow.toggle()
        }
    }

    IpcHandler {
        target: "powerMenu"
        function toggle(): void {
            if (!powerMenu.visible) {
                powerMenu.open()
            } else {
                powerMenu.close()
            }
        }
    }

    IpcHandler {
        target: "avatarPicker"
        function toggle(): void {
            if (!avatarPicker.opened) {
                avatarPicker.open()
            } else {
                avatarPicker.close()
            }
        }
    }
}

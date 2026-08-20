import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.src.services
import qs.src.state
import qs.src.theme

PanelWindow {
    id: root

    required property var screen

    screen: root.screen

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay

    // Only the focused monitor should show the session menu.
    readonly property bool isFocusedScreen: {
        const monitor = root.screen
            ? Hyprland.monitorFor(root.screen)
            : null

        return monitor ? monitor.focused : false
    }

    // ── Visual dimensions ────────────────────────────────────────────────────

    readonly property int cardSize: 470
    readonly property real buttonRadius: 150

    // ── Actions ───────────────────────────────────────────────────────────────

    readonly property var actions: [
        {
            key: "lock",
            label: "Lock",
            icon: "",
            angle: -90
        },
        {
            key: "logout",
            label: "Logout",
            icon: "",
            angle: -30
        },
        {
            key: "hibernate",
            label: "Hibernate",
            icon: "",
            angle: 30
        },
        {
            key: "reboot",
            label: "Reboot",
            icon: "",
            angle: 90
        },
        {
            key: "poweroff",
            label: "Power Off",
            icon: "",
            angle: 150
        },
        {
            key: "suspend",
            label: "Suspend",
            icon: "",
            angle: 210
        }
    ]

    property int selectedIndex: 0

    // ── Delayed visibility ────────────────────────────────────────────────────

    property bool _shouldShow: false
    property bool _visualOpen: false

    visible:
        root._shouldShow &&
        root.isFocusedScreen

    WlrLayershell.keyboardFocus:
        root._shouldShow &&
        root.isFocusedScreen
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

    Connections {
        target: Popups

        function onSessionOpenChanged() {
            if (Popups.sessionOpen) {
                closeDelay.stop()

                root._shouldShow = true
                root._visualOpen = false

                root.selectedIndex = 0

                openVisualTimer.start()
                focusTimer.start()
            } else {
                root._visualOpen = false
                closeDelay.restart()
            }
        }
    }

    Timer {
        id: openVisualTimer

        interval: 30
        repeat: false

        onTriggered: {
            root._visualOpen = true
        }
    }

    Timer {
        id: focusTimer

        interval: 90
        repeat: false

        onTriggered: {
            keyFocus.forceActiveFocus()
        }
    }

    Timer {
        id: closeDelay

        interval: Theme.animDuration + 70
        repeat: false

        onTriggered: {
            if (!Popups.sessionOpen)
                root._shouldShow = false
        }
    }

    Component.onCompleted: {
        if (Popups.sessionOpen) {
            root._shouldShow = true
            root._visualOpen = false

            root.selectedIndex = 0

            openVisualTimer.start()
            focusTimer.start()
        }
    }

    // ── Keyboard input ────────────────────────────────────────────────────────

    Item {
        id: keyFocus

        anchors.fill: parent

        focus: root._shouldShow

        Keys.onEscapePressed: (event) => {
            Popups.sessionOpen = false
            event.accepted = true
        }

        Keys.onReturnPressed: (event) => {
            root.activateSelected()
            event.accepted = true
        }

        Keys.onEnterPressed: (event) => {
            root.activateSelected()
            event.accepted = true
        }

        Keys.onSpacePressed: (event) => {
            root.activateSelected()
            event.accepted = true
        }

        Keys.onLeftPressed: (event) => {
            root.moveSelection(-1)
            event.accepted = true
        }

        Keys.onRightPressed: (event) => {
            root.moveSelection(1)
            event.accepted = true
        }

        Keys.onUpPressed: (event) => {
            root.moveSelection(-2)
            event.accepted = true
        }

        Keys.onDownPressed: (event) => {
            root.moveSelection(2)
            event.accepted = true
        }

        Keys.onTabPressed: (event) => {
            root.moveSelection(1)
            event.accepted = true
        }

        Keys.onBacktabPressed: (event) => {
            root.moveSelection(-1)
            event.accepted = true
        }
    }

    function moveSelection(delta) {
        const count = root.actions.length

        root.selectedIndex =
            (root.selectedIndex + delta + count) % count
    }

    function activateSelected() {
        root.activate(root.selectedIndex)
    }

    function activate(index) {
        if (index < 0 || index >= root.actions.length)
            return

        const action = root.actions[index]

        if (!action || !action.key)
            return

        SessionService.perform(action.key)

        Popups.sessionOpen = false
    }

    // ── Fullscreen dim backdrop ───────────────────────────────────────────────

    Rectangle {
        anchors.fill: parent

        color: Qt.rgba(0, 0, 0, 0.60)

        opacity:
            root._visualOpen
                ? 1
                : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animDuration
                easing.type: Easing.InOutCubic
            }
        }

        MouseArea {
            anchors.fill: parent

            onClicked: {
                Popups.sessionOpen = false
            }
        }
    }

    // ── Center card ──────────────────────────────────────────────────────────

    Rectangle {
        id: card

        width: root.cardSize
        height: root.cardSize

        anchors.centerIn: parent

        z: 10

        radius: 34

        color: Colors.surfaceContainer

        border.width: Theme.popupBorder

        border.color: Colors.outlineVariant

        opacity:
            root._visualOpen
                ? 1
                : 0

        scale:
            root._visualOpen
                ? 1
                : 0.90

        Behavior on opacity {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutBack
            }
        }

        // ── Center title ──────────────────────────────────────────────────────

        Column {
            anchors.centerIn: parent

            spacing: 4

            z: 5

            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: "Session"

                color: Colors.on_Surface

                font.family: Fonts.font
                font.pixelSize: 17
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: "Power & session"

                color: Colors.on_SurfaceVariant

                font.family: Fonts.font
                font.pixelSize: 10
            }
        }

        // ── Radial action buttons ────────────────────────────────────────────

        Repeater {
            model: root.actions

            delegate: Item {
                id: actionItem

                required property var modelData
                required property int index

                width: 128
                height: 116

                z: 20

                readonly property real angleRadians:
                    modelData.angle * Math.PI / 180

                readonly property real targetCenterX:
                    card.width / 2 +
                    Math.cos(angleRadians) * root.buttonRadius

                readonly property real targetCenterY:
                    card.height / 2 +
                    Math.sin(angleRadians) * root.buttonRadius

                readonly property real closedCenterX:
                    card.width / 2

                readonly property real closedCenterY:
                    card.height / 2

                x:
                    root._visualOpen
                        ? targetCenterX - width / 2
                        : closedCenterX - width / 2

                y:
                    root._visualOpen
                        ? targetCenterY - height / 2
                        : closedCenterY - height / 2

                opacity:
                    root._visualOpen
                        ? 1
                        : 0

                scale:
                    root._visualOpen
                        ? root.selectedIndex === index
                            ? 1.07
                            : 1
                        : 0.72

                Behavior on x {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: 30 + actionItem.index * 28
                        }

                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Behavior on y {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: 30 + actionItem.index * 28
                        }

                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: 30 + actionItem.index * 28
                        }

                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                // ── Circular icon button ─────────────────────────────────────

                Rectangle {
                    id: button

                    width: 100
                    height: 100

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top

                    radius: width / 2

                    readonly property bool selected:
                        root.selectedIndex === actionItem.index

                    readonly property bool destructive:
                        actionItem.modelData.key === "poweroff"

                    color:
                        selected
                            ? destructive
                                ? Colors.error
                                : Colors.primary
                            : Colors.surfaceContainerHigh

                    border.width:
                        selected
                            ? 2
                            : 1

                    border.color:
                        selected
                            ? destructive
                                ? Colors.error
                                : Colors.primary
                            : Colors.outlineVariant

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Column {
                        anchors.centerIn: parent

                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter

                            text: actionItem.modelData.icon

                            color:
                                button.selected
                                    ? button.destructive
                                        ? Colors.on_Error
                                        : Colors.on_Primary
                                    : Colors.on_Surface

                            font.family: "SpaceMono Nerd Font"
                            font.pixelSize: 30

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        hoverEnabled: true

                        onEntered: {
                            root.selectedIndex = actionItem.index
                        }

                        onPressed: {
                            root.selectedIndex = actionItem.index
                        }

                        onClicked: {
                            root.activate(actionItem.index)
                        }
                    }
                }

                // ── Action label ─────────────────────────────────────────────

                Text {
                    anchors {
                        top: button.bottom
                        topMargin: 8
                        horizontalCenter: button.horizontalCenter
                    }

                    text: actionItem.modelData.label

                    color:
                        root.selectedIndex === actionItem.index
                            ? actionItem.modelData.key === "poweroff"
                                ? Colors.error
                                : Colors.on_Surface
                            : Colors.on_SurfaceVariant

                    font.family: Fonts.font
                    font.pixelSize: 12
                    font.bold: root.selectedIndex === actionItem.index

                    horizontalAlignment: Text.AlignHCenter

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
            }
        }
    }
}

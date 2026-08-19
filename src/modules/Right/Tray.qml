import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.src.components
import qs.src.theme

PillBase {
    id: root

    property var window

    // The tray is a single compact control until the user expands it.
    property bool collapsed: true
    property int iconSize: 20
    property int iconSpacing: 8
    property int toggleWidth: 28
    property int trayCount: SystemTray.items.values.length

    hoverExpand: false
    hoverEnabled: false
    mouseEnabled: false

    // A tray pill should disappear completely when there is nothing to show.
    visible: trayCount > 0

    function toggleCollapsed() {
        collapsed = !collapsed
    }

    RowLayout {
        id: trayLayout
        spacing: root.iconSpacing

        // Expand / collapse control.
        Item {
            id: toggleArea
            Layout.preferredWidth: root.toggleWidth
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: toggleMouse.containsMouse ? Colors.primaryContainer : "transparent"
                opacity: toggleMouse.containsMouse ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.hoverFadeDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.collapsed ? "⌄" : "⌃"
                color: Colors.primary
                font.family: Fonts.font
                font.pixelSize: 16
                font.bold: true
            }

            // Show how many icons are hidden while collapsed.
            Rectangle {
                visible: root.collapsed && root.trayCount > 0
                anchors.right: parent.right
                anchors.rightMargin: -1
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -4
                width: root.trayCount > 9 ? 16 : 12
                height: 12
                radius: 6
                color: Colors.primary

                Text {
                    anchors.fill: parent
                    text: root.trayCount > 9 ? "9+" : String(root.trayCount)
                    color: Colors.on_Primary
                    font.family: Fonts.font
                    font.pixelSize: 8
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            MouseArea {
                id: toggleMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleCollapsed()
            }
        }

        // The actual tray icons. They remain instantiated while collapsed so
        // an application can appear/disappear without rebuilding the tray.
        RowLayout {
            id: iconRow
            Layout.preferredWidth: root.collapsed ? 0 : implicitWidth
            Layout.preferredHeight: 24
            spacing: root.iconSpacing
            clip: true

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: Theme.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model: SystemTray.items.values

                delegate: Item {
                    id: trayDelegate
                    required property var modelData

                    Layout.preferredWidth: root.iconSize
                    Layout.preferredHeight: root.iconSize
                    Layout.alignment: Qt.AlignVCenter

                    readonly property bool needsAttention:
                        modelData.status === Status.NeedsAttention

                    readonly property bool hasTooltip:
                        Boolean(
                            modelData.tooltipTitle ||
                            modelData.tooltipDescription ||
                            modelData.title
                        )

                    Rectangle {
                        id: iconHover
                        anchors.fill: parent
                        radius: 7
                        color: hoverArea.containsMouse ? Colors.primary : "transparent"
                        opacity: hoverArea.containsMouse ? 0.12 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.hoverFadeDuration
                            }
                        }
                    }

                    Image {
                        id: trayIcon
                        anchors.centerIn: parent
                        width: root.iconSize
                        height: root.iconSize
                        source: modelData.icon || ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }

                    // Fallback for tray entries with a missing/broken icon.
                    Text {
                        visible:
                            modelData.icon === "" ||
                            trayIcon.status === Image.Error

                        anchors.centerIn: parent
                        text: "◈"
                        color: Colors.on_SurfaceVariant
                        font.family: Fonts.font
                        font.pixelSize: 13
                    }

                    // NeedsAttention is deliberately represented without
                    // recolouring the application's own tray icon.
                    Rectangle {
                        id: attentionDot
                        visible: trayDelegate.needsAttention
                        width: 6
                        height: 6
                        radius: 3
                        anchors.right: parent.right
                        anchors.top: parent.top
                        color: Colors.error
                        border.width: 1
                        border.color: Colors.background

                        SequentialAnimation on opacity {
                            running: trayDelegate.needsAttention
                            loops: Animation.Infinite

                            NumberAnimation {
                                to: 0.35
                                duration: 650
                                easing.type: Easing.InOutSine
                            }

                            NumberAnimation {
                                to: 1.0
                                duration: 650
                                easing.type: Easing.InOutSine
                            }
                        }
                    }

                    // Lightweight in-bar tooltip. This avoids another popup
                    // window while still exposing the tray item's metadata.
                    Rectangle {
                        id: tooltip
                        visible:
                            trayDelegate.hasTooltip &&
                            hoverArea.containsMouse

                        z: 100
                        x: Math.max(
                            -80,
                            Math.min(-20, (parent.width - width) / 2)
                        )
                        y: parent.height + 7
                        width: Math.min(
                            260,
                            Math.max(120, tooltipText.implicitWidth + 20)
                        )
                        height: tooltipText.implicitHeight + 14
                        radius: 8
                        color: Colors.surfaceContainerHigh
                        border.width: 1
                        border.color: Colors.outlineVariant
                        opacity: visible ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.hoverFadeDuration
                            }
                        }

                        Text {
                            id: tooltipText
                            anchors.fill: parent
                            anchors.margins: 10
                            text:
                                modelData.tooltipTitle ||
                                modelData.tooltipDescription ||
                                modelData.title ||
                                ""

                            color: Colors.on_Surface
                            font.family: Fonts.font
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        acceptedButtons:
                            Qt.LeftButton |
                            Qt.RightButton |
                            Qt.MiddleButton

                        onClicked: (mouse) => {
                            if (mouse.button === Qt.LeftButton) {
                                if (modelData.onlyMenu && modelData.hasMenu) {
                                    root.openTrayMenu(modelData, trayDelegate)
                                } else {
                                    modelData.activate()
                                }
                            } else if (mouse.button === Qt.MiddleButton) {
                                modelData.secondaryActivate()
                            } else if (mouse.button === Qt.RightButton) {
                                root.openTrayMenu(modelData, trayDelegate)
                            }
                        }

                        onWheel: (wheel) => {
                            const horizontal =
                                Math.abs(wheel.angleDelta.x) >
                                Math.abs(wheel.angleDelta.y)

                            const delta =
                                horizontal
                                    ? wheel.angleDelta.x
                                    : wheel.angleDelta.y

                            modelData.scroll(
                                delta > 0 ? 1 : -1,
                                horizontal
                            )
                        }
                    }
                }
            }
        }
    }

    // The custom menu is completely separate from the bar's layout.
    TrayContextMenu {
        id: trayMenu
        screen: root.window ? root.window.screen : null
    }

    function openTrayMenu(item, delegate) {
        if (!item || !item.hasMenu)
            return

        if (!root.window)
            return

        const p = root.window.contentItem.mapFromItem(
            delegate,
            delegate.width / 2,
            delegate.height
        )

        trayMenu.open(
            item.menu,
            p.x,
            p.y,
            item.title || "Tray"
        )
    }
}

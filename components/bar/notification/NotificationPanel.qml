import QtQuick
import Quickshell
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../../services"
import "../../../settings"

PanelWindow {
    id: notifPanel

    property var screen
    visible: NotificationService.panelVisible

    anchors {
        top: true
        right: true
    }

    margins {
        right: 8
    }

    implicitWidth: 350
    implicitHeight: panelContent.implicitHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    HyprlandFocusGrab {
        id: focusGrab
        windows: [notifPanel]
        onCleared: NotificationService.panelVisible = false
    }

    onVisibleChanged: focusGrab.active = visible

    Rectangle {
        id: panelContent
        width: parent.width
        implicitHeight: col.implicitHeight + 16
        color: Colors.background
        radius: 14
        border.color: Colors.primary
        border.width: 1

        ColumnLayout {
            id: col
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 8
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 2

            // Header row
            Item {
                Layout.fillWidth: true
                height: 36

                // Accent bar
                Rectangle {
                    width: 3
                    height: 16
                    radius: 2
                    color: Colors.primary
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        text: "Notifications"
                        color: Colors.primary
                        font.family: Fonts.font
                        font.bold: true
                        font.pixelSize: 13
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Item {
                        id: clearBtn
                        visible: NotificationService.notifications.length > 0
                        implicitWidth: clearLabel.implicitWidth + 16
                        height: 28

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: Colors.primary
                            opacity: clearHover.containsMouse ? 0.15 : 0

                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        Text {
                            id: clearLabel
                            anchors.centerIn: parent
                            text: "Clear all"
                            color: Colors.primary
                            font.family: Fonts.font
                            font.bold: true
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: clearHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationService.clearAll()
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                height: 1
                color: Colors.primary
                opacity: 0.2
                visible: NotificationService.notifications.length > 0
            }

            // Empty state
            Item {
                Layout.fillWidth: true
                height: 36
                visible: NotificationService.notifications.length === 0

                Text {
                    anchors.centerIn: parent
                    text: "No notifications"
                    color: Colors.primary
                    opacity: 0.4
                    font.family: Fonts.font
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            // Notification items
            Repeater {
                model: NotificationService.server.trackedNotifications.values

                delegate: Item {
                    id: notifItem
                    required property var modelData

                    Layout.fillWidth: true
                    height: notifRow.implicitHeight + 20

                    Rectangle {
                        id: notifHighlight
                        anchors.fill: parent
                        radius: 8
                        color: Colors.primary
                        opacity: notifMouse.containsMouse ? 0.15 : 0

                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    Rectangle {
                        visible: notifMouse.containsMouse
                        width: 3
                        height: 16
                        radius: 2
                        color: Colors.primary
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    ColumnLayout {
                        id: notifRow
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.topMargin: 10
                        anchors.bottomMargin: 10
                        anchors.leftMargin: 16
                        anchors.rightMargin: 12
                        spacing: 3

                        Text {
                            text: modelData.summary
                            color: Colors.primary
                            font.bold: true
                            font.family: Fonts.font
                            font.pixelSize: 13
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.body
                            color: Colors.primary
                            opacity: 0.7
                            font.family: Fonts.font
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 5
                            elide: Text.ElideRight
                            visible: modelData.body !== ""
                        }
                    }

                    MouseArea {
                        id: notifMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.dismiss()
                    }
                }
            }

            // Bottom padding item
            Item { height: 4; Layout.fillWidth: true }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services
import qs.src.popups.notifications

PanelWindow {
    id: root

    color: "transparent"

    anchors {
        top: true
        right: true
    }

    implicitWidth: 380
    implicitHeight: root.screen ? root.screen.height : 800

    exclusionMode: ExclusionMode.Ignore
    screen: NotificationService.panelScreen
    WlrLayershell.layer: WlrLayer.Overlay
    visible: slidePanel.windowVisible

    mask: Region {
        x: panelCard.x
        y: panelCard.y
        width: panelCard.width
        height: panelCard.height
    }

    PopupSlide {
        id: slidePanel

        anchors.fill: parent
        edge: "right"
        open: Popups.notificationsOpen

        onCloseRequested: Popups.notificationsOpen = false

        Rectangle {
            id: panelCard

            anchors {
                top: parent.top
                right: parent.right
                topMargin: Theme.barHeight + 2
                rightMargin: Theme.barMargin
            }

            width: 360
            height: Math.min(notifList.implicitHeight + 48, root.implicitHeight - Theme.barHeight - 24)

            radius: Theme.popupRadius
            color: Colors.background
            border.color: Colors.outlineVariant
            border.width: Theme.popupBorder

            clip: true

            Rectangle {
                id: panelHeader
                z: 10

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                height: 48

                color: "transparent"

                RowLayout {
                    anchors {
                        fill: parent

                        topMargin: 8
                        leftMargin: 16
                        rightMargin: 16
                        bottomMargin: 8
                    }

                    Text {
                        text: "Notifications"

                        color: Colors.on_Surface

                        font.pixelSize: 14
                        font.bold: true
                        font.family: Fonts.font

                        Layout.fillWidth: true

                        textFormat: Text.PlainText
                    }

                    Rectangle {
                        visible: NotificationService.notificationCount > 0

                        width: 90
                        height: 26

                        radius: 13

                        color: "transparent"

                        border.color: Colors.outline
                        border.width: 1

                        Rectangle {
                            anchors.fill: parent
                            radius: 13
                            color: Colors.primary
                            opacity: clearHover.containsMouse ? 0.25 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Clear all"
                            color: Colors.on_Surface
                            font.pixelSize: 11
                            font.family: Fonts.font
                            textFormat: Text.PlainText
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

                Rectangle {
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                    }

                    height: 1
                    color: Colors.outlineVariant
                    opacity: 0.5
                }
            }

Item {
    anchors {
        top: panelHeader.bottom
        left: parent.left
        right: parent.right
        bottom: parent.bottom
    }

    ListView {
        id: notifList

        anchors.fill: parent

        clip: true
        boundsBehavior: Flickable.StopAtBounds
        spacing: 4
        topMargin: 8
        bottomMargin: 8
        leftMargin: 8
        rightMargin: 8

        model: NotificationService.notificationsModel
        verticalLayoutDirection: ListView.BottomToTop

        delegate: NotificationCard {
            required property var modelData

            width: notifList.width - notifList.leftMargin - notifList.rightMargin
            notification: modelData
            bodyMaximumLineCount: 3
        }
    }

    Item {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 8
        }

        visible: NotificationService.notificationCount === 0
        height: 80

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "󰂚"
                font.pixelSize: 28
                font.family: Fonts.font
                color: Colors.outline
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No notifications"
                font.pixelSize: 12
                font.family: Fonts.font
                color: Colors.outline
                textFormat: Text.PlainText
            }
        }
    }
}        }
    }
}

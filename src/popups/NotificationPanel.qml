import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services

PanelWindow {
    id: root

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        right: true
    }

    implicitWidth: 380

    implicitHeight:
        root.screen
            ? root.screen.height
            : 800

    screen: NotificationService.panelScreen

    WlrLayershell.layer: WlrLayer.Overlay

    visible: slidePanel.windowVisible

    // The mask follows the actual animated panel card.
    mask: Region {
        item: panelCard
    }

    PopupSlide {
        id: slidePanel

        anchors.fill: parent

        edge: "right"

        open: Popups.notificationsOpen

        onCloseRequested:
            Popups.notificationsOpen = false

        Rectangle {
            id: panelCard

            anchors {
                top: parent.top
                right: parent.right

                topMargin: Theme.barHeight + 2
                rightMargin: Theme.barMargin
            }

            width: 360

            height: Math.min(
                notifCol.implicitHeight + 48,
                root.implicitHeight - Theme.barHeight - 24
            )

            radius: Theme.popupRadius

            color: Colors.background

            border.color: Colors.outlineVariant
            border.width: Theme.popupBorder

            clip: true

            // ── Header ───────────────────────────────────────────────────────

            Rectangle {
                id: panelHeader

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
                        visible:
                            NotificationService.notificationCount > 0

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

                            opacity:
                                clearHover.containsMouse
                                    ? 0.25
                                    : 0

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

                            cursorShape:
                                Qt.PointingHandCursor

                            onClicked:
                                NotificationService.clearAll()
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

            // ── Notification list ────────────────────────────────────────────

            Flickable {
                anchors {
                    top: panelHeader.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                contentHeight:
                    notifCol.implicitHeight

                clip: true

                boundsBehavior:
                    Flickable.StopAtBounds

                Column {
                    id: notifCol

                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }

                    spacing: 4

                    padding: 8

                    // ── Empty state ──────────────────────────────────────────

                    Item {
                        visible:
                            NotificationService.notificationCount === 0

                        width: parent.width - 16
                        height: 80

                        ColumnLayout {
                            anchors.centerIn: parent

                            spacing: 6

                            Text {
                                Layout.alignment:
                                    Qt.AlignHCenter

                                text: "󰂚"

                                font.pixelSize: 28
                                font.family: Fonts.font

                                color: Colors.outline
                            }

                            Text {
                                Layout.alignment:
                                    Qt.AlignHCenter

                                text: "No notifications"

                                font.pixelSize: 12
                                font.family: Fonts.font

                                color: Colors.outline

                                textFormat: Text.PlainText
                            }
                        }
                    }

                    // ── Notification entries ─────────────────────────────────

                    Repeater {
                        model:
                            NotificationService.notificationsModel

                        delegate: Rectangle {
                            id: notifItem

                            required property var modelData

                            readonly property var notification:
                                modelData

                            width: notifCol.width - 16

                            height:
                                notifBody.implicitHeight + 24

                            radius: 10

                            color:
                                itemHover.containsMouse
                                    ? Colors.surfaceContainerHighest
                                    : Colors.surfaceContainerHigh

                            border.width: 1

                            border.color:
                                Colors.outlineVariant

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }

                            RowLayout {
                                id: notifBody

                                anchors {
                                    fill: parent
                                    margins: 12
                                }

                                spacing: 10

                                // ── App icon ─────────────────────────────────

                                Rectangle {
                                    width: 36
                                    height: 36

                                    radius: 8

                                    color:
                                        Colors.primaryContainer

                                    Layout.alignment:
                                        Qt.AlignTop

                                    Image {
                                        id: appIcon

                                        anchors.centerIn: parent

                                        width: 22
                                        height: 22

                                        source:
                                            notifItem.notification &&
                                            notifItem.notification.appIcon
                                                ? "image://icon/" +
                                                  notifItem.notification.appIcon
                                                : ""

                                        visible:
                                            status === Image.Ready

                                        fillMode:
                                            Image.PreserveAspectFit

                                        smooth: true
                                    }

                                    Text {
                                        anchors.centerIn: parent

                                        visible:
                                            appIcon.status !== Image.Ready

                                        text: "󰂚"

                                        font.pixelSize: 16
                                        font.family: Fonts.font

                                        color:
                                            Colors.on_PrimaryContainer
                                    }
                                }

                                // ── Text content ──────────────────────────────

                                ColumnLayout {
                                    Layout.fillWidth: true

                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text:
                                                notifItem.notification
                                                    ? notifItem.notification.appName
                                                    : ""

                                            color:
                                                Colors.on_SurfaceVariant

                                            font.pixelSize: 10
                                            font.family: Fonts.font

                                            Layout.fillWidth: true

                                            elide:
                                                Text.ElideRight

                                            textFormat:
                                                Text.PlainText
                                        }

                                        Text {
                                            text:
                                                notifItem.notification
                                                    ? NotificationService.formatTimestamp(
                                                          notifItem.notification
                                                      )
                                                    : ""

                                            color:
                                                Colors.outline

                                            font.pixelSize: 10
                                            font.family: Fonts.font

                                            textFormat:
                                                Text.PlainText
                                        }
                                    }

                                    Text {
                                        text:
                                            notifItem.notification
                                                ? notifItem.notification.summary
                                                : ""

                                        color:
                                            Colors.on_Surface

                                        font.pixelSize: 12
                                        font.bold: true
                                        font.family: Fonts.font

                                        Layout.fillWidth: true

                                        elide:
                                            Text.ElideRight

                                        textFormat:
                                            Text.PlainText
                                    }

                                    Text {
                                        visible:
                                            notifItem.notification &&
                                            notifItem.notification.body !== ""

                                        text:
                                            notifItem.notification
                                                ? notifItem.notification.body
                                                : ""

                                        color:
                                            Colors.on_SurfaceVariant

                                        font.pixelSize: 11
                                        font.family: Fonts.font

                                        Layout.fillWidth: true

                                        wrapMode:
                                            Text.WordWrap

                                        maximumLineCount: 3

                                        elide:
                                            Text.ElideRight

                                        textFormat:
                                            Text.PlainText
                                    }
                                }

                                // ── Dismiss button ─────────────────────────────

                                Rectangle {
                                    id: dismissButton

                                    width: 20
                                    height: 20

                                    radius: 10

                                    color:
                                        dismissArea.containsMouse
                                            ? Qt.rgba(
                                                  1, 1, 1, 0.12
                                              )
                                            : "transparent"

                                    Layout.alignment:
                                        Qt.AlignTop

                                    z: 2

                                    Text {
                                        anchors.centerIn: parent

                                        text: "󰅖"

                                        font.pixelSize: 11
                                        font.family: Fonts.font

                                        color:
                                            Colors.on_SurfaceVariant
                                    }

                                    MouseArea {
                                        id: dismissArea

                                        anchors.fill: parent

                                        hoverEnabled: true

                                        cursorShape:
                                            Qt.PointingHandCursor

                                        onClicked:
                                            NotificationService.dismiss(
                                                notifItem.notification
                                            )
                                    }
                                }
                            }

                            MouseArea {
                                id: itemHover

                                anchors.fill: parent

                                hoverEnabled: true

                                acceptedButtons:
                                    Qt.LeftButton

                                cursorShape:
                                    Qt.PointingHandCursor

                                onClicked:
                                    NotificationService.dismiss(
                                        notifItem.notification
                                    )
                            }
                        }
                    }
                }
            }
        }
    }
}

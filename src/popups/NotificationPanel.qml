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

    property var screen

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top:   true
        right: true
    }

    implicitWidth:  380
    implicitHeight: root.screen ? root.screen.height : 800

    WlrLayershell.layer: WlrLayer.Overlay

    visible: slidePanel.windowVisible

    PopupSlide {
        id: slidePanel
        anchors.fill: parent
        edge: "top"
        open: Popups.notificationsOpen
        onCloseRequested: Popups.notificationsOpen = false
    }

    // ── Panel card ────────────────────────────────────────────────────────────
    Rectangle {
        anchors {
            top:         parent.top
            right:       parent.right
            topMargin:   Theme.barHeight + 8
            rightMargin: Theme.barMargin
        }
        width:         360
        height:        Math.min(
                           notifCol.implicitHeight + 60,
                           root.implicitHeight - Theme.barHeight - 24
                       )
        radius:        Theme.popupRadius
        color:         Colors.surfaceContainer
        border.color:  Colors.outlineVariant
        border.width:  Theme.popupBorder
        clip:          true

        // ── Header ────────────────────────────────────────────────────────────
        Rectangle {
            id: panelHeader
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 48
            color:  "transparent"

            RowLayout {
                anchors { fill: parent; margins: 16 }

                Text {
                    text:           "Notifications"
                    color:          Colors.on_Surface
                    font.pixelSize: 14
                    font.bold:      true
                    font.family:    Fonts.font
                    Layout.fillWidth: true
                }

                // Clear all button
                Rectangle {
                    visible:      NotificationService.notifications.length > 0
                    width:        90
                    height:       26
                    radius:       13
                    color:        "transparent"
                    border.color: Colors.outline
                    border.width: 1

                    Rectangle {
                        width: 90
                        height: 26
                        radius: 15
                        color: Colors.primary
                        opacity: clearHov.containsMouse ? 0.25 : 0

                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    Text {
                        id:               clearText
                        anchors.centerIn: parent
                        text:             "Clear all"
                        color:            Colors.on_Surface
                        font.pixelSize:   11
                        font.family:      Fonts.font
                    }

                    MouseArea {
                        id:           clearHov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    NotificationService.clearAll()
                    }
                }
            }

            // Divider
            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height:  1
                color:   Colors.outlineVariant
                opacity: 0.5
            }
        }

        // ── Notification list ─────────────────────────────────────────────────
        Flickable {
            anchors {
                top:    panelHeader.bottom
                left:   parent.left
                right:  parent.right
                bottom: parent.bottom
            }
            contentHeight: notifCol.implicitHeight + 16
            clip:          true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth:  3
                    implicitHeight: 40
                    radius:         1.5
                    color:          Qt.rgba(1, 1, 1, 0.25)
                }
                background: Item {}
            }

            Column {
                id:       notifCol
                anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 8 }
                spacing:  4
                padding:  8

                // Empty state
                Item {
                    visible: NotificationService.notifications.length === 0
                    width:   parent.width - 16
                    height:  80

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text:             "󰂚"
                            font.pixelSize:   28
                            font.family:      Fonts.font
                            color:            Colors.outline
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text:             "No notifications"
                            font.pixelSize:   12
                            font.family:      Fonts.font
                            color:            Colors.outline
                        }
                    }
                }

                // Notification items
                Repeater {
                    model: NotificationService.notifications

                    delegate: Rectangle {
                        id:           notifItem
                        required property var modelData

                        width:   notifCol.width - 16
                        height:  notifBody.implicitHeight + 24
                        radius:  10
                        color:   itemHov.containsMouse
                                     ? Colors.surfaceContainerHighest
                                     : Colors.surfaceContainerHigh
                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            id:      notifBody
                            anchors { fill: parent; margins: 12 }
                            spacing: 10

                            // App icon
                            Rectangle {
                                width:  36
                                height: 36
                                radius: 8
                                color:  Colors.primaryContainer
                                Layout.alignment: Qt.AlignTop

                                Image {
                                    anchors.centerIn: parent
                                    width:   22
                                    height:  22
                                    source:  notifItem.modelData && notifItem.modelData.appIcon
                                                 ? "image://icon/" + notifItem.modelData.appIcon
                                                 : ""
                                    visible: source !== ""
                                    fillMode: Image.PreserveAspectFit
                                    smooth:   true
                                }

                                // Fallback icon when no app icon available
                                Text {
                                    anchors.centerIn: parent
                                    visible:          !(notifItem.modelData && notifItem.modelData.appIcon)
                                    text:             "󰂚"
                                    font.pixelSize:   16
                                    font.family:      Fonts.font
                                    color:            Colors.on_PrimaryContainer
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text:           notifItem.modelData.appName || ""
                                        color:          Colors.on_SurfaceVariant
                                        font.pixelSize: 10
                                        font.family:    Fonts.font
                                        Layout.fillWidth: true
                                        elide:          Text.ElideRight
                                    }

                                    Text {
                                        text: NotificationService.formatTimestamp(
                                            NotificationService.getPanelArrivalTime(
                                                notifItem.modelData.id))
                                        color:          Colors.outline
                                        font.pixelSize: 10
                                        font.family:    Fonts.font
                                    }
                                }

                                Text {
                                    text:           notifItem.modelData.summary || ""
                                    color:          Colors.on_Surface
                                    font.pixelSize: 12
                                    font.bold:      true
                                    font.family:    Fonts.font
                                    Layout.fillWidth: true
                                    elide:          Text.ElideRight
                                }

                                Text {
                                    visible:        notifItem.modelData.body !== ""
                                    text:           notifItem.modelData.body || ""
                                    color:          Colors.on_SurfaceVariant
                                    font.pixelSize: 11
                                    font.family:    Fonts.font
                                    Layout.fillWidth: true
                                    wrapMode:       Text.WordWrap
                                    maximumLineCount: 3
                                    elide:          Text.ElideRight
                                }
                            }

                            // Dismiss
                            Rectangle {
                                width:  20
                                height: 20
                                radius: 10
                                color:  dimissItemHov.containsMouse
                                            ? Qt.rgba(1, 1, 1, 0.12)
                                            : "transparent"
                                Layout.alignment: Qt.AlignTop

                                Text {
                                    anchors.centerIn: parent
                                    text:             "󰅖"
                                    font.pixelSize:   11
                                    font.family:      Fonts.font
                                    color:            Colors.on_SurfaceVariant
                                }

                                MouseArea {
                                    id:           dimissItemHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape:  Qt.PointingHandCursor
                                    onClicked:    notifItem.modelData.dismiss()
                                }
                            }
                        }

                        MouseArea {
                            id:           itemHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            // Clicking item dismisses it
                            onClicked:    notifItem.modelData.dismiss()
                        }
                    }
                }
            }
        }
    }
}

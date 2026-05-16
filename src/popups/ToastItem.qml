import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs.src.theme
import qs.src.services

Item {
    id: root

    property int notifId:     0
    property int toastIndex:  0
    property int totalToasts: 1

    // Find the actual notification object
    property var notif: {
        const all = NotificationService.server.trackedNotifications.values
        for (let i = 0; i < all.length; i++) {
            if (all[i].id === root.notifId) return all[i]
        }
        return null
    }

    readonly property int toastHeight: 80
    readonly property int toastSpacing: 8

    // Position: bottom of stack = index 0, stacks upward
    // Each toast sits at: bottom - (index * (height + spacing))
    width:  360
    height: toastHeight

    anchors {
        bottom:       parent.bottom
        right:        parent.right
        bottomMargin: root.toastIndex * (root.toastHeight + root.toastSpacing)
    }

    Behavior on anchors.bottomMargin {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    // ── Slide in from right ───────────────────────────────────────────────────
    property bool _visible: false

    Component.onCompleted: {
        slideInTimer.start()
    }

    Timer {
        id: slideInTimer
        interval: 16  // one frame delay so anchor is set before animation starts
        onTriggered: root._visible = true
    }

    x:       root._visible ? 0 : root.width + 20
    opacity: root._visible ? 1 : 0

    Behavior on x {
        NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: 250 }
    }

    // ── Toast card ────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius:       Theme.popupRadius
        color:        Colors.surfaceContainerHigh
        border.color: Colors.outlineVariant
        border.width: Theme.popupBorder

        // Drop shadow feel via layered rectangles
        Rectangle {
            anchors {
                fill:        parent
                topMargin:   2
                leftMargin:  2
                rightMargin: -2
                bottomMargin: -2
            }
            radius: parent.radius
            color:  Colors.shadow
            opacity: 0.3
            z: -1
        }

        RowLayout {
            anchors {
                fill:    parent
                margins: 12
            }
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
                    source:  root.notif && root.notif.appIcon
                                 ? "image://icon/" + root.notif.appIcon
                                 : ""
                    visible: source !== ""
                    fillMode: Image.PreserveAspectFit
                    smooth:   true
                }

                // Fallback icon when no app icon available
                Text {
                    anchors.centerIn: parent
                    visible:          !(root.notif && root.notif.appIcon)
                    text:             "󰂚"
                    font.pixelSize:   16
                    font.family:      Fonts.font
                    color:            Colors.on_PrimaryContainer
                }
            }

            // Text content
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text:           root.notif ? (root.notif.appName || "") : ""
                        color:          Colors.on_SurfaceVariant
                        font.pixelSize: 10
                        font.family:    Fonts.font
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // Timestamp — binds to _tick so updates every 30s
                    Text {
                        text: root.notif
                            ? NotificationService.formatTimestamp(
                                NotificationService.getPanelArrivalTime(root.notifId))
                            : ""
                        color:          Colors.outline
                        font.pixelSize: 10
                        font.family:    Fonts.font
                    }
                }

                Text {
                    text:           root.notif ? (root.notif.summary || "") : ""
                    color:          Colors.on_Surface
                    font.pixelSize: 12
                    font.bold:      true
                    font.family:    Fonts.font
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    visible:        root.notif ? (root.notif.body !== "") : false
                    text:           root.notif ? root.notif.body : ""
                    color:          Colors.on_SurfaceVariant
                    font.pixelSize: 11
                    font.family:    Fonts.font
                    Layout.fillWidth: true
                    elide:          Text.ElideRight
                    maximumLineCount: 2
                    wrapMode:       Text.WordWrap
                }
            }

            // Dismiss button
            Rectangle {
                width:  20
                height: 20
                radius: 10
                color:  dismissHov.containsMouse
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
                    id:           dismissHov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        if (root.notif) root.notif.dismiss()
                        NotificationService.removeToast(root.notifId)
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import qs.src.theme
import qs.src.services

Item {
    id: root

    required property var notification
    readonly property int toastHeight: 80

    property int remainingMs: NotificationService.toastDuration
    property int countdownStartedAt: 0

    readonly property bool stackHovered: NotificationService.toastStackHovered

    width: 360
    height: toastHeight

    function startCountdown() {
        if (root.stackHovered) return
        if (!root.notification) return
        if (root.remainingMs <= 0) {
            NotificationService.expireToast(
                root.notification
            )
            return
        }

        root.countdownStartedAt = Date.now()
        lifetimeTimer.interval = root.remainingMs
        lifetimeTimer.start()
    }

    function pauseCountdown() {
        if (!lifetimeTimer.running) return

        const elapsed = Date.now() - root.countdownStartedAt
        root.remainingMs = Math.max(0, root.remainingMs - elapsed)
        lifetimeTimer.stop()
    }

    Timer {
        id: lifetimeTimer

        repeat: false
        onTriggered: {
            root.remainingMs = 0
            if (root.notification && root.notification.tracked) { NotificationService.expireToast(root.notification) }
        }
    }

    Component.onCompleted: root.startCountdown()

    onStackHoveredChanged: {
        if (root.stackHovered)
            root.pauseCountdown()
        else
            root.startCountdown()
    }

    Rectangle {
        anchors.fill: parent

        radius: Theme.popupRadius
        color: Colors.surfaceContainerHigh
        border.color: Colors.outlineVariant
        border.width: Theme.popupBorder

        Rectangle {
            anchors {
                fill: parent
                topMargin: 2
                leftMargin: 2
                rightMargin: -2
                bottomMargin: -2
            }

            radius: parent.radius
            color: Colors.shadow
            opacity: 0.3
            z: -1
        }

        RowLayout {
            anchors {
                fill: parent
                margins: 12
            }

            spacing: 10

            Rectangle {
                width: 36
                height: 36
                radius: 8
                color: Colors.primaryContainer
                Layout.alignment: Qt.AlignTop

                Image {
                    id: appIcon

                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    source: root.notification && root.notification.appIcon ? "image://icon/" + root.notification.appIcon : ""

                    visible: status === Image.Ready
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: appIcon.status !== Image.Ready
                    text: "󰂚"
                    font.pixelSize: 16
                    font.family: Fonts.font
                    color: Colors.on_PrimaryContainer
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.notification ? root.notification.appName : ""
                        color: Colors.on_SurfaceVariant
                        font.pixelSize: 10
                        font.family: Fonts.font
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    Text {
                        text: root.notification ? NotificationService.formatTimestamp( root.notification) : ""
                        color: Colors.outline
                        font.pixelSize: 10
                        font.family: Fonts.font
                        textFormat: Text.PlainText
                    }
                }

                Text {
                    text: root.notification ? root.notification.summary : ""
                    color: Colors.on_Surface
                    font.pixelSize: 12
                    font.bold: true
                    font.family: Fonts.font
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                Text {
                    visible: !!root.notification && root.notification.body !== ""
                    text: root.notification ? root.notification.body : ""
                    color: Colors.on_SurfaceVariant
                    font.pixelSize: 11
                    font.family: Fonts.font
                    Layout.fillWidth: true
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                }
            }

            Rectangle {
                id: dismissButton

                width: 20
                height: 20
                radius: 10
                color: dismissArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                Layout.alignment: Qt.AlignTop
                z: 2

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.pixelSize: 11
                    font.family: Fonts.font
                    color: Colors.on_SurfaceVariant
                }

                MouseArea {
                    id: dismissArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: NotificationService.dismiss(root.notification)
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: NotificationService.dismiss(root.notification)
    }
}

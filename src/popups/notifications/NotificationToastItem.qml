import QtQuick
import qs.src.theme
import qs.src.services
import qs.src.popups.notifications

Item {
    id: root

    required property var notification

    readonly property bool stackHovered:
        NotificationService.toastStackHovered

    implicitHeight: notificationCard.implicitHeight
    height: implicitHeight

    function startCountdown() {
        if (root.stackHovered)
            return

        if (!root.notification)
            return

        if (root.remainingMs <= 0) {
            NotificationService.expireToast(root.notification)
            return
        }

        root.countdownStartedAt = Date.now()

        lifetimeTimer.interval = root.remainingMs
        lifetimeTimer.start()
    }

    function pauseCountdown() {
        if (!lifetimeTimer.running)
            return

        const elapsed = Date.now() - root.countdownStartedAt

        root.remainingMs = Math.max(
            0,
            root.remainingMs - elapsed
        )

        lifetimeTimer.stop()
    }

    property int remainingMs: NotificationService.toastDuration
    property int countdownStartedAt: 0

    Timer {
        id: lifetimeTimer

        repeat: false

        onTriggered: {
            root.remainingMs = 0

            if (root.notification && root.notification.tracked)
                NotificationService.expireToast(root.notification)
        }
    }

    Component.onCompleted:
        root.startCountdown()

    onStackHoveredChanged: {
        if (root.stackHovered)
            root.pauseCountdown()
        else
            root.startCountdown()
    }

    NotificationCard {
        id: notificationCard

        width: parent.width
        height: implicitHeight

        notification: root.notification
        bodyMaximumLineCount: 2
    }
}

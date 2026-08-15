pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    // ── Configuration ────────────────────────────────────────────────────────
    readonly property int maxVisibleToasts: 5
    readonly property int toastDuration: 4000

    // ── Notification server ──────────────────────────────────────────────────
    property NotificationServer server: NotificationServer {
        bodySupported: true
        bodyMarkupSupported: false
        bodyImagesSupported: false
        imageSupported: false

        actionsSupported: false
        actionIconsSupported: false
        inlineReplySupported: false

        keepOnReload: true

        onNotification: notification => root._handleNotification(notification)
    }

    // ── Public state ─────────────────────────────────────────────────────────

    // The notification panel consumes the server's real ObjectModel directly.
    readonly property var notificationsModel:
        server.trackedNotifications

    readonly property int notificationCount:
        server.trackedNotifications.values.length

    // Transient toast state. This is intentionally separate from notification
    // history because a toast is a visual presentation, not a notification.
    ListModel {
        id: toastModel
    }

    readonly property var activeToastsModel: toastModel

    readonly property int activeToastCount:
        toastModel.count

    // ── Toast queue ──────────────────────────────────────────────────────────
    // Contains actual Quickshell Notification objects.
    property var _toastQueue: []

    // ── Notification presentation state ──────────────────────────────────────

    // Manual notification suppression / gaming mode.
    property bool notificationsSuppressed: false

    // Toasts stay on one deliberate screen. We do not create one toast
    // surface per monitor.
    property ShellScreen toastScreen:
        Quickshell.screens.length > 0
            ? Quickshell.screens[0]
            : null

    // The panel can open on the monitor whose notification button was clicked.
    property ShellScreen panelScreen:
        Quickshell.screens.length > 0
            ? Quickshell.screens[0]
            : null

    // ── Arrival timestamps ───────────────────────────────────────────────────
    //
    // We need this because Notification does not expose "received at" time.
    // We keep the actual Notification object as the identity.
    property var _arrivalTimes: []

    function _setArrivalTime(notification, timestamp) {
        const existing = _findArrivalIndex(notification)

        if (existing >= 0) {
            _arrivalTimes[existing].timestamp = timestamp
            return
        }

        _arrivalTimes.push({
            notification: notification,
            timestamp: timestamp
        })
    }

    function _findArrivalIndex(notification) {
        for (let i = 0; i < _arrivalTimes.length; ++i) {
            if (_arrivalTimes[i].notification === notification)
                return i
        }

        return -1
    }

    function getArrivalTime(notification) {
        if (!notification)
            return 0

        const index = _findArrivalIndex(notification)

        if (index >= 0)
            return _arrivalTimes[index].timestamp

        return 0
    }

    function _removeArrivalTime(notification) {
        const index = _findArrivalIndex(notification)

        if (index >= 0)
            _arrivalTimes.splice(index, 1)
    }

    // ── Notification lifecycle ───────────────────────────────────────────────

    function _handleNotification(notification) {
        if (!notification)
            return

        // Retain it in NotificationServer.trackedNotifications so the
        // notification panel can consume the server's real ObjectModel.
        notification.tracked = true

        const isHistorical = !!notification.lastGeneration
        const now = Date.now()

        // Historical notifications are retained for the panel but do not get
        // fresh toast notifications after a Quickshell reload.
        if (!isHistorical)
            _setArrivalTime(notification, now)

        // Every Notification object gets its own closure. This is important
        // because applications can reuse notification IDs.
        const capturedNotification = notification

        notification.closed.connect(() => {
            root._handleNotificationClosed(capturedNotification)
        })

        // No toast for notifications restored from a previous generation.
        if (isHistorical)
            return

        // DND / gaming mode: notification remains tracked but creates no
        // visual toast and does not enter the toast queue.
        if (root.notificationsSuppressed)
            return

        root._enqueueToast(notification)
    }

    function _handleNotificationClosed(notification) {
        if (!notification)
            return

        _removeToast(notification)
        _removeFromQueue(notification)
        _removeArrivalTime(notification)
    }

    // ── Toast queue ──────────────────────────────────────────────────────────

    function _toastIndex(notification) {
        for (let i = 0; i < toastModel.count; ++i) {
            if (toastModel.get(i).toastNotification === notification)
                return i
        }

        return -1
    }

    function _queueIndex(notification) {
        return root._toastQueue.indexOf(notification)
    }

    function _enqueueToast(notification) {
        if (!notification)
            return

        // Don't show the same Notification object twice.
        if (_toastIndex(notification) >= 0)
            return

        if (_queueIndex(notification) >= 0)
            return

        if (toastModel.count < root.maxVisibleToasts) {
            _showToast(notification)
        } else {
            root._toastQueue.push(notification)
        }

        _restartToastTimer()
    }

    function _showToast(notification) {
        if (!notification)
            return

        toastModel.insert(0, {
            toastNotification: notification,
            expiresAt: Date.now() + root.toastDuration
        })
    }

    function _promoteQueuedToasts() {
        while (!root.notificationsSuppressed &&
               toastModel.count < root.maxVisibleToasts &&
               root._toastQueue.length > 0) {

            const notification = root._toastQueue.shift()

            if (!notification)
                continue

            // The notification might have been closed while waiting.
            if (!notification.tracked)
                continue

            _showToast(notification)
        }

        _restartToastTimer()
    }

    // ── Toast removal ────────────────────────────────────────────────────────

    function _removeToast(notification) {
        const index = _toastIndex(notification)

        if (index < 0)
            return false

        toastModel.remove(index)

        _promoteQueuedToasts()

        return true
    }

    function _removeFromQueue(notification) {
        const index = _queueIndex(notification)

        if (index >= 0)
            root._toastQueue.splice(index, 1)
    }

    // ── User dismissal ───────────────────────────────────────────────────────

    function dismiss(notification) {
        if (!notification)
            return

        _removeToast(notification)
        _removeFromQueue(notification)
        _removeArrivalTime(notification)

        // This removes it from trackedNotifications as well.
        notification.dismiss()
    }

    // ── Clear all ────────────────────────────────────────────────────────────

    function clearAll() {
        const notifications =
            server.trackedNotifications.values.slice()

        // First remove visible toasts individually so ListView receives
        // proper remove transitions.
        for (let i = toastModel.count - 1; i >= 0; --i)
            toastModel.remove(i)

        root._toastQueue = []

        _stopToastTimer()

        // Then dismiss the actual notifications.
        for (const notification of notifications) {
            if (notification)
                notification.dismiss()
        }

        _arrivalTimes = []
    }

    // ── DND / Gaming mode ────────────────────────────────────────────────────

    function setSuppressed(enabled) {
        enabled = !!enabled

        if (root.notificationsSuppressed === enabled)
            return

        root.notificationsSuppressed = enabled

        if (enabled) {
            // Existing visual notifications disappear.
            // The underlying notifications stay tracked and remain visible
            // inside the notification panel.
            for (let i = toastModel.count - 1; i >= 0; --i)
                toastModel.remove(i)

            root._toastQueue = []

            _stopToastTimer()
        }
    }

    function toggleSuppressed() {
        setSuppressed(!root.notificationsSuppressed)
    }

    // ── Toast expiry ─────────────────────────────────────────────────────────
    //
    // One dynamically scheduled timer. No constant polling loop.

    Timer {
        id: toastTimer

        repeat: false

        onTriggered: root._expireToasts()
    }

    function _restartToastTimer() {
        if (toastModel.count === 0) {
            _stopToastTimer()
            return
        }

        let nextExpiration = Number.MAX_SAFE_INTEGER

        for (let i = 0; i < toastModel.count; ++i) {
            const expiresAt = toastModel.get(i).expiresAt

            if (expiresAt > 0)
                nextExpiration = Math.min(nextExpiration, expiresAt)
        }

        if (nextExpiration === Number.MAX_SAFE_INTEGER) {
            _stopToastTimer()
            return
        }

        toastTimer.interval =
            Math.max(1, nextExpiration - Date.now())

        toastTimer.start()
    }

    function _stopToastTimer() {
        toastTimer.stop()
    }

    function _expireToasts() {
        if (toastModel.count === 0)
            return

        const now = Date.now()

        // Remove from highest index down so model indices remain valid.
        for (let i = toastModel.count - 1; i >= 0; --i) {
            if (toastModel.get(i).expiresAt <= now)
                toastModel.remove(i)
        }

        _promoteQueuedToasts()
        _restartToastTimer()
    }

    // ── Relative timestamps ──────────────────────────────────────────────────

    property int _timeTick: 0

    Timer {
        interval: 30000
        repeat: true
        running: true

        onTriggered:
            root._timeTick++
    }

    function formatTimestamp(notification) {
        // Create a dependency on _timeTick so timestamp text refreshes.
        const tick = root._timeTick

        if (!notification)
            return ""

        const timestamp = getArrivalTime(notification)

        // Historical notifications from a previous generation don't have a
        // trustworthy local arrival timestamp.
        if (timestamp === 0)
            return "Earlier"

        const diff = Math.max(0, Date.now() - timestamp)
        const minutes = Math.floor(diff / 60000)

        if (minutes < 1)
            return "just now"

        if (minutes < 60)
            return minutes + " min" + (minutes > 1 ? "s" : "") + " ago"

        const date = new Date(timestamp)

        let hours = date.getHours()
        const minutesString =
            date.getMinutes().toString().padStart(2, "0")

        const ampm = hours >= 12 ? "PM" : "AM"

        hours = hours % 12 || 12

        return hours + ":" + minutesString + " " + ampm
    }
}

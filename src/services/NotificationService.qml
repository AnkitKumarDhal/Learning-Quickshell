pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property int maxVisibleToasts: 5
    readonly property int toastDuration: 4000
    readonly property int toastEntryInterval: 350

    property NotificationServer server: NotificationServer {
        bodySupported: true
        bodyMarkupSupported: false
        bodyImagesSupported: false
        imageSupported: false

        actionsSupported: true
        actionIconsSupported: false
        inlineReplySupported: false

        keepOnReload: true

        onNotification: notification => root._handleNotification(notification)
    }

    readonly property var notificationsModel: server.trackedNotifications
    readonly property int notificationCount: server.trackedNotifications.values.length

    ListModel { id: toastModel }

    readonly property var activeToastsModel: toastModel
    readonly property int activeToastCount: toastModel.count

    property var _toastQueue: []
    property bool _toastPresentationBusy: false

    property int _hoveredToastCount: 0
    readonly property bool toastStackHovered: _hoveredToastCount > 0

    property bool notificationsSuppressed: false

    property ShellScreen toastScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    property ShellScreen panelScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    property var _arrivalTimes: []

    function setToastHovered(hovered) {
        if (hovered) {
            root._hoveredToastCount++
        } else {
            root._hoveredToastCount = Math.max(0, root._hoveredToastCount - 1)
        }
    }

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
            if (_arrivalTimes[i].notification === notification) return i
        }

        return -1
    }

    function getArrivalTime(notification) {
        if (!notification) return 0
        const index = _findArrivalIndex(notification)
        if (index >= 0) return _arrivalTimes[index].timestamp

        return 0
    }

    function _removeArrivalTime(notification) {
        const index = _findArrivalIndex(notification)
        if (index >= 0) _arrivalTimes.splice(index, 1)
    }

    function _handleNotification(notification) {
        if (!notification) return

        notification.tracked = true
        const historical = !!notification.lastGeneration

        if (!historical) _setArrivalTime(notification, Date.now())

        const capturedNotification = notification

        notification.closed.connect(() => {
            root._handleNotificationClosed(capturedNotification)
        })

        if (historical) return
        if (root.notificationsSuppressed) return

        root._enqueueToast(notification)
    }

    function _handleNotificationClosed(notification) {
        if (!notification) return

        _removeToast(notification)
        _removeFromQueue(notification)
        _removeArrivalTime(notification)
    }

    function _toastIndex(notification) {
        for (let i = 0; i < toastModel.count; ++i) {
            if (toastModel.get(i).toastNotification === notification) return i
        }

        return -1
    }

    function _queueIndex(notification) {
        return root._toastQueue.indexOf(notification)
    }

    function _enqueueToast(notification) {
        if (!notification) return
        if (_toastIndex(notification) >= 0) return
        if (_queueIndex(notification) >= 0) return

        root._toastQueue.push(notification)
        _pumpToastQueue()
    }

    function _pumpToastQueue() {
        if (root.notificationsSuppressed) return
        if (root._toastPresentationBusy) return
        if (toastModel.count >= root.maxVisibleToasts) return

        if (root._toastQueue.length === 0) {
            root._toastPresentationBusy = false
            return
        }

        const notification = root._toastQueue.shift()

        if (!notification) return

        if (!notification.tracked) {
            _pumpToastQueue()
            return
        }

        _showToast(notification)
        root._toastPresentationBusy = true
        toastPresentationTimer.restart()
    }

    function _showToast(notification) {
        if (!notification) return
        toastModel.insert(0, {
            toastNotification: notification
        })
    }

    function _promoteQueuedToasts() {
        _pumpToastQueue()
    }

    function expireToast(notification) {
        _removeToast(notification)
    }

    function _removeToast(notification) {
        const index = _toastIndex(notification)
        if (index < 0) return false

        toastModel.remove(index)
        if (!root._toastPresentationBusy) _pumpToastQueue()

        return true
    }

    function _removeFromQueue(notification) {
        const index = _queueIndex(notification)
        if (index >= 0) root._toastQueue.splice(index, 1)
    }

    function dismiss(notification) {
        if (!notification) return

        _removeToast(notification)
        _removeFromQueue(notification)
        _removeArrivalTime(notification)

        notification.dismiss()
    }

    function clearAll() {
        const notifications = server.trackedNotifications.values.slice()

        for (let i = toastModel.count - 1; i >= 0; --i)
            toastModel.remove(i)

        root._toastQueue = []
        root._hoveredToastCount = 0
        root._toastPresentationBusy = false

        toastPresentationTimer.stop()

        for (const notification of notifications) {
            if (notification) notification.dismiss()
        }

        _arrivalTimes = []
    }

    function setSuppressed(enabled) {
        enabled = !!enabled
        if (root.notificationsSuppressed === enabled) return

        root.notificationsSuppressed = enabled

        if (enabled) {
            for (let i = toastModel.count - 1; i >= 0; --i)
                toastModel.remove(i)

            root._toastQueue = []
            root._hoveredToastCount = 0
            root._toastPresentationBusy = false

            toastPresentationTimer.stop()
        }
    }

    function toggleSuppressed() {
        setSuppressed(!root.notificationsSuppressed)
    }

    Timer {
        id: toastPresentationTimer
        interval: root.toastEntryInterval
        repeat: false
        onTriggered: {
            root._toastPresentationBusy = false
            root._pumpToastQueue()
        }
    }

    property int _timeTick: 0

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root._timeTick++
    }

    function formatTimestamp(notification) {
        const unused = root._timeTick
        if (!notification) return ""

        const timestamp = getArrivalTime(notification)
        if (timestamp === 0) return "Earlier"

        const diff = Math.max(0, Date.now() - timestamp)
        const minutes = Math.floor(diff / 60000)

        if (minutes < 1) return "just now"
        if (minutes < 60) return minutes + " min" + (minutes > 1 ? "s" : "") + " ago"

        const date = new Date(timestamp)
        let hours = date.getHours()
        const minuteString = date.getMinutes() .toString() .padStart(2, "0")
        const ampm = hours >= 12 ? "PM" : "AM"
        hours = hours % 12 || 12
        return hours + ":" + minuteString + " " + ampm
    }
}

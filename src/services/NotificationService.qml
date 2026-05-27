pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool panelVisible: false
    property var  activeToasts: []
    property var  _toastData:   []

    // ── Startup grace period ──────────────────────────────────────────────────
    // Suppress toast popups for the first 500ms to avoid flooding on login.
    // Notifications still land in history; they just don't visually pop up.
    property bool _isStartup: true
    Timer {
        interval: 500
        running:  true
        onTriggered: root._isStartup = false
    }

    property NotificationServer server: NotificationServer {
        bodySupported:    true
        actionsSupported: true

        onNotification: (notif) => {
            notif.tracked = true

            // Always record arrival time for history panel
            let tData = root._toastData.slice()
            tData.push({
                id:        notif.id,
                expires:   Date.now() + 4000,
                arrivedAt: Date.now()
            })
            root._toastData = tData

            // Only show the visual toast once startup flood is over
            if (!root._isStartup) {
                updateActiveToasts()
            }
        }
    }

    function getArrivalTime(id) {
        const entry = root._toastData.find(t => t.id === id)
        return entry ? entry.arrivedAt : Date.now()
    }

    property var _arrivalMap: ({})

    onActiveToastsChanged: {
        root._toastData.forEach(t => {
            if (!root._arrivalMap[t.id])
                root._arrivalMap[t.id] = t.arrivedAt
        })
    }

    function getPanelArrivalTime(id) {
        return root._arrivalMap[id] || Date.now()
    }

    function updateActiveToasts() {
        root.activeToasts = root._toastData.map(t => t.id)
    }

    function removeToast(id) {
        let tData = root._toastData.slice()
        let idx   = tData.findIndex(t => t.id === id)
        if (idx < 0) return
        tData.splice(idx, 1)
        root._toastData = tData
        updateActiveToasts()
    }

    function clearAll() {
        const allNotifs = [...server.trackedNotifications.values]
        allNotifs.forEach(n => n.dismiss())
        root._arrivalMap = {}
    }

    // ── Reversed notification list for panel display ──────────────────────────
    // Stored as a stable property (not recreated per binding eval) to avoid
    // Repeater delegate churn and the resulting animation jank.
    readonly property var reversedNotifications: {
        const all = server.trackedNotifications.values
        const copy = all.slice()
        copy.reverse()
        return copy
    }

    readonly property var notifications: server.trackedNotifications.values

    // Expiry timer — only runs while toasts are alive
    Timer {
        interval:  500
        running:   root._toastData.length > 0
        repeat:    true
        onTriggered: {
            const now   = Date.now()
            let tData   = root._toastData.slice()
            let changed = false
            for (let i = tData.length - 1; i >= 0; i--) {
                if (now >= tData[i].expires) {
                    tData.splice(i, 1)
                    changed = true
                }
            }
            if (changed) {
                root._toastData = tData
                updateActiveToasts()
            }
        }
    }

    // Timestamp refresh timer — drives relative time updates in UI
    property int _tick: 0
    Timer {
        interval: 30000
        running:  true
        repeat:   true
        onTriggered: root._tick++
    }

    function formatTimestamp(arrivedAt) {
        const _ = root._tick
        const diff = Date.now() - arrivedAt
        const mins = Math.floor(diff / 60000)

        if (mins < 1)   return "just now"
        if (mins < 60)  return mins + " min" + (mins > 1 ? "s" : "") + " ago"

        const d    = new Date(arrivedAt)
        let h      = d.getHours()
        const m    = d.getMinutes().toString().padStart(2, "0")
        const ampm = h >= 12 ? "PM" : "AM"
        h = h % 12 || 12
        return h + ":" + m + " " + ampm
    }
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool panelVisible: false
    property var  activeToasts: []
    property var  _toastData:   []

    property NotificationServer server: NotificationServer {
        bodySupported:    true
        actionsSupported: true

        onNotification: (notif) => {
            notif.tracked = true
            let tData = root._toastData.slice()
            tData.push({
                id:        notif.id,
                expires:   Date.now() + 4000,
                arrivedAt: Date.now()        // ← timestamp stored here
            })
            root._toastData = tData
            updateActiveToasts()
        }
    }

    // Returns the arrivedAt timestamp for a given notification id
    function getArrivalTime(id) {
        const entry = root._toastData.find(t => t.id === id)
        return entry ? entry.arrivedAt : Date.now()
    }

    // Also expose arrival time for panel — panel uses full tracked list
    // so we keep a separate persistent map that survives toast expiry
    property var _arrivalMap: ({})

    onActiveToastsChanged: {
        // Sync arrivals into persistent map
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
        server.trackedNotifications.values.forEach(n => n.dismiss())
        root._arrivalMap = {}
    }

    readonly property var notifications: server.trackedNotifications.values

    // Expiry timer
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
    // Fires every 30s, fast enough for "just now" → "1 min ago" transitions
    property int _tick: 0
    Timer {
        interval: 30000
        running:  true
        repeat:   true
        onTriggered: root._tick++
    }

    // Formats a timestamp into relative or absolute string
    // Any component that needs a timestamp binds to both the timestamp
    // AND root._tick so it re-evaluates every 30s
    function formatTimestamp(arrivedAt) {
        const _ = root._tick  // creates binding dependency
        const diff = Date.now() - arrivedAt
        const mins = Math.floor(diff / 60000)
        const hrs  = Math.floor(diff / 3600000)

        if (mins < 1)   return "just now"
        if (mins < 60)  return mins + " min" + (mins > 1 ? "s" : "") + " ago"

        // Over an hour — show absolute time
        const d = new Date(arrivedAt)
        let h   = d.getHours()
        const m = d.getMinutes().toString().padStart(2, "0")
        const ampm = h >= 12 ? "PM" : "AM"
        h = h % 12 || 12
        return h + ":" + m + " " + ampm
    }
}

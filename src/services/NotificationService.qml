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
            tData.push({ id: notif.id, expires: Date.now() + 4000 })
            root._toastData = tData
            updateActiveToasts()
        }
    }

    function updateActiveToasts() {
        root.activeToasts = root._toastData.map(t => t.id)
    }

    function removeToast(id) {
        let tData   = root._toastData.slice()
        let idx     = tData.findIndex(t => t.id === id)
        if (idx < 0) return
        tData.splice(idx, 1)
        root._toastData = tData
        updateActiveToasts()
    }

    function clearAll() {
        server.trackedNotifications.values
              .forEach(n => n.dismiss())
    }

    readonly property var notifications: server.trackedNotifications.values

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
}

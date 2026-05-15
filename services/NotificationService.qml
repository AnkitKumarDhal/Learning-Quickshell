pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool panelVisible: false

    property var activeToasts: []
    property var _toastData: []

    property NotificationServer server: NotificationServer {
        bodySupported: true
        actionsSupported: true

        onNotification: (notif) => {
            notif.tracked = true

            let tData = root._toastData.slice();
            tData.push({ id: notif.id, expires: Date.now() + 4000});
            root._toastData = tData;

            updateActiveToasts();
        }
    }

    function updateActiveToasts() {
        let ids = [];
        for (let i = 0; i < root._toastData.length; i++) {
            ids.push(root._toastData[i].id);
        }
        root.activeToasts = ids;
    }

    Timer {
        interval: 500
        running: root._toastData.length > 0
        repeat: true
        onTriggered: {
            let now = Date.now();
            let tData = root._toastData.slice();
            let changed = false;

            for (let i = tData.length - 1; i >= 0; i--) {
                if (now >= tData[i].expires) {
                    tData.splice(i, 1);
                    changed = true;
                }
            }

            if (changed){
                root._toastData = tData;
                root.updateActiveToasts();
            }
        }
    }

    function removeToast(id) {
        let tData = root._toastData.slice();
        let changed = false;
        for (let i = tData.length - 1; i >= 0; i--) {
            if (tData[i].id === id) {
                tData.splice(i, 1);
                changed = true;
                break;
            }
        }

        if (changed) {
            root._toastData = tData;
            root.updateActiveToasts();
        }
    }

    property var notifications: server.trackedNotifications.values
    function clearAll() {
        let notifs = server.trackedNotifications.values;
        for (let i = notifs.length - 1; i >= 0; i--) {
            notifs[i].dismiss();
        }
    }
}

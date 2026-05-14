pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool panelVisible: false

    property NotificationServer server: NotificationServer {
        bodySupported: true
        actionsSupported: true

        onNotification: (notif) => {
            notif.tracked = true
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

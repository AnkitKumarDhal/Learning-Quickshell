// pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

QtObject {
    id: root

    property bool panelVisible: false
    property NotificationServer server

    server: NotificationServer {
        // registerServer: true
        bodySupported: true
        actionsSupported: true
    }

    property var notifications: server.trackedNotifications.values
}

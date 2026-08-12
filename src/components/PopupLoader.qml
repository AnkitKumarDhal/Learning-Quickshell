import QtQuick
import Quickshell
import qs.src.theme

Item {
    id: root

    required property bool open
    required property Component popup

    readonly property int unloadDelay: Theme.slideInDuration + 50

    property bool _keepLoaded: false

    onOpenChanged: {
        if (root.open) {
            unloadTimer.stop()
            root._keepLoaded = true
        } else {
            unloadTimer.restart()
        }
    }

    Timer {
        id: unloadTimer

        interval: root.unloadDelay
        repeat: false

        onTriggered: {
            if (!root.open) {
                root._keepLoaded = false
            }
        }
    }

    LazyLoader {
        id: loader

        activeAsync: root._keepLoaded
        component: root.popup
    }
}

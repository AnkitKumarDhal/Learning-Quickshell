pragma Singleton
import QtQuick
import Quickshell

Singleton {
    property string type: ""
    property real value: 0
    property bool visible: false

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: visible = false
    }

    function show(t, v) {
        type = t
        value = v
        visible = true
        hideTimer.restart()
    }
}

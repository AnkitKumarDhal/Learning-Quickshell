pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    property alias date: clock.date
    readonly property SystemClock clock: clock

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    function format(fmt) {
        return Qt.formatDateTime(clocke.date, fmt)
    }
}

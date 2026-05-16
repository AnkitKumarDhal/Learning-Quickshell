import QtQuick
import Quickshell
import qs.src.components
import qs.src.theme
import qs.src.state

PillBase {
    id: root

    hoverExpand: true

    property bool showDate: false

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    Text {
        text: root.showDate
            ? Qt.formatDateTime(sysClock.date, "ddd, MMM d")
            : Qt.formatDateTime(sysClock.date, "hh:mm A")
        color: Colors.primary
        font.pointSize: 11
        font.bold: true
        font.family: Fonts.font
        verticalAlignment: Text.AlignVCenter
    }

    onClicked:      root.showDate = !root.showDate
    onRightClicked: Popups.calendarOpen = !Popups.calendarOpen
}

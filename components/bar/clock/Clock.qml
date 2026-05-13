import QtQuick
import Quickshell
import "../../../settings"

Rectangle {
    id: clockPill

    implicitWidth: timeText.implicitWidth + 32
    implicitHeight: 30
    radius: 15
    color: Colors.background

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    Text {
        id: timeText
        anchors.centerIn: parent
        text: Qt.formatDateTime(sysClock.date, "hh:mm A")
        color: Colors.primary
        font.pointSize: 11
        font.bold: true
        font.family: Fonts.font
    }
}

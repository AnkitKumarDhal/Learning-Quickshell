import QtQuick
import Quickshell

Item {
    id: root

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    property var parentWindow

    property string currentTime: "00:00"
    property string currentDate: "Loading..."

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let now = new Date();
            root.currentTime = Qt.formatTime(now, "hh:mm");
            root.currentDate = Qt.formatDate(now, "dddd, d MMMM");
        }
    }

    Pill {
        id: pill
        anchors.fill: parent
        onClicked: dropdown.isOpen = !dropdown.isOpen

        Text {
            text: root.currentTime
            color: Colors.foreground
            font.pixelSize: 14
            font.bold: true
        }
    }

    DropdownPanel {
        id: dropdown
        parentWindow: root.parentWindow
        targetPill: pill

        popupEdge: Edges.Bottom
        popupGap: 7

        Text {
            text: "Date & Time"
            color: Colors.foreground
            opacity: 0.5
            font.pixelSize: 11
            font.capitalization: Font.AllUppercase
        }

        Text {
            text: root.currentDate
            color: Colors.foreground
            font.pixelSize: 14
        }
    }
}

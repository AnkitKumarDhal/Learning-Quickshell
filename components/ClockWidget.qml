import ".."
import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    property string timeString: ""

    // "Glass" Pill Styling
    color: Qt.alpha(Theme.bg, 0.5)
    radius: 10
    border.color: Qt.alpha(Theme.fg, 0.2)
    border.width: 1
    // Padding/Sizing
    implicitWidth: timeLabel.implicitWidth + 24
    implicitHeight: 24

    Text {
        id: timeLabel

        anchors.centerIn: parent
        text: root.timeString
        color: Theme.color8 // Use the foreground color for the clock

        font {
            family: "JetBrainsMono Nerd Font"
            pixelSize: 14
            bold: true
        }

    }

    // Timer to update the clock every second
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var date = new Date();
            // Format: HH:MM:SS - You can change this to include the date too!
            root.timeString = date.toLocaleTimeString(Qt.locale(), "hh:mm ap");
        }
        // Run once immediately so it doesn't start empty
        Component.onCompleted: {
            var date = new Date();
            root.timeString = date.toLocaleTimeString(Qt.locale(), "hh:mm ap");
        }
    }

}

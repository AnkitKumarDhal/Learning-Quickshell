import QtQuick
import QtQuick.Controls
import Quickshell
import qs.src.components
import qs.src.theme
import qs.src.state

PillBase {
    id: root

    hoverExpand: true

    property bool showDate: false
    property bool use24Hour: false
    property bool showSeconds: false
    property string dateFormat: "ddd, MMM d"

    SystemClock {
        id: sysClock
        precision: root.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    SystemClock {
        id: tooltipClock
        precision: SystemClock.Seconds
    }

    Text {
        text: root.showDate
            ? Qt.formatDateTime(sysClock.date, root.dateFormat)
            : Qt.formatDateTime(sysClock.date, root.use24Hour
                ? (root.showSeconds ? "HH:mm:ss" : "HH:mm")
                : (root.showSeconds ? "hh:mm:ss AP" : "hh:mm AP"))
        color: Colors.primary
        font.pointSize: 11
        font.bold: true
        font.family: Fonts.font
        verticalAlignment: Text.AlignVCenter
    }

    Timer {
        id: tooltipTimer

        interval: 500
        repeat: false

        onTriggered: {
            if (root.hoverArea.containsMouse) {
                clockTooltip.visible = true
            }
        }
    }

    PopupWindow {
        id: clockTooltip

        visible: false

        anchor {
            window: root.hoverArea.QsWindow.window
            adjustment: PopupAdjustment.None
            gravity: Edges.Bottom | Edges.Right

            onAnchoring: {
                const pos = root.hoverArea.QsWindow.contentItem.mapFromItem(
                    root.hoverArea,
                    root.hoverArea.width / 2 - clockTooltip.width / 2,
                    root.hoverArea.height + 8,
                )

                anchor.rect.x = pos.x
                anchor.rect.y = pos.y
            }
        }

        implicitWidth: Math.max(170, clockTooltipText.implicitWidth + 20)
        implicitHeight: clockTooltipText.implicitHeight + 16

        color: "transparent"

        Rectangle {
            anchors.fill: parent

            radius: 8
            color: Colors.surfaceContainerHigh

            border.width: 1
            border.color: Colors.outlineVariant

            Text {
                id: clockTooltipText

                anchors.fill: parent
                anchors.margins: 10

                text: Qt.formatDateTime(tooltipClock.date, "dddd, MMMM d, yyyy") + "\n"
                    + Qt.formatDateTime(tooltipClock.date, root.use24Hour ? "HH:mm:ss" : "hh:mm:ss AP")

                color: Colors.on_Surface

                font.family: Fonts.font
                font.pixelSize: 11

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Connections {
        target: root.hoverArea

        function onEntered() {
            tooltipTimer.restart()
        }

        function onExited() {
            tooltipTimer.stop()
            clockTooltip.visible = false
        }

        function onCanceled() {
            tooltipTimer.stop()
            clockTooltip.visible = false
        }
    }

    onClicked:      root.showDate = !root.showDate
    onRightClicked: Popups.calendarOpen = !Popups.calendarOpen
}

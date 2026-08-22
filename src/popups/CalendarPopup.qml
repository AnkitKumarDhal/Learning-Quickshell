import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.src.components
import qs.src.theme
import qs.src.state

PanelWindow {
    id: root

    required property var screen
    screen: root.screen

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top:   true
        left:  true
        right: true
    }

    implicitWidth: 360
    implicitHeight: root.screen ? root.screen.height : 800

    WlrLayershell.layer: WlrLayer.Overlay
    visible: slidePanel.windowVisible

    property date today: new Date()
    property date displayedDate: new Date()

    ListModel {
        id: days
    }

    function rebuildDays() {
        days.clear()

        const year = root.displayedDate.getFullYear()
        const month = root.displayedDate.getMonth()
        const firstDay = new Date(year, month, 1).getDay()
        const daysInMonth = new Date(year, month + 1, 0).getDate()
        const daysInPreviousMonth = new Date(year, month, 0).getDate()

        for (let i = 0; i < 42; i++) {
            const dayOffset = i - firstDay
            let cellDate = new Date(year, month, dayOffset + 1)
            let currentMonth = true

            if (dayOffset < 0) {
                cellDate = new Date(year, month - 1, daysInPreviousMonth + dayOffset + 1)
                currentMonth = false
            } else if (dayOffset >= daysInMonth) {
                cellDate = new Date(year, month + 1, dayOffset - daysInMonth + 1)
                currentMonth = false
            }

            const isToday = cellDate.getFullYear() === root.today.getFullYear()
                    && cellDate.getMonth() === root.today.getMonth()
                    && cellDate.getDate() === root.today.getDate()

            days.append({
                day: cellDate.getDate(),
                currentMonth: currentMonth,
                isToday: isToday
            })
        }
    }

    function showMonth(offset) {
        root.displayedDate = new Date(
            root.displayedDate.getFullYear(),
            root.displayedDate.getMonth() + offset,
            1
        )
        root.rebuildDays()
    }

    function showToday() {
        root.today = new Date()
        root.displayedDate = new Date(root.today.getFullYear(), root.today.getMonth(), 1)
        root.rebuildDays()
    }

    function isShowingCurrentMonth() {
        return root.displayedDate.getFullYear() === root.today.getFullYear()
                && root.displayedDate.getMonth() === root.today.getMonth()
    }

    Component.onCompleted: root.showToday()

    Connections {
        target: Popups

        function onCalendarOpenChanged() {
            if (Popups.calendarOpen) {
                root.showToday()
            }
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: true

        onTriggered: {
            const previousDay = root.today.getDate()
            root.today = new Date()

            if (previousDay !== root.today.getDate() || root.isShowingCurrentMonth())
                root.rebuildDays()
        }
    }

    mask: Region {
        x:      (root.implicitWidth - card.width) / 2
        y:      Theme.barHeight + 8
        width:  card.width
        height: card.height
    }

    PopupSlide {
        id: slidePanel
        anchors.fill: parent
        edge: "top"
        open: Popups.calendarOpen
        onCloseRequested: Popups.calendarOpen = false

        Rectangle {
            id: card
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: Theme.barHeight + 8
            }

            width: 340
            height: 350
            radius: Theme.popupRadius
            color: Colors.surfaceContainer
            border.color: Colors.outlineVariant
            border.width: Theme.popupBorder
            clip: true

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 14
                }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: Qt.formatDateTime(root.displayedDate, "MMMM yyyy")
                        color: Colors.on_Surface
                        font.pixelSize: 17
                        font.bold: true
                        font.family: Fonts.font
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 16
                        color: prevHover.containsMouse ? Colors.primaryContainer : Colors.surfaceContainerHigh

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            color: Colors.on_Surface
                            font.pixelSize: 24
                            font.family: Fonts.font
                        }

                        MouseArea {
                            id: prevHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showMonth(-1)
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 16
                        color: nextHover.containsMouse ? Colors.primaryContainer : Colors.surfaceContainerHigh

                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            color: Colors.on_Surface
                            font.pixelSize: 24
                            font.family: Fonts.font
                        }

                        MouseArea {
                            id: nextHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showMonth(1)
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

                        Text {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            text: modelData
                            color: Colors.on_SurfaceVariant
                            font.pixelSize: 10
                            font.bold: true
                            font.family: Fonts.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: days

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumWidth: 36
                            Layout.minimumHeight: 36
                            radius: 18
                            color: model.isToday ? Colors.primaryContainer
                                : dayHover.containsMouse ? Colors.surfaceContainerHigh
                                : "transparent"
                            opacity: model.currentMonth ? 1 : 0.35

                            Text {
                                anchors.centerIn: parent
                                text: model.day
                                color: model.isToday ? Colors.on_PrimaryContainer : Colors.on_Surface
                                font.pixelSize: 12
                                font.bold: model.isToday
                                font.family: Fonts.font
                            }

                            MouseArea {
                                id: dayHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.outlineVariant
                    opacity: 0.5
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: 15
                    color: todayHover.containsMouse ? Colors.primaryContainer : Colors.surfaceContainerHigh
                    visible: !root.isShowingCurrentMonth()

                    Text {
                        anchors.centerIn: parent
                        text: "Today"
                        color: Colors.on_Surface
                        font.pixelSize: 11
                        font.bold: true
                        font.family: Fonts.font
                    }

                    MouseArea {
                        id: todayHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showToday()
                    }
                }
            }
        }
    }
}

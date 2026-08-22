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

    implicitWidth: 380
    implicitHeight: root.screen ? root.screen.height : 800

    WlrLayershell.layer: WlrLayer.Overlay
    visible: slidePanel.windowVisible

    property date today:         new Date()
    property date displayedDate: new Date()
    property date selectedDate:  new Date()

    property Item selectedCell: null
    property bool selectedHighlightReady: false

    property int pendingMonthOffset: 0
    property int monthSlideDirection: 1

    ListModel {
        id: days
    }

    function sameDate(first, second) {
        return first.getFullYear() === second.getFullYear()
                && first.getMonth() === second.getMonth()
                && first.getDate() === second.getDate()
    }

    function isSameMonth(first, second) {
        return first.getFullYear() === second.getFullYear()
                && first.getMonth() === second.getMonth()
    }

    function monthIndex(value) {
        return value.getFullYear() * 12 + value.getMonth()
    }

    function rebuildDays() {
        root.selectedCell = null

        days.clear()

        const year = root.displayedDate.getFullYear()
        const month = root.displayedDate.getMonth()

        const firstDay = new Date(year, month, 1).getDay()
        const daysInMonth = new Date(year, month + 1, 0).getDate()

        for (let i = 0; i < 42; i++) {
            const dayOffset = i - firstDay
            const cellDate = new Date(year, month, dayOffset + 1)

            days.append({
                day:          cellDate.getDate(),
                month:        cellDate.getMonth(),
                year:         cellDate.getFullYear(),
                currentMonth: cellDate.getMonth() === month,
                isToday:      root.sameDate(cellDate, root.today),
                isSelected:   root.sameDate(cellDate, root.selectedDate)
            })
        }
    }

    function updateSelection() {
        for (let i = 0; i < days.count; i++) {
            const item = days.get(i)

            days.setProperty(
                i,
                "isSelected",
                item.year === root.selectedDate.getFullYear()
                    && item.month === root.selectedDate.getMonth()
                    && item.day === root.selectedDate.getDate()
            )
        }
    }

    function setSelectedCell(cell) {
        root.selectedCell = cell
        root.selectedHighlightReady = true
    }

    function selectDate(year, month, day) {
        if (monthAnimation.running)
            return

        const selected = new Date(year, month, day)

        root.selectedDate = selected

        const currentMonth = root.monthIndex(root.displayedDate)
        const selectedMonth = root.monthIndex(selected)
        const offset = selectedMonth - currentMonth

        if (offset !== 0) {
            root.showMonth(offset)
            return
        }

        root.updateSelection()
    }

    function showMonth(offset) {
        if (monthAnimation.running || offset === 0)
            return

        root.pendingMonthOffset = offset
        root.monthSlideDirection = offset > 0 ? -1 : 1

        monthAnimation.start()
    }

    function showToday(animateToToday) {
        if (animateToToday === undefined)
            animateToToday = false

        const currentDate = new Date()

        root.today = currentDate
        root.selectedDate = new Date(
            currentDate.getFullYear(),
            currentDate.getMonth(),
            currentDate.getDate()
        )

        const currentMonth = root.monthIndex(root.displayedDate)
        const todayMonth = root.monthIndex(currentDate)
        const offset = todayMonth - currentMonth

        if (animateToToday && offset !== 0) {
            root.pendingMonthOffset = offset
            root.monthSlideDirection = offset > 0 ? -1 : 1

            monthAnimation.start()
            return
        }

        root.displayedDate = new Date(
            currentDate.getFullYear(),
            currentDate.getMonth(),
            1
        )

        root.rebuildDays()
    }

    function isShowingCurrentMonth() {
        return root.isSameMonth(root.displayedDate, root.today)
    }

    function isTodaySelected() {
        return root.sameDate(root.selectedDate, root.today)
    }

    Component.onCompleted: root.showToday(false)

    Connections {
        target: Popups

        function onCalendarOpenChanged() {
            if (Popups.calendarOpen)
                root.showToday(false)
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: true

        onTriggered: {
            const currentDate = new Date()

            if (!root.sameDate(currentDate, root.today)) {
                root.today = currentDate

                if (root.isShowingCurrentMonth())
                    root.rebuildDays()
            }
        }
    }

    SequentialAnimation {
        id: monthAnimation

        ParallelAnimation {
            NumberAnimation {
                target: monthGridTransform
                property: "x"
                to: root.monthSlideDirection * (gridViewport.width + 24)
                duration: 180
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                target: gridViewport
                property: "opacity"
                to: 0
                duration: 140
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                target: monthHeader
                property: "opacity"
                to: 0
                duration: 140
                easing.type: Easing.InCubic
            }
        }

        ScriptAction {
            script: {
                root.displayedDate = new Date(
                    root.displayedDate.getFullYear(),
                    root.displayedDate.getMonth() + root.pendingMonthOffset,
                    1
                )

                root.rebuildDays()

                monthGridTransform.x =
                    -root.monthSlideDirection * (gridViewport.width + 24)

                monthHeaderTransform.x =
                    -root.monthSlideDirection * 24
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: monthGridTransform
                property: "x"
                to: 0
                duration: 220
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: gridViewport
                property: "opacity"
                to: 1
                duration: 180
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: monthHeaderTransform
                property: "x"
                to: 0
                duration: 220
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: monthHeader
                property: "opacity"
                to: 1
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    mask: Region {
        x:      (root.width - card.width) / 2
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
                top:             parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin:       Theme.barHeight + 8
            }

            width:  360
            height: 398

            radius:       Theme.popupRadius
            color:        Colors.surfaceContainer
            border.color: Colors.outlineVariant
            border.width: Theme.popupBorder

            clip: true

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 16
                }

                spacing: 10

                Item {
                    id: calendarHeader

                    Layout.fillWidth: true
                    Layout.preferredHeight: 46

                    ColumnLayout {
                        id: monthHeader

                        anchors.left: parent.left
                        anchors.top: parent.top

                        spacing: 2

                        transform: Translate {
                            id: monthHeaderTransform
                        }

                        Text {
                            text: Qt.formatDateTime(root.displayedDate, "MMMM")

                            color: Colors.on_Surface

                            font.pixelSize: 17
                            font.bold: true
                            font.family: Fonts.font
                        }

                        Text {
                            text: Qt.formatDateTime(root.displayedDate, "yyyy")

                            color: Colors.on_SurfaceVariant

                            font.pixelSize: 10
                            font.family: Fonts.font
                        }
                    }

                    RowLayout {
                        anchors.right: parent.right
                        anchors.top: parent.top

                        spacing: 6

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32

                            radius: 16

                            color: prevHover.containsMouse
                                    ? Colors.primaryContainer
                                    : Colors.surfaceContainerHigh

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.hoverFadeDuration
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -2

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

                            color: nextHover.containsMouse
                                    ? Colors.primaryContainer
                                    : Colors.surfaceContainerHigh

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.hoverFadeDuration
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -2

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
                            Layout.preferredHeight: 22

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

                Item {
                    id: gridViewport

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: true

                    Rectangle {
                        id: selectedHighlight

                        z: 0

                        x: root.selectedCell ? root.selectedCell.x : 0
                        y: root.selectedCell ? root.selectedCell.y : 0
                        width: root.selectedCell ? root.selectedCell.width : 0
                        height: root.selectedCell ? root.selectedCell.height : 0

                        radius: width / 2

                        color: Colors.primaryContainer

                        opacity: root.selectedHighlightReady && root.selectedCell ? 1 : 0

                        Behavior on x {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on y {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on width {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on height {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    GridLayout {
                        id: dayGrid

                        anchors.fill: parent

                        columns: 7

                        rowSpacing: 4
                        columnSpacing: 4

                        transform: Translate {
                            id: monthGridTransform
                        }

                        Repeater {
                            model: days

                            delegate: Rectangle {
                                id: dayCell

                                required property var modelData

                                property bool isSelected: modelData.isSelected

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Layout.minimumWidth: 36
                                Layout.minimumHeight: 36

                                radius: 18

                                z: 1

                                opacity: modelData.currentMonth ? 1 : 0.35

                                color: dayHover.containsMouse
                                        ? Colors.surfaceContainerHigh
                                        : "transparent"

                                border.color: modelData.isToday
                                        ? Colors.primary
                                        : "transparent"

                                border.width: modelData.isToday ? 1.5 : 0

                                scale: isSelected ? 1.04 : 1

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.hoverFadeDuration
                                    }
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Theme.hoverFadeDuration
                                    }
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 160
                                        easing.type: Easing.OutBack
                                    }
                                }

                                Component.onCompleted: {
                                    if (isSelected)
                                        Qt.callLater(function() {
                                            root.setSelectedCell(dayCell)
                                        })
                                }

                                onIsSelectedChanged: {
                                    if (isSelected)
                                        Qt.callLater(function() {
                                            root.setSelectedCell(dayCell)
                                        })
                                }

                                Text {
                                    anchors.centerIn: parent

                                    text: modelData.day

                                    color: modelData.isSelected
                                            ? Colors.on_PrimaryContainer
                                            : Colors.on_Surface

                                    font.pixelSize: 12
                                    font.bold: modelData.isSelected || modelData.isToday
                                    font.family: Fonts.font
                                }

                                MouseArea {
                                    id: dayHover

                                    anchors.fill: parent

                                    hoverEnabled: true

                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: root.selectDate(
                                        modelData.year,
                                        modelData.month,
                                        modelData.day
                                    )
                                }
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

                RowLayout {
                    Layout.fillWidth: true

                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true

                        spacing: 2

                        Text {
                            text: Qt.formatDateTime(root.selectedDate, "ddd, MMM d")

                            color: Colors.on_Surface

                            font.pixelSize: 11
                            font.bold: true
                            font.family: Fonts.font
                        }

                        Text {
                            text: Qt.formatDateTime(root.selectedDate, "yyyy")

                            color: Colors.on_SurfaceVariant

                            font.pixelSize: 9
                            font.family: Fonts.font
                        }
                    }

                    Item {
                        Layout.preferredWidth: 70
                        Layout.preferredHeight: 30

                        Rectangle {
                            id: todayButton

                            anchors.centerIn: parent

                            width: parent.width
                            height: parent.height

                            radius: 15

                            color: todayHover.containsMouse
                                    ? Colors.primaryContainer
                                    : Colors.surfaceContainerHigh

                            opacity: root.isTodaySelected() ? 0 : 1
                            scale: root.isTodaySelected() ? 0.82 : 1

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 160
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutBack
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.hoverFadeDuration
                                }
                            }

                            Text {
                                anchors.centerIn: parent

                                text: "Today"

                                color: Colors.on_Surface

                                font.pixelSize: 10
                                font.bold: true
                                font.family: Fonts.font
                            }

                            MouseArea {
                                id: todayHover

                                anchors.fill: parent

                                hoverEnabled: true
                                enabled: !root.isTodaySelected()

                                cursorShape: Qt.PointingHandCursor

                                onClicked: root.showToday(true)
                            }
                        }
                    }
                }
            }
        }
    }
}

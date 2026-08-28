import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services

PanelWindow {
    id: root

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        bottom: true
        right: true
    }

    implicitWidth: 720
    implicitHeight: 620

    WlrLayershell.layer: WlrLayer.Overlay

    WlrLayershell.keyboardFocus: Popups.clipboardOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    visible: slide.windowVisible

    Connections {
        target: Popups

        function onClipboardOpenChanged() {
            if (Popups.clipboardOpen) {
                ClipboardService.refresh()
                ClipboardService.searchQuery = ""
                ClipboardService.filterCategory = "all"
                searchField.text = ""
                listView.currentIndex = 0
                clipboardFocusTimer.start()
            }
        }
    }

    Component.onCompleted: {
        if (Popups.clipboardOpen) {
            ClipboardService.refresh()
            ClipboardService.searchQuery = ""
            ClipboardService.filterCategory = "all"
            searchField.text = ""
            listView.currentIndex = 0
            clipboardFocusTimer.start()
        }
    }

    Timer {
        id: clipboardFocusTimer

        interval: 80
        running: false
        repeat: false

        onTriggered: searchField.forceActiveFocus()
    }

    PopupSlide {
        id: slide

        anchors.fill: parent

        edge: "bottom"
        open: Popups.clipboardOpen

        onCloseRequested: Popups.clipboardOpen = false

        Rectangle {
            anchors {
                bottom: parent.bottom
                right: parent.right
                bottomMargin: 18
                rightMargin: 18
            }

            width: 700
            height: 520

            radius: Theme.popupRadius

            color: Colors.surfaceContainer

            border.color: Colors.outlineVariant
            border.width: Theme.popupBorder

            clip: true

            ColumnLayout {
                id: mainCol

                anchors {
                    fill: parent
                    margins: 16
                }

                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "󰆏"
                        color: Colors.primary
                        font.pixelSize: 18
                        font.family: Fonts.fontM
                    }

                    TextField {
                        id: searchField

                        Layout.fillWidth: true
                        height: 32

                        placeholderText: "Search clipboard..."
                        font.family: Fonts.font
                        font.pixelSize: 12
                        color: Colors.on_Surface
                        placeholderTextColor: Colors.outline

                        onTextChanged: {
                            ClipboardService.searchQuery = text
                            listView.currentIndex = 0
                        }

                        Keys.onEscapePressed: (event) => {
                            Popups.clipboardOpen = false
                            event.accepted = true
                        }

                        Keys.onDownPressed: (event) => {
                            listView.forceActiveFocus()

                            if (listView.count > 0)
                                listView.incrementCurrentIndex()

                            listView.positionViewAtIndex(listView.currentIndex, ListView.Contain)
                            event.accepted = true
                        }

                        Keys.onUpPressed: (event) => {
                            listView.forceActiveFocus()

                            if (listView.count > 0)
                                listView.decrementCurrentIndex()

                            listView.positionViewAtIndex(listView.currentIndex, ListView.Contain)
                            event.accepted = true
                        }

                        background: Rectangle {
                            radius: 8
                            color: Colors.surfaceContainerHigh
                            border.width: 1
                            border.color: searchField.activeFocus ? Colors.primary : Colors.outline

                            Behavior on border.color {
                                ColorAnimation { duration: Theme.hoverFadeDuration }
                            }
                        }
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: wipeHov.containsMouse ? Colors.errorContainer : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: Theme.hoverFadeDuration }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰆴"
                            font.family: Fonts.fontM
                            font.pixelSize: 16
                            color: wipeHov.containsMouse ? Colors.on_ErrorContainer : Colors.outline
                        }

                        MouseArea {
                            id: wipeHov

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: ClipboardService.wipe()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { key: "all", label: "All" },
                            { key: "text", label: "Text" },
                            { key: "images", label: "Images" },
                            { key: "link", label: "Links" },
                            { key: "code", label: "Code" },
                            { key: "pinned", label: "Pinned" }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            Layout.preferredWidth: filterText.implicitWidth + 20
                            Layout.preferredHeight: 28

                            radius: 8

                            color: ClipboardService.filterCategory === modelData.key
                                   ? Colors.primaryContainer
                                   : filterHov.containsMouse
                                       ? Colors.surfaceContainerHigh
                                       : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: Theme.hoverFadeDuration }
                            }

                            Text {
                                id: filterText

                                anchors.centerIn: parent

                                text: modelData.label

                                color: ClipboardService.filterCategory === modelData.key
                                       ? Colors.on_PrimaryContainer
                                       : Colors.on_SurfaceVariant

                                font.family: Fonts.font
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: filterHov

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    ClipboardService.setFilterCategory(modelData.key)
                                    listView.currentIndex = 0
                                    searchField.forceActiveFocus()
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: ClipboardService.history.length + " items"
                        color: Colors.outline
                        font.family: Fonts.font
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.outlineVariant
                    opacity: 0.5
                }

                Rectangle {
                    visible: ClipboardService.errorMessage !== ""

                    Layout.fillWidth: true
                    implicitHeight: Math.max(errorText.implicitHeight + 18, 38)

                    radius: 8
                    color: Colors.errorContainer

                    RowLayout {
                        anchors {
                            fill: parent
                            margins: 10
                        }

                        spacing: 8

                        Text {
                            id: errorText

                            Layout.fillWidth: true

                            text: ClipboardService.errorMessage

                            color: Colors.on_ErrorContainer

                            font.family: Fonts.font
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                        }

                        Rectangle {
                            width: 52
                            height: 26
                            radius: 7

                            color: retryHov.containsMouse
                                   ? Colors.on_ErrorContainer
                                   : "transparent"

                            Text {
                                anchors.centerIn: parent

                                text: "Retry"

                                color: retryHov.containsMouse
                                       ? Colors.errorContainer
                                       : Colors.on_ErrorContainer

                                font.family: Fonts.font
                                font.pixelSize: 10
                            }

                            MouseArea {
                                id: retryHov

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: ClipboardService.refresh()
                            }
                        }
                    }
                }

                Item {
                    visible: ClipboardService.loading &&
                             ClipboardService.filteredHistory.length === 0

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent

                        text: "Loading clipboard history..."

                        font.family: Fonts.font
                        font.pixelSize: 12
                        color: Colors.outline
                    }
                }

                ListView {
                    id: listView

                    visible: !ClipboardService.loading ||
                             ClipboardService.filteredHistory.length > 0

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    focus: true
                    currentIndex: 0
                    clip: true
                    spacing: 4

                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 2500
                    maximumFlickVelocity: 5000

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    model: ClipboardService.filteredHistory

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            Popups.clipboardOpen = false
                            event.accepted = true
                        } else if (event.key === Qt.Key_Down) {
                            incrementCurrentIndex()
                            positionViewAtIndex(currentIndex, ListView.Contain)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            decrementCurrentIndex()
                            positionViewAtIndex(currentIndex, ListView.Contain)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            const item = ClipboardService.filteredHistory[currentIndex]

                            if (item) {
                                ClipboardService.copy(item)
                                Popups.clipboardOpen = false
                            }

                            event.accepted = true
                        } else if (event.text.length > 0) {
                            searchField.forceActiveFocus()
                            searchField.insert(searchField.cursorPosition, event.text)
                            event.accepted = true
                        }
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: listView.width - 6
                        height: modelData.kind === "image" ? 112 : 62

                        radius: 8

                        color: index === listView.currentIndex
                                   ? Colors.surfaceContainerHigh
                                   : itemHov.containsMouse
                                       ? Colors.background
                                       : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: 140
                                easing.type: Easing.OutCubic
                            }
                        }

                        MouseArea {
                            id: itemHov

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: listView.currentIndex = index

                            onClicked: {
                                ClipboardService.copy(modelData)
                                Popups.clipboardOpen = false
                            }
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                margins: 10
                            }

                            spacing: 10

                            Item {
                                Layout.preferredWidth: modelData.kind === "image" ? 96 : 28
                                Layout.preferredHeight: modelData.kind === "image" ? 88 : 28
                                Layout.alignment: Qt.AlignVCenter

                                Rectangle {
                                    anchors.fill: parent

                                    visible: modelData.kind !== "image"

                                    radius: 8
                                    color: Colors.surfaceContainerHighest

                                    Text {
                                        anchors.centerIn: parent

                                        text: modelData.kind === "link"
                                              ? "󰌷"
                                              : modelData.kind === "code"
                                                  ? "󰅨"
                                                  : "󰉿"

                                        font.family: Fonts.fontM
                                        font.pixelSize: 15
                                        color: Colors.primary
                                    }
                                }

                                Image {
                                    id: imagePreview

                                    property bool imageReady: false

                                    anchors.fill: parent

                                    visible: modelData.kind === "image" &&
                                             imageReady

                                    source: imageReady
                                            ? modelData.imagePath
                                            : ""

                                    sourceSize.width: 96
                                    sourceSize.height: 88

                                    fillMode: Image.PreserveAspectFit

                                    asynchronous: true
                                    cache: false

                                    Process {
                                        id: imageProc

                                        command: [
                                            "sh",
                                            "-c",
                                            "mkdir -p \"$1\" && printf '%s\\t\\n' \"$2\" | cliphist decode > \"$3\"",
                                            "--",
                                            Quickshell.cachePath("clipboard/images"),
                                            modelData.id,
                                            modelData.imagePath
                                        ]

                                        running: false

                                        Component.onCompleted: {
                                            if (modelData.kind === "image")
                                                imageProc.running = true
                                        }

                                        onExited: (exitCode, exitStatus) => {
                                            imagePreview.imageReady = exitCode === 0
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent

                                    visible: modelData.kind === "image" &&
                                             !imagePreview.imageReady

                                    radius: 8
                                    color: Colors.surfaceContainerHighest

                                    Text {
                                        anchors.centerIn: parent

                                        text: "󰉏"

                                        font.family: Fonts.fontM
                                        font.pixelSize: 18
                                        color: Colors.outline
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                spacing: 3

                                Text {
                                    Layout.fillWidth: true

                                    text: modelData.preview

                                    color: Colors.on_Surface

                                    font.family: Fonts.font
                                    font.pixelSize: 12

                                    maximumLineCount: modelData.kind === "image" ? 1 : 2

                                    elide: Text.ElideRight
                                    wrapMode: Text.WrapAnywhere
                                    verticalAlignment: Text.AlignVCenter
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: modelData.kind === "image"
                                              ? modelData.sizeText + " • " +
                                                modelData.width + " × " +
                                                modelData.height
                                              : modelData.kind === "link"
                                                  ? "Link"
                                                  : modelData.kind === "code"
                                                      ? "Code"
                                                      : "Text"

                                        color: Colors.outline

                                        font.family: Fonts.font
                                        font.pixelSize: 9
                                    }

                                    Text {
                                        text: "•"

                                        color: Colors.outlineVariant

                                        font.pixelSize: 9
                                    }

                                    Text {
                                        text: ClipboardService.recencyLabel(modelData, index)

                                        color: Colors.outline

                                        font.family: Fonts.font
                                        font.pixelSize: 9
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        visible: ClipboardService.isPinned(modelData)

                                        text: "󰐃"

                                        color: Colors.primary

                                        font.family: Fonts.fontM
                                        font.pixelSize: 12
                                    }
                                }
                            }

                            Row {
                                visible: itemHov.containsMouse

                                Layout.preferredWidth: 60
                                Layout.alignment: Qt.AlignVCenter

                                spacing: 4

                                Rectangle {
                                    width: 28
                                    height: 28

                                    radius: 8

                                    color: pinHov.containsMouse
                                           ? Colors.primaryContainer
                                           : "transparent"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Theme.hoverFadeDuration
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent

                                        text: ClipboardService.isPinned(modelData)
                                              ? "󰐃"
                                              : "󰐄"

                                        color: pinHov.containsMouse
                                               ? Colors.on_PrimaryContainer
                                               : Colors.outline

                                        font.family: Fonts.fontM
                                        font.pixelSize: 14
                                    }

                                    MouseArea {
                                        id: pinHov

                                        anchors.fill: parent

                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked: {
                                            ClipboardService.togglePin(modelData)
                                            mouse.accepted = true
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 28
                                    height: 28

                                    radius: 8

                                    color: deleteHov.containsMouse
                                           ? Colors.errorContainer
                                           : "transparent"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Theme.hoverFadeDuration
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent

                                        text: "󰆴"

                                        color: deleteHov.containsMouse
                                               ? Colors.on_ErrorContainer
                                               : Colors.outline

                                        font.family: Fonts.fontM
                                        font.pixelSize: 13
                                    }

                                    MouseArea {
                                        id: deleteHov

                                        anchors.fill: parent

                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked: {
                                            ClipboardService.deleteItem(modelData)
                                            mouse.accepted = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: !ClipboardService.loading &&
                             ClipboardService.errorMessage === "" &&
                             ClipboardService.filteredHistory.length === 0

                    Layout.alignment: Qt.AlignHCenter

                    text: ClipboardService.history.length === 0
                          ? "Clipboard is empty"
                          : "No clipboard entries match your filters"

                    font.family: Fonts.font
                    font.pixelSize: 12

                    color: Colors.outline

                    topPadding: 8
                    bottomPadding: 8
                }
            }
        }
    }
}

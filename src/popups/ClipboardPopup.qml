import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services

PanelWindow {
    id: root

    property bool wipeConfirmOpen: false

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        bottom: true
        right:  true
    }

    implicitWidth:  720
    implicitHeight: 620

    WlrLayershell.layer: WlrLayer.Overlay
    visible: slide.windowVisible

    WlrLayershell.keyboardFocus:
        Popups.clipboardOpen
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

    Connections {
        target: Popups

        function onClipboardOpenChanged() {
            if (Popups.clipboardOpen) {
                ClipboardService.searchQuery = ""
                ClipboardService.filterCategory = "all"

                searchField.text = ""
                listView.currentIndex = 0
                root.wipeConfirmOpen = false

                ClipboardService.refresh()
                clipboardFocusTimer.start()
            } else {
                root.wipeConfirmOpen = false
            }
        }
    }

    Component.onCompleted: {
        if (Popups.clipboardOpen) {
            ClipboardService.searchQuery = ""
            ClipboardService.filterCategory = "all"

            searchField.text = ""
            listView.currentIndex = 0

            ClipboardService.refresh()
            clipboardFocusTimer.start()
        }
    }

    Timer {
        id: clipboardFocusTimer

        interval: 80
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
            id: card

            anchors {
                bottom:       parent.bottom
                right:        parent.right
                bottomMargin: 18
                rightMargin:  18
            }

            width:  700
            height: 520

            radius:       Theme.popupRadius
            color:        Colors.surfaceContainer
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
                        text:        "󰆏"
                        color:       Colors.primary
                        font.pixelSize: 18
                        font.family:  Fonts.fontM
                    }

                    TextField {
                        id: searchField

                        Layout.fillWidth: true
                        height: 32

                        placeholderText: "Search clipboard..."
                        font.pixelSize: 12
                        font.family:  Fonts.font
                        color:         Colors.on_Surface
                        placeholderTextColor: Colors.outline

                        selectByMouse: true

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

                            listView.positionViewAtIndex(
                                listView.currentIndex,
                                ListView.Contain
                            )

                            event.accepted = true
                        }

                        Keys.onUpPressed: (event) => {
                            listView.forceActiveFocus()

                            if (listView.count > 0)
                                listView.decrementCurrentIndex()

                            listView.positionViewAtIndex(
                                listView.currentIndex,
                                ListView.Contain
                            )

                            event.accepted = true
                        }

                        background: Rectangle {
                            radius: 8
                            color: Colors.surfaceContainerHigh

                            border.width: 1
                            border.color:
                                searchField.activeFocus
                                    ? Colors.primary
                                    : Colors.outline

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: Theme.hoverFadeDuration
                                }
                            }
                        }
                    }

                    Rectangle {
                        width:  32
                        height: 32
                        radius: 8

                        color:
                            wipeHov.containsMouse
                                ? Colors.errorContainer
                                : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.hoverFadeDuration
                            }
                        }

                        Text {
                            anchors.centerIn: parent

                            text:        "󰆴"
                            color:
                                wipeHov.containsMouse
                                    ? Colors.on_ErrorContainer
                                    : Colors.outline
                            font.pixelSize: 16
                            font.family:  Fonts.fontM
                        }

                        MouseArea {
                            id: wipeHov

                            anchors.fill: parent

                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor

                            onClicked: {
                                root.wipeConfirmOpen = true
                            }
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

                            Layout.preferredWidth:
                                filterText.implicitWidth + 20

                            Layout.preferredHeight: 28

                            radius: 8

                            color:
                                ClipboardService.filterCategory === modelData.key
                                    ? Colors.primaryContainer
                                    : filterHov.containsMouse
                                        ? Colors.surfaceContainerHigh
                                        : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.hoverFadeDuration
                                }
                            }

                            Text {
                                id: filterText

                                anchors.centerIn: parent

                                text: modelData.label

                                color:
                                    ClipboardService.filterCategory === modelData.key
                                        ? Colors.on_PrimaryContainer
                                        : Colors.on_SurfaceVariant

                                font.pixelSize: 11
                                font.family:  Fonts.font
                            }

                            MouseArea {
                                id: filterHov

                                anchors.fill: parent

                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor

                                onClicked: {
                                    ClipboardService.setFilterCategory(
                                        modelData.key
                                    )

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
                        text: ClipboardService.resultCountLabel()

                        color:      Colors.outline
                        font.pixelSize: 10
                        font.family:  Fonts.font
                    }
                }

                Rectangle {
                    visible: root.wipeConfirmOpen

                    Layout.fillWidth: true
                    implicitHeight: 42

                    radius: 8

                    color: Colors.errorContainer

                    RowLayout {
                        anchors {
                            fill:    parent
                            margins: 8
                        }

                        spacing: 8

                        Text {
                            Layout.fillWidth: true

                            text: "Clear all clipboard history?"

                            color: Colors.on_ErrorContainer

                            font.pixelSize: 11
                            font.family:  Fonts.font
                        }

                        Rectangle {
                            width: 58
                            height: 26
                            radius: 7

                            color:
                                cancelWipeHov.containsMouse
                                    ? Colors.surfaceContainer
                                    : "transparent"

                            Text {
                                anchors.centerIn: parent

                                text:  "Cancel"
                                color: Colors.on_ErrorContainer

                                font.pixelSize: 10
                                font.family:  Fonts.font
                            }

                            MouseArea {
                                id: cancelWipeHov

                                anchors.fill: parent

                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor

                                onClicked: root.wipeConfirmOpen = false
                            }
                        }

                        Rectangle {
                            width: 54
                            height: 26
                            radius: 7

                            color:
                                confirmWipeHov.containsMouse
                                    ? Colors.error
                                    : Colors.surfaceContainer

                            Text {
                                anchors.centerIn: parent

                                text:  "Clear"

                                color:
                                    confirmWipeHov.containsMouse
                                        ? Colors.on_Error
                                        : Colors.on_Surface

                                font.pixelSize: 10
                                font.family:  Fonts.font
                            }

                            MouseArea {
                                id: confirmWipeHov

                                anchors.fill: parent

                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor

                                onClicked: {
                                    root.wipeConfirmOpen = false
                                    ClipboardService.wipe()
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1

                    color:   Colors.outlineVariant
                    opacity: 0.5
                }

                Rectangle {
                    visible: ClipboardService.errorMessage !== ""

                    Layout.fillWidth: true
                    implicitHeight:
                        Math.max(errorText.implicitHeight + 18, 38)

                    radius: 8

                    color: Colors.errorContainer

                    RowLayout {
                        anchors {
                            fill:    parent
                            margins: 10
                        }

                        spacing: 8

                        Text {
                            id: errorText

                            Layout.fillWidth: true

                            text: ClipboardService.errorMessage

                            color: Colors.on_ErrorContainer

                            font.pixelSize: 11
                            font.family:  Fonts.font
                            wrapMode:    Text.Wrap
                        }

                        Rectangle {
                            width: 52
                            height: 26
                            radius: 7

                            color:
                                retryHov.containsMouse
                                    ? Colors.on_ErrorContainer
                                    : "transparent"

                            Text {
                                anchors.centerIn: parent

                                text:  "Retry"

                                color:
                                    retryHov.containsMouse
                                        ? Colors.errorContainer
                                        : Colors.on_ErrorContainer

                                font.pixelSize: 10
                                font.family:  Fonts.font
                            }

                            MouseArea {
                                id: retryHov

                                anchors.fill: parent

                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor

                                onClicked: ClipboardService.refresh()
                            }
                        }
                    }
                }

                Item {
                    visible:
                        ClipboardService.loading &&
                        ClipboardService.filteredHistory.length === 0

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent

                        text: "Loading clipboard history..."

                        color: Colors.outline

                        font.pixelSize: 12
                        font.family:  Fonts.font
                    }
                }

                ListView {
                    id: listView

                    visible:
                        !ClipboardService.loading ||
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
                            positionViewAtIndex(
                                currentIndex,
                                ListView.Contain
                            )
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            decrementCurrentIndex()
                            positionViewAtIndex(
                                currentIndex,
                                ListView.Contain
                            )
                            event.accepted = true
                        } else if (
                            event.key === Qt.Key_Return ||
                            event.key === Qt.Key_Enter
                        ) {
                            const item =
                                ClipboardService.filteredHistory[currentIndex]

                            if (item) {
                                ClipboardService.copy(item)
                                Popups.clipboardOpen = false
                            }

                            event.accepted = true
                        } else if (event.text.length > 0) {
                            searchField.forceActiveFocus()
                            searchField.insert(
                                searchField.cursorPosition,
                                event.text
                            )
                            event.accepted = true
                        }
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: listView.width - 6

                        height:
                            modelData.kind === "image"
                                ? 112
                                : 62

                        radius: 8

                        color:
                            index === listView.currentIndex
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

                        HoverHandler {
                            id: itemHover
                        }

                        Component.onCompleted: {
                            if (modelData.kind === "image")
                                ClipboardService.ensureImage(modelData)
                        }

                        onModelDataChanged: {
                            if (modelData.kind === "image")
                                ClipboardService.ensureImage(modelData)
                        }

                        MouseArea {
                            id: itemHov

                            anchors.fill: parent

                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor

                            onEntered: {
                                listView.currentIndex = index
                            }

                            onClicked: {
                                ClipboardService.copy(modelData)
                                Popups.clipboardOpen = false
                            }
                        }

                        RowLayout {
                            anchors {
                                fill:    parent
                                margins: 10
                            }

                            spacing: 10

                            Item {
                                Layout.preferredWidth:
                                    modelData.kind === "image"
                                        ? 150
                                        : 28

                                Layout.preferredHeight:
                                    modelData.kind === "image"
                                        ? 92
                                        : 28

                                Layout.alignment: Qt.AlignVCenter

                                Rectangle {
                                    anchors.fill: parent

                                    visible: modelData.kind !== "image"

                                    radius: 8

                                    color: Colors.surfaceContainerHighest

                                    Text {
                                        anchors.centerIn: parent

                                        text:
                                            modelData.kind === "link"
                                                ? "󰌷"
                                                : modelData.kind === "code"
                                                    ? "󰅨"
                                                    : "󰉿"

                                        color:      Colors.primary
                                        font.pixelSize: 15
                                        font.family:  Fonts.fontM
                                    }
                                }

                                Rectangle {
                                    visible: modelData.kind === "image"

                                    anchors.fill: parent

                                    radius: 8

                                    color: Colors.surfaceContainerHighest

                                    clip: true

                                    Image {
                                        anchors.fill: parent

                                        visible:
                                            modelData.kind === "image" &&
                                            ClipboardService.imageStates[modelData.id] === 2

                                        source:
                                            ClipboardService.imageStates[modelData.id] === 2
                                                ? "file://" + modelData.imagePath
                                                : ""

                                        fillMode: Image.PreserveAspectFit

                                        asynchronous: true
                                        cache: false

                                        sourceSize.width: 150
                                        sourceSize.height: 92
                                    }

                                    Text {
                                        visible:
                                            modelData.kind === "image" &&
                                            ClipboardService.imageStates[modelData.id] !== 2

                                        anchors.centerIn: parent

                                        text:
                                            ClipboardService.imageStates[modelData.id] === 3
                                                ? "󰈙"
                                                : "󰉏"

                                        color: Colors.outline

                                        font.pixelSize: 18
                                        font.family:  Fonts.fontM
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                spacing: 3

                                Text {
                                    Layout.fillWidth: true

                                    text:
                                        modelData.kind === "image"
                                            ? "Image"
                                            : modelData.preview

                                    color:      Colors.on_Surface
                                    font.pixelSize: 12
                                    font.family:  Fonts.font

                                    maximumLineCount:
                                        modelData.kind === "image"
                                            ? 1
                                            : 2

                                    elide:      Text.ElideRight
                                    wrapMode:   Text.WrapAnywhere

                                    verticalAlignment:
                                        Text.AlignVCenter
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text:
                                            modelData.kind === "image"
                                                ? modelData.format.toUpperCase() +
                                                  " • " +
                                                  modelData.sizeText +
                                                  " • " +
                                                  modelData.width +
                                                  " × " +
                                                  modelData.height
                                                : modelData.kind === "link"
                                                    ? "Link"
                                                    : modelData.kind === "code"
                                                        ? "Code"
                                                        : "Text"

                                        color:      Colors.outline
                                        font.pixelSize: 9
                                        font.family:  Fonts.font
                                    }

                                    Text {
                                        text:  "•"
                                        color: Colors.outlineVariant
                                        font.pixelSize: 9
                                    }

                                    Text {
                                        text:
                                            ClipboardService.recencyLabel(
                                                modelData
                                            )

                                        color:      Colors.outline
                                        font.pixelSize: 9
                                        font.family:  Fonts.font
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        visible:
                                            ClipboardService.isPinned(modelData)

                                        text:  "󰐃"
                                        color: Colors.primary

                                        font.pixelSize: 12
                                        font.family:  Fonts.fontM
                                    }
                                }
                            }

                            Row {
                                visible: itemHover.hovered

                                Layout.preferredWidth: 60
                                Layout.alignment:     Qt.AlignVCenter

                                spacing: 4

                                Rectangle {
                                    width:  28
                                    height: 28
                                    radius: 8
                                    z: 2

                                    color:
                                        pinHov.containsMouse
                                            ? Colors.primaryContainer
                                            : "transparent"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Theme.hoverFadeDuration
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent

                                        text:
                                            ClipboardService.isPinned(
                                                modelData
                                            )
                                                ? "󰐃"
                                                : "󰐄"

                                        color:
                                            pinHov.containsMouse
                                                ? Colors.on_PrimaryContainer
                                                : Colors.outline

                                        font.pixelSize: 14
                                        font.family:  Fonts.fontM
                                    }

                                    MouseArea {
                                        id: pinHov

                                        anchors.fill: parent

                                        hoverEnabled: true
                                        cursorShape:  Qt.PointingHandCursor

                                        onClicked: (mouse) => {
                                            ClipboardService.togglePin(
                                                modelData
                                            )

                                            mouse.accepted = true
                                        }
                                    }
                                }

                                Rectangle {
                                    width:  28
                                    height: 28
                                    radius: 8
                                    z: 2

                                    color:
                                        deleteHov.containsMouse
                                            ? Colors.errorContainer
                                            : "transparent"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Theme.hoverFadeDuration
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent

                                        text:  "󰆴"

                                        color:
                                            deleteHov.containsMouse
                                                ? Colors.on_ErrorContainer
                                                : Colors.outline

                                        font.pixelSize: 13
                                        font.family:  Fonts.fontM
                                    }

                                    MouseArea {
                                        id: deleteHov

                                        anchors.fill: parent

                                        hoverEnabled: true
                                        cursorShape:  Qt.PointingHandCursor

                                        onClicked: (mouse) => {
                                            ClipboardService.deleteItem(
                                                modelData
                                            )

                                            mouse.accepted = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible:
                        !ClipboardService.loading &&
                        ClipboardService.errorMessage === "" &&
                        ClipboardService.filteredHistory.length === 0

                    Layout.alignment: Qt.AlignHCenter

                    text:
                        ClipboardService.history.length === 0
                            ? "Clipboard is empty"
                            : ClipboardService.searchQuery.trim() !== ""
                                ? "No results for \"" +
                                  ClipboardService.searchQuery +
                                  "\""
                                : "No clipboard entries match your filters"

                    color:      Colors.outline
                    font.pixelSize: 12
                    font.family:  Fonts.font

                    topPadding:    8
                    bottomPadding: 8
                }
            }
        }
    }
}

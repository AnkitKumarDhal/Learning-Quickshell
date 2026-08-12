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

    //property var screen

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        bottom: true
        right: true
    }

    implicitWidth: 720
    implicitHeight: 520

    WlrLayershell.layer: WlrLayer.Overlay

    WlrLayershell.keyboardFocus: Popups.clipboardOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    visible: slide.windowVisible

    Connections {
        target: Popups

        function onClipboardOpenChanged() {
            if (Popups.clipboardOpen) {
                ClipboardService.refresh()
                ClipboardService.searchQuery = ""
                searchField.text = ""
                listView.currentIndex = 0
                // Use a Timer to defer focus until the event loop has fully processed
                // the window visibility and WlrLayershell keyboard grab setup
                clipboardFocusTimer.start()
            }
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
            height: 420

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

                spacing: 12

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

                        Keys.onEscapePressed: {
                            Popups.clipboardOpen = false
                        }

                        Keys.onDownPressed: (event) => {
                            listView.forceActiveFocus()
                            listView.incrementCurrentIndex()
                            listView.positionViewAtIndex(listView.currentIndex, ListView.Contain)
                            event.accepted = true
                        }

                        Keys.onUpPressed: (event) => {
                            listView.forceActiveFocus()
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

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.outlineVariant
                    opacity: 0.5
                }

                ListView {
                    id: listView

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
                        if (event.key === Qt.Key_Down) {
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
                        } else if (event.text.length > 0 && event.key !== Qt.Key_Space) {
                            searchField.forceActiveFocus()
                            searchField.insert(searchField.cursorPosition, event.text)
                            event.accepted = true
                        }
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        readonly property string displayString: {
                            const idx = modelData.indexOf('\t')
                            return idx >= 0 ? modelData.substring(idx + 1) : modelData
                        }

                        width: listView.width - 6
                        height: Math.max(40, itemText.implicitHeight + 16)
                        radius: 8
                        color: index === listView.currentIndex
                                   ? Colors.surfaceContainerHigh
                                   : itemHov.containsMouse
                                       ? Colors.background
                                       : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 140; easing.type: Easing.OutCubic }
                        }

                        Text {
                            id: itemText
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 12
                            }
                            text: displayString
                            color: Colors.on_Surface
                            font.family: Fonts.font
                            font.pixelSize: 12
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            wrapMode: Text.WrapAnywhere
                        }

                        MouseArea {
                            id: itemHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: { listView.currentIndex = index }
                            onClicked: {
                                ClipboardService.copy(modelData)
                                Popups.clipboardOpen = false
                            }
                        }
                    }
                }

                Text {
                    visible: ClipboardService.filteredHistory.length === 0
                    Layout.alignment: Qt.AlignHCenter
                    text: "Clipboard is empty"
                    font.family: Fonts.font
                    font.pixelSize: 12
                    color: Colors.outline
                    topPadding: 16
                    bottomPadding: 16
                }
            }
        }
    }
}

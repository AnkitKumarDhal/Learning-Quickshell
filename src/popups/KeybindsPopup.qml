import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.src.components
import qs.src.services
import qs.src.state
import qs.src.theme

PanelWindow {
    id: root

    required property var screen

    screen: root.screen

    readonly property bool isFocusedScreen: {
        const monitor = root.screen
            ? Hyprland.monitorFor(root.screen)
            : null

        return monitor ? monitor.focused : false
    }

    visible:
        slidePanel.windowVisible &&
        root.isFocusedScreen

    implicitWidth:
        root.screen
            ? root.screen.width * 0.40
            : 0

    implicitHeight: root.screen ? root.screen.height : 800

    anchors {
        top: true
        bottom: true
        right: true
    }

    margins {
        right: 16
    }

    mask: Region {
        x: root.width - popupRect.width
        y: (root.height - popupRect.height) / 2
        width: popupRect.width
        height: popupRect.height
    }

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay

    WlrLayershell.keyboardFocus:
        slidePanel.windowVisible &&
        root.isFocusedScreen
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

    Item {
        id: popupArea

        anchors.fill: parent

        PopupSlide {
            id: slidePanel

            anchors.fill: parent

            edge: "right"

            open: Popups.keybindsOpen && root.isFocusedScreen

            onCloseRequested: Popups.keybindsOpen = false

            focus: windowVisible

            onWindowVisibleChanged: {
                if (windowVisible)
                    forceActiveFocus()
            }

            Keys.onEscapePressed: (event) => {
                Popups.keybindsOpen = false
                event.accepted = true
            }

            Rectangle {
                id: popupRect

                width: root.width
                height: root.height * 0.70

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                color: Colors.surfaceContainer

                radius: Theme.popupRadius

                border.width: 1
                border.color: Colors.outlineVariant

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 20
                    }

                    spacing: 14

                    // ── Header ────────────────────────────────────────────

                    Text {
                        Layout.fillWidth: true

                        text: "Keybinds"

                        color: Colors.on_Surface

                        font.family: Fonts.font
                        font.pixelSize: 17
                        font.bold: true

                        horizontalAlignment:
                            Text.AlignHCenter
                    }

                    Rectangle {
                        Layout.fillWidth: true

                        Layout.preferredHeight: 1

                        color: Colors.outlineVariant
                    }

                    // ── Loading ──────────────────────────────────────────

                    Text {
                        Layout.fillWidth: true

                        visible:
                            KeybindsService.loading

                        text: "Loading keybinds..."

                        color: Colors.on_SurfaceVariant

                        font.family: Fonts.font
                        font.pixelSize: 12

                        horizontalAlignment:
                            Text.AlignHCenter
                    }

                    // ── Error ────────────────────────────────────────────

                    Text {
                        Layout.fillWidth: true

                        visible:
                            !KeybindsService.loading &&
                            KeybindsService.error.length > 0

                        text:
                            KeybindsService.error

                        color: Colors.error

                        font.family: Fonts.font
                        font.pixelSize: 12

                        wrapMode:
                            Text.WordWrap

                        horizontalAlignment:
                            Text.AlignHCenter
                    }

                    // ── Categorized keybinds ──────────────────────────────

                    Flickable {
                        id: keybindsFlickable

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        visible:
                            !KeybindsService.loading &&
                            KeybindsService.error.length === 0

                        clip: true

                        contentWidth: width
                        contentHeight: sectionColumn.implicitHeight

                        boundsBehavior:
                            Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            policy:
                                ScrollBar.AsNeeded
                        }

                        ColumnLayout {
                            id: sectionColumn

                            width:
                                keybindsFlickable.width

                            spacing: 18

                            Repeater {
                                model:
                                    KeybindsService.sections

                                delegate: ColumnLayout {
                                    required property var modelData

                                    Layout.fillWidth: true

                                    spacing: 8

                                    // ── Category title ─────────────────

                                    RowLayout {
                                        Layout.fillWidth: true

                                        spacing: 8

                                        Text {
                                            text:
                                                modelData.title.toUpperCase()

                                            color:
                                                Colors.primary

                                            font.family:
                                                Fonts.font

                                            font.pixelSize: 14
                                            font.bold: true
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true

                                            Layout.preferredHeight: 1

                                            color:
                                                Colors.outlineVariant
                                        }
                                    }

                                    // ── Two-column bind grid ─────────────

                                    GridView {
                                        id: bindGrid

                                        Layout.fillWidth: true

                                        Layout.preferredHeight:
                                            Math.ceil(
                                                modelData.binds.length / 2
                                            ) * 84

                                        cellWidth:
                                            width / 2

                                        cellHeight: 84

                                        interactive: false
                                        clip: false

                                        model:
                                            modelData.binds

                                        delegate: Rectangle {
                                            required property var modelData

                                            width:
                                                bindGrid.cellWidth - 8

                                            height:
                                                bindGrid.cellHeight - 8

                                            radius: 9

                                            color:
                                                Colors.surfaceContainerHigh

                                            border.width: 1

                                            border.color:
                                                Colors.outlineVariant

                                            RowLayout {
                                                anchors {
                                                    fill: parent

                                                    leftMargin: 10
                                                    rightMargin: 10

                                                    topMargin: 9
                                                    bottomMargin: 9
                                                }

                                                spacing: 10

                                                Flow {
                                                    id: keyFlow

                                                    Layout.fillWidth: false

                                                    Layout.preferredWidth:
                                                        parent.width * 0.50

                                                    Layout.maximumWidth:
                                                        parent.width * 0.50

                                                    spacing: 4

                                                    property var keyParts:
                                                        modelData.keyParts

                                                    Repeater {
                                                        model: keyFlow.keyParts

                                                        delegate: Row {
                                                            required property string modelData
                                                            required property int index

                                                            spacing: 4

                                                            Rectangle {
                                                                width:
                                                                    keyText.implicitWidth + 16

                                                                height: 25

                                                                radius: 5

                                                                color: Colors.surface

                                                                border.width: 1
                                                                border.color: Colors.outline

                                                                Text {
                                                                    id: keyText

                                                                    anchors.centerIn: parent

                                                                    text: modelData

                                                                    color: Colors.primary

                                                                    font.family: Fonts.font
                                                                    font.pixelSize: 12
                                                                    font.bold: true

                                                                    horizontalAlignment:
                                                                        Text.AlignHCenter

                                                                    verticalAlignment:
                                                                        Text.AlignVCenter
                                                                }
                                                            }

                                                            Text {
                                                                visible:
                                                                    index < keyFlow.keyParts.length - 1

                                                                text: "+"

                                                                color: Colors.on_SurfaceVariant

                                                                font.family: Fonts.font
                                                                font.pixelSize: 11
                                                                font.bold: true

                                                                anchors.verticalCenter:
                                                                    parent.verticalCenter
                                                            }
                                                        }
                                                    }
                                                }

                                                Text {
                                                    Layout.fillWidth: true

                                                    text:
                                                        modelData.description

                                                    color:
                                                        Colors.on_Surface

                                                    font.family:
                                                        Fonts.font

                                                    font.pixelSize: 14

                                                    maximumLineCount: 2

                                                    wrapMode:
                                                        Text.Wrap

                                                    elide:
                                                        Text.ElideRight

                                                    verticalAlignment:
                                                        Text.AlignVCenter
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: Popups

        function onKeybindsOpenChanged() {
            if (Popups.keybindsOpen)
                KeybindsService.refresh()
        }
    }
}

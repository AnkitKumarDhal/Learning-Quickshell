import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services

PanelWindow {
    id: root

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: root.screen ? root.screen.height : 800

    WlrLayershell.layer: WlrLayer.Overlay

    visible: slidePanel.windowVisible

    mask: Region {
        x: (root.width - card.width) / 2
        y: Theme.barHeight + 8
        width: card.width
        height: card.height
    }

    PopupSlide {
        id: slidePanel

        anchors.fill: parent
        edge: "top"

        open: Popups.caffeineOpen
        onCloseRequested: Popups.caffeineOpen = false

        Rectangle {
            id: card

            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: Theme.barHeight + 8
            }

            width: 370
            height: cardColumn.implicitHeight + 28
            radius: Theme.popupRadius

            color: Colors.surfaceContainer

            border.color: Colors.outlineVariant
            border.width: Theme.popupBorder

            clip: true

            ColumnLayout {
                id: cardColumn

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 16
                }

                spacing: 14

                RowLayout {
                    Layout.fillWidth: true

                        Text {
                            Layout.alignment: Qt.AlignLeft
                            text: "Caffeine"

                            color: Colors.on_Surface

                            font.pixelSize: 15
                            font.bold: true
                            font.family: Fonts.font
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: {
                                if (CaffeineService.caffeineActive) {
                                    if (CaffeineService.infinite)
                                        return "Keeping the system awake indefinitely"

                                    return CaffeineService.remainingSeconds > 0
                                        ? CaffeineService.remainingSeconds + " seconds remaining"
                                        : "Finishing…"
                                }

                                return "Caffeine is off"
                            }

                            color: Colors.on_SurfaceVariant

                            font.pixelSize: 10
                            font.family: Fonts.font
                        }
                }

                Rectangle {
                    Layout.fillWidth: true

                    height: 1

                    color: Colors.outlineVariant
                    opacity: 0.5
                }

                Text {
                    text: "Duration"

                    color: Colors.on_SurfaceVariant

                    font.pixelSize: 11
                    font.bold: true
                    font.family: Fonts.font
                }

                GridLayout {
                    Layout.fillWidth: true

                    columns: 3

                    rowSpacing: 7
                    columnSpacing: 7

                    Repeater {
                        model: [
                            { index: 1, label: "2 min" },
                            { index: 2, label: "5 min" },
                            { index: 3, label: "10 min" },
                            { index: 4, label: "15 min" },
                            { index: 5, label: "30 min" },
                            { index: 6, label: "∞" }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            Layout.fillWidth: true
                            height: 34
                            radius: 9

                            readonly property bool selected: CaffeineService.caffeineActive && CaffeineService.presetIndex === modelData.index

                            color: selected
                                    ? Qt.rgba(
                                        Colors.primary.r,
                                        Colors.primary.g,
                                        Colors.primary.b,
                                        0.16
                                    )
                                    : optionHover.hovered
                                        ? Colors.surfaceContainerHighest
                                        : Colors.surfaceContainerHigh

                            border.color: selected
                                    ? Colors.primary
                                    : Colors.outlineVariant

                            border.width: selected ? 1.5 : 1

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label

                                color: selected
                                        ? Colors.primary
                                        : Colors.on_Surface

                                font.pixelSize: 10
                                font.bold: selected
                                font.family: Fonts.font
                            }

                            HoverHandler {
                                id: optionHover
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: CaffeineService.selectPreset(modelData.index)
                            }
                        }
                    }
                }

                Text {
                    visible: CaffeineService.externalInhibitorActive
                    text: "Another application is holding an inhibitor"

                    color: Colors.tertiary

                    font.pixelSize: 10
                    font.family: Fonts.fontM

                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.outlineVariant
                    opacity: 0.5
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "󰃠  Brightness"

                        color: Colors.on_SurfaceVariant

                        font.pixelSize: 11
                        font.bold: true
                        font.family: Fonts.fontM
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        visible: BrightnessService.available
                        text: BrightnessService.brightness + "%"

                        color: Colors.on_Surface

                        font.pixelSize: 11
                        font.bold: true
                        font.family: Fonts.font
                    }
                }

                Item {
                    id: brightnessSlider

                    Layout.fillWidth: true
                    height: 28
                    visible: BrightnessService.available

                    property int dragValue: BrightnessService.brightness
                    readonly property int visualValue: dragArea.pressed ? dragValue : BrightnessService.brightness

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        height: 6
                        radius: 3

                        color: Colors.surfaceContainerHighest
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        width: parent.width * brightnessSlider.visualValue / 100
                        height: 6
                        radius: 3

                        color: Colors.primary
                    }

                    Rectangle {
                        x: parent.width * brightnessSlider.visualValue / 100 - width / 2

                        anchors.verticalCenter: parent.verticalCenter

                        width: 16
                        height: 16
                        radius: 8

                        color: Colors.primary

                        Behavior on x {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        id: dragArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        function valueFromX(x) {
                            return Math.max(1, Math.min(100, Math.round((x / width) * 100)))
                        }

                        onPressed: (mouse) => {
                            brightnessSlider.dragValue = valueFromX(mouse.x)
                        }

                        onPositionChanged: (mouse) => {
                            if (!pressed) return
                            brightnessSlider.dragValue = valueFromX(mouse.x)
                        }

                        onReleased: { BrightnessService.setBrightness(brightnessSlider.dragValue) }
                    }
                }

                Text {
                    visible: !BrightnessService.available
                    text: "Brightness control is unavailable"

                    color: Colors.outline

                    font.pixelSize: 10
                    font.family: Fonts.font
                }
            }
        }
    }
}

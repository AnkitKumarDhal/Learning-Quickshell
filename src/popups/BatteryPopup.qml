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
    property var screen

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top:   true
        right: true
    }

    implicitWidth:  380
    implicitHeight: root.screen ? root.screen.height : 800

    WlrLayershell.layer: WlrLayer.Overlay
    visible: slidePanel.windowVisible

    mask: Region {
        x:      root.implicitWidth - card.width - Theme.barMargin
        y:      Theme.barHeight + 8
        width:  card.width
        height: card.height
    }

    PopupSlide {
        id: slidePanel
        anchors.fill: parent
        edge: "top"
        open: Popups.batteryOpen
        onCloseRequested: Popups.batteryOpen = false

        Rectangle {
            id: card
            anchors {
                top:         parent.top
                right:       parent.right
                topMargin:   Theme.barHeight + 8
                rightMargin: Theme.barMargin
            }

            width:        360
            height:       cardCol.implicitHeight + 20
            radius:       Theme.popupRadius
            color:        Colors.surfaceContainer
            border.color: Colors.outlineVariant
            border.width: Theme.popupBorder
            clip:         true

            // ── Applying overlay ──────────────────────────────────────────────────
            Rectangle {
                anchors.fill: parent
                radius:       parent.radius
                color:        Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.82)
                visible:      BatteryService.applying
                z:            10

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    // Basic unicode gear — safe across all fonts
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text:             "⚙"
                        font.pixelSize:   30
                        color:            Colors.primary

                        SequentialAnimation on opacity {
                            running: BatteryService.applying
                            loops:   Animation.Infinite
                            NumberAnimation { to: 0.2; duration: 500; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text:             "Applying mode…"
                        color:            Colors.on_Surface
                        font.pixelSize:   13
                        font.family:      Fonts.font
                    }
                }
            }

            ColumnLayout {
                id: cardCol
                anchors {
                    top:          parent.top
                    left:         parent.left
                    right:        parent.right
                    topMargin:    14
                    leftMargin:   16
                    rightMargin:  16
                }
                spacing: 12

                // ── Status header ─────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Text {
                        text:           BatteryService.getIcon() + BatteryService.capacity + "%"
                        color:          BatteryService.getColor()
                        font.pixelSize: 30
                        font.bold:      true
                        font.family:    Fonts.fontM

                        Behavior on color { ColorAnimation { duration: 300 } }

                        SequentialAnimation on opacity {
                            running: BatteryService.capacity <= 10 && !BatteryService.charging
                            loops:   Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 3
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: {
                                if (BatteryService.full)        return "Full"
                                if (BatteryService.notCharging) return "Capped at 80%"
                                if (BatteryService.charging)    return "Charging"
                                return "On battery"
                            }
                            color:          BatteryService.getColor()
                            font.pixelSize: 12
                            font.bold:      true
                            font.family:    Fonts.font
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        Text {
                            Layout.alignment: Qt.AlignRight
                            visible: BatteryService.formatTimeRemaining() !== ""
                            text: {
                                const t = BatteryService.formatTimeRemaining()
                                if (!t) return ""
                                return BatteryService.charging ? t + " to full" : t + " left"
                            }
                            color:          Colors.on_SurfaceVariant
                            font.pixelSize: 11
                            font.family:    Fonts.font
                        }
                    }
                }

                // ── Progress bar ──────────────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    height: 6

                    Rectangle {
                        anchors.fill: parent
                        radius:       3
                        color:        Colors.surfaceContainerHighest
                    }

                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width:  parent.width * BatteryService.fraction
                        radius: 3
                        color:  BatteryService.getColor()
                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation  { duration: 300 } }
                    }
                }

                // ── Divider ───────────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height:  1
                    color:   Colors.outlineVariant
                    opacity: 0.5
                }

                // ── Mode section header ───────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text:           "Power Mode"
                        color:          Colors.on_SurfaceVariant
                        font.pixelSize: 11
                        font.bold:      true
                        font.family:    Fonts.font
                        leftPadding:    2
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        visible: BatteryService.cpuProfile !== ""
                        width:   cpuLabel.implicitWidth + 12
                        height:  18
                        radius:  9
                        color:   Colors.surfaceContainerHigh

                        Text {
                            id: cpuLabel
                            anchors.centerIn: parent
                            text:           BatteryService.cpuProfile
                            color:          Colors.on_SurfaceVariant
                            font.pixelSize: 9
                            font.family:    Fonts.font
                        }
                    }
                }

                // ── Mode grid ─────────────────────────────────────────────────────
                GridLayout {
                    Layout.fillWidth: true
                    columns:          2
                    columnSpacing:    8
                    rowSpacing:       8

                    component ModeCard: Rectangle {
                        property string modeId:    ""
                        property string modeEmoji: ""
                        property string modeName:  ""
                        property string modeDesc:  ""

                        readonly property bool isActive: BatteryService.currentMode === modeId

                        Layout.fillWidth: true
                        height: 82
                        radius: 12

                        color: isActive
                                   ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.13)
                                   : cardHov.containsMouse
                                       ? Colors.surfaceContainerHighest
                                       : Colors.surfaceContainerHigh

                        border.color: isActive ? Colors.primary : Colors.outlineVariant
                        border.width: isActive ? 2 : 1

                        Behavior on color        { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on border.width { NumberAnimation { duration: 150 } }

                        ColumnLayout {
                            anchors { fill: parent; margins: 10 }
                            spacing: 2

                            Text {
                                text:           modeEmoji
                                font.pixelSize: 18
                            }

                            Text {
                                text:           modeName
                                color:          isActive ? Colors.primary : Colors.on_Surface
                                font.pixelSize: 12
                                font.bold:      true
                                font.family:    Fonts.fontM
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Text {
                                text:             modeDesc
                                color:            Colors.on_SurfaceVariant
                                font.pixelSize:   9
                                font.family:      Fonts.font
                                opacity:          0.85
                                wrapMode:         Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id:           cardHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  (BatteryService.applying || isActive)
                                              ? Qt.ArrowCursor : Qt.PointingHandCursor
                            enabled:      !BatteryService.applying && !isActive
                            onClicked:    BatteryService.applyMode(modeId)
                        }
                    }

                    ModeCard {
                        modeId:    "game"
                        modeEmoji: "🎮"
                        modeName:  "Game"
                        modeDesc:  "Performance · 80% cap · 120Hz"
                    }

                    ModeCard {
                        modeId:    "study"
                        modeEmoji: "📚"
                        modeName:  "Study"
                        modeDesc:  "Balanced · 80% cap · 120Hz"
                    }

                    ModeCard {
                        modeId:    "quickjuice"
                        modeEmoji: "⚡"
                        modeName:  "Quick Juice"
                        modeDesc:  "Power-saver · Rapid charge · 60Hz"
                    }

                    ModeCard {
                        modeId:    "eco"
                        modeEmoji: "🍃"
                        modeName:  "Eco"
                        modeDesc:  "Power-saver · 100% fill · 60Hz"
                    }
                }

                Item { height: 2 }
            }
        }
    }
}

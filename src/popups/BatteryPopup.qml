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
        right: true
    }

    implicitWidth: 380
    implicitHeight: root.screen ? root.screen.height : 800

    WlrLayershell.layer: WlrLayer.Overlay
    visible: slidePanel.windowVisible

    mask: Region {
        x: root.implicitWidth - card.width - Theme.barMargin
        y: Theme.barHeight + 8
        width: card.width
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
                top: parent.top
                right: parent.right
                topMargin: Theme.barHeight + 8
                rightMargin: Theme.barMargin
            }

            width: 360
            height: cardCol.implicitHeight + 20
            radius: Theme.popupRadius
            color: Colors.surfaceContainer
            border.color: Colors.outlineVariant
            border.width: Theme.popupBorder
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.82)
                visible: BatteryService.applying
                z: 10

                Text {
                    anchors.centerIn: parent
                    text: "Applying..."
                    color: Colors.on_Surface
                    font.pixelSize: 13
                    font.family: Fonts.font
                }
            }

            ColumnLayout {
                id: cardCol
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: 14
                    leftMargin: 16
                    rightMargin: 16
                }
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Text {
                        text: BatteryService.getIcon() + BatteryService.capacity + "%"
                        color: BatteryService.getColor()
                        font.pixelSize: 30
                        font.bold: true
                        font.family: Fonts.fontM

                        Behavior on color { ColorAnimation { duration: 300 } }

                        SequentialAnimation on opacity {
                            running: BatteryService.capacity <= 10 && !BatteryService.charging
                            loops: Animation.Infinite
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
                                if (BatteryService.full) return "Full"
                                if (BatteryService.notCharging) return "Not charging"
                                if (BatteryService.charging) return "Charging"
                                return "On battery"
                            }
                            color: BatteryService.getColor()
                            font.pixelSize: 12
                            font.bold: true
                            font.family: Fonts.font
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
                            color: Colors.on_SurfaceVariant
                            font.pixelSize: 11
                            font.family: Fonts.font
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    height: 6

                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        color: Colors.surfaceContainerHighest
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: parent.width * BatteryService.fraction
                        radius: 3
                        color: BatteryService.getColor()
                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.outlineVariant
                    opacity: 0.5
                }

                component SettingRow: ColumnLayout {
                    id: settingRow

                    property string label: ""
                    property var options: []
                    property string currentValue: ""
                    signal selected(string id)

                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: settingRow.label
                        color: Colors.on_SurfaceVariant
                        font.pixelSize: 11
                        font.bold: true
                        font.family: Fonts.font
                        leftPadding: 2
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: settingRow.options

                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool isActive: modelData.id === settingRow.currentValue

                                Layout.fillWidth: true
                                height: 30
                                radius: 8

                                color: isActive
                                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.16)
                                    : optHov.containsMouse
                                        ? Colors.surfaceContainerHighest
                                        : Colors.surfaceContainerHigh

                                border.color: isActive ? Colors.primary : Colors.outlineVariant
                                border.width: isActive ? 1.5 : 1

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: isActive ? Colors.primary : Colors.on_Surface
                                    font.pixelSize: 10
                                    font.bold: isActive
                                    font.family: Fonts.font
                                }

                                MouseArea {
                                    id: optHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: (BatteryService.applying || isActive)
                                        ? Qt.ArrowCursor
                                        : Qt.PointingHandCursor
                                    enabled: !BatteryService.applying && !isActive
                                    onClicked: settingRow.selected(modelData.id)
                                }
                            }
                        }
                    }
                }

                SettingRow {
                    label: "Performance"
                    visible: BatteryService.performanceAvailable
                    currentValue: BatteryService.cpuTier
                    options: BatteryService.performanceOptions.map(id => ({
                        id: id,
                        label: id === "power-saving"
                            ? "Power Saving"
                            : id === "balanced"
                                ? "Balanced"
                                : id === "performance"
                                    ? "Performance"
                                    : id
                    }))
                    onSelected: (id) => BatteryService.setCpuTier(id)
                }

                SettingRow {
                    label: "Charging"
                    visible: BatteryService.chargingAvailable
                    currentValue: BatteryService.chargeMode
                    options: BatteryService.chargingOptions.map(id => ({
                        id: id,
                        label: id === "conserve"
                            ? "Conserve"
                            : id === "full"
                                ? "Full"
                                : id
                    }))
                    onSelected: (id) => BatteryService.setChargeMode(id)
                }

                SettingRow {
                    label: "Display"
                    visible: BatteryService.displayAvailable
                    currentValue: String(BatteryService.refreshRate)
                    options: BatteryService.displayOptions.map(rate => {
                        const value = Math.round(Number(rate))
                        return {
                            id: String(value),
                            label: value + "Hz"
                        }
                    })
                    onSelected: (id) => BatteryService.setRefreshRate(Number(id))
                }

                Item { height: 2 }
            }
        }
    }
}

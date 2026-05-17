import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Networking
import qs.src.services
import qs.src.state
import qs.src.theme
import qs.src.components

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
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    visible: slide.windowVisible

    PopupSlide {
        id: slide
        anchors.fill: parent
        edge: "top"
        open: Popups.networkOpen
        onCloseRequested: Popups.networkOpen = false
    }

    Binding {
        target: NetworkService
        property: "scannerActive"
        value: Popups.networkOpen
    }

    // ── Popup card ────────────────────────────────────────────────────────────
    Rectangle {
        anchors {
            top:        parent.top
            right:      parent.right
            topMargin:  Theme.barHeight + 8
            rightMargin: Theme.barMargin
        }

        width:        360
        height:       mainCol.implicitHeight + 18
        radius:       Theme.popupRadius
        color:        Colors.surfaceContainer
        border.color: Colors.outlineVariant
        border.width: Theme.popupBorder
        clip:         true

        ColumnLayout {
            id: mainCol
            anchors {
                top:          parent.top
                left:         parent.left
                right:        parent.right
                topMargin:    10
                leftMargin:   16
                rightMargin:  16
                bottomMargin: 16
            }
            spacing: 12

            // ── Tab bar ──────────────────────────────────────────────────────
            TabBar {
                id: tabs
                Layout.fillWidth: true
                orientation: "horizontal"
                currentPage: ["wifi", "bluetooth", "hotspot"][Popups.networkTab]
                model: [
                    { key: "wifi",      icon: "󰤨", label: "Wi-Fi"    },
                    { key: "bluetooth", icon: "󰂯", label: "Bluetooth" },
                    { key: "hotspot",   icon: "󰀂", label: "Hotspot"   }
                ]
                onPageChanged: (key) => {
                    const idx = ["wifi", "bluetooth", "hotspot"].indexOf(key)
                    if (idx >= 0) Popups.networkTab = idx
                }
            }

            // ── WiFi tab ─────────────────────────────────────────────────────
            ColumnLayout {
                visible: Popups.networkTab === 0
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 4

                    Text {
                        text: "Wi-Fi"
                        color: Colors.on_SurfaceVariant
                        font.pixelSize: 11
                        font.bold: true
                        font.family: Fonts.font
                        leftPadding: 4
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 40; height: 22; radius: 11
                        color: NetworkService.wifiEnabled ? Colors.primary : Colors.surfaceContainerHighest
                        border.width: NetworkService.wifiEnabled ? 0 : 1
                        border.color: Colors.outlineVariant
                        opacity: (NetworkService.wifiHardwareEnabled ?? true) ? 1.0 : 0.4
                        
                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }

                        Rectangle {
                            width: 16; height: 16; radius: 8
                            color: NetworkService.wifiEnabled ? Colors.on_Primary : Colors.outline
                            anchors.verticalCenter: parent.verticalCenter
                            x: NetworkService.wifiEnabled ? 20 : 4
                            Behavior on x { NumberAnimation { duration: Theme.hoverFadeDuration; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: NetworkService.wifiHardwareEnabled ?? true
                            onClicked: NetworkService.setWifiEnabled(!NetworkService.wifiEnabled)
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(networkCol.implicitHeight, 280)
                    contentHeight: networkCol.implicitHeight
                    clip: true
                    visible: NetworkService.wifiEnabled
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: networkCol
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: NetworkService.networks

                            delegate: NetworkRow {
                                required property var modelData
                                Layout.fillWidth: true
                                network: modelData
                            }
                        }

                        Text {
                            visible: NetworkService.networks.length === 0
                            Layout.alignment: Qt.AlignHCenter
                            text: "Scanning…"
                            font.family: Fonts.font
                            font.pixelSize: 11
                            color: Colors.outline
                            topPadding: 8; bottomPadding: 8
                        }
                    }
                }

                Text {
                    visible: !NetworkService.wifiEnabled
                    Layout.alignment: Qt.AlignHCenter
                    text: "Wi-Fi is disabled"
                    font.family: Fonts.font
                    font.pixelSize: 11
                    color: Colors.outline
                    topPadding: 8; bottomPadding: 8
                }
            }

            // ── Bluetooth tab ─────────────────────────────────────────────────
            ColumnLayout {
                visible: Popups.networkTab === 1
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 4

                    Text {
                        text: "Bluetooth"
                        color: Colors.on_SurfaceVariant
                        font.pixelSize: 11
                        font.bold: true
                        font.family: Fonts.font
                        leftPadding: 4
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 40; height: 22; radius: 11
                        color: NetworkService.btEnabled ? Colors.primary : Colors.surfaceContainerHighest
                        border.width: NetworkService.btEnabled ? 0 : 1
                        border.color: Colors.outlineVariant
                        opacity: NetworkService.btAdapter ? 1.0 : 0.4
                        
                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }

                        Rectangle {
                            width: 16; height: 16; radius: 8
                            color: NetworkService.btEnabled ? Colors.on_Primary : Colors.outline
                            anchors.verticalCenter: parent.verticalCenter
                            x: NetworkService.btEnabled ? 20 : 4
                            Behavior on x { NumberAnimation { duration: Theme.hoverFadeDuration; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: NetworkService.btAdapter !== null
                            onClicked: NetworkService.setBtEnabled(!NetworkService.btEnabled)
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: NetworkService.btEnabled

                    Repeater {
                        model: NetworkService.btDevices

                        delegate: Item {
                            required property var modelData

                            Layout.fillWidth: true
                            implicitHeight: 44

                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: btHov.containsMouse ? Colors.surfaceContainerHighest : Qt.rgba(Colors.primaryContainer.r, Colors.primaryContainer.g, Colors.primaryContainer.b, 0.3)
                                Behavior on color { ColorAnimation { duration: 120 } }

                                MouseArea {
                                    id: btHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: modelData.connected = false
                                }
                            }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 10

                                Text {
                                    text: {
                                        const ic = modelData.icon ?? "";
                                        if (ic.includes("headphone") || ic.includes("headset")) return "󰋋";
                                        if (ic.includes("phone"))    return "󰄜";
                                        if (ic.includes("keyboard")) return "󰌌";
                                        if (ic.includes("mouse"))    return "󰍽";
                                        if (ic.includes("speaker"))  return "󰓃";
                                        if (ic.includes("computer")) return "󰇄";
                                        return "󰂯";
                                    }
                                    font.family: Fonts.fontM
                                    font.pixelSize: 16
                                    color: Colors.primary
                                }

                                Text {
                                    text: modelData.name
                                    font.family: Fonts.font
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Colors.on_Surface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    visible: modelData.hasBattery
                                    text: Math.round((modelData.battery ?? 0) * 100) + "%"
                                    font.family: Fonts.font
                                    font.pixelSize: 10
                                    color: Colors.outline
                                }

                                // Connected chip (mirrors DeviceRow's "Default" chip)
                                Rectangle {
                                    width: btChip.implicitWidth + 16
                                    height: 22
                                    radius: 11
                                    color: Colors.primary

                                    Row {
                                        id: btChip
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text {
                                            text: "󰄵"
                                            color: Colors.on_Primary
                                            font.pixelSize: 10
                                            font.family: Fonts.font
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: "Connected"
                                            color: Colors.on_Primary
                                            font.pixelSize: 10
                                            font.bold: true
                                            font.family: Fonts.font
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: (NetworkService.btDevices?.length ?? 0) === 0
                        Layout.alignment: Qt.AlignHCenter
                        text: "No devices connected"
                        font.family: Fonts.font
                        font.pixelSize: 11
                        color: Colors.outline
                        topPadding: 8; bottomPadding: 8
                    }
                }

                Text {
                    visible: !NetworkService.btEnabled
                    Layout.alignment: Qt.AlignHCenter
                    text: NetworkService.btAdapter ? "Bluetooth is disabled" : "No Bluetooth adapter found"
                    font.family: Fonts.font
                    font.pixelSize: 11
                    color: Colors.outline
                    topPadding: 8; bottomPadding: 8
                }
            }

            // ── Hotspot tab ───────────────────────────────────────────────────
            ColumnLayout {
                visible: Popups.networkTab === 2
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "󰀂"
                    font.family: Fonts.fontM
                    font.pixelSize: 32
                    color: Colors.outline
                    topPadding: 12
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Hotspot coming soon"
                    font.family: Fonts.font
                    font.pixelSize: 11
                    color: Colors.outline
                    bottomPadding: 12
                }
            }
        }
    }
}

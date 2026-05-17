// src/popups/NetworkPopup.qml
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

    implicitWidth:  340
    implicitHeight: root.screen ? root.screen.height : 800

    WlrLayershell.layer: WlrLayer.Overlay
    visible: slide.windowVisible

    PopupSlide {
        id: slide
        anchors.fill: parent
        edge: "top"
        open: Popups.networkOpen
        onCloseRequested: Popups.networkOpen = false
    }

    // ── Popup card ────────────────────────────────────────────────────────────
    Rectangle {
        anchors {
            top:        parent.top
            right:      parent.right
            topMargin:  Theme.barHeight + 8
            rightMargin: Theme.barMargin
        }

        width:        320
        height:       mainCol.implicitHeight + 24
        radius:       Theme.popupRadius
        color:        Colors.surfaceContainer
        border.color: Colors.outlineVariant
        border.width: Theme.popupBorder
        clip:         true

        ColumnLayout {
            id: mainCol
            anchors {
                top:   parent.top
                left:  parent.left
                right: parent.right
                margins: 12
            }
            spacing: 8

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
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Wi-Fi"
                        font.family: Fonts.font
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Colors.on_Surface
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 40; height: 22; radius: 11
                        color: NetworkService.wifiEnabled
                            ? Colors.primary
                            : Colors.surfaceVariant
                        opacity: (NetworkService.wifiHardwareEnabled ?? true) ? 1.0 : 0.4
                        enabled: NetworkService.wifiHardwareEnabled ?? true

                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }

                        Rectangle {
                            width: 16; height: 16; radius: 8
                            color: Colors.on_Primary
                            anchors.verticalCenter: parent.verticalCenter
                            x: NetworkService.wifiEnabled ? 20 : 4
                            Behavior on x { NumberAnimation { duration: Theme.hoverFadeDuration; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: NetworkService.wifiHardwareEnabled
                            onClicked: NetworkService.setWifiEnabled(!NetworkService.wifiEnabled)
                        }
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    height: Math.min(networkCol.implicitHeight, 240)
                    contentHeight: networkCol.implicitHeight
                    clip: true
                    visible: NetworkService.wifiEnabled

                    ColumnLayout {
                        id: networkCol
                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: NetworkService.networks

                            delegate: NetworkRow {
                                required property var modelData
                                required property int index

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
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Bluetooth"
                        font.family: Fonts.font
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Colors.on_Surface
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 40; height: 22; radius: 11
                        color: NetworkService.btEnabled
                            ? Colors.primary
                            : Colors.surfaceVariant
                        opacity: NetworkService.btAdapter ? 1.0 : 0.4

                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }

                        Rectangle {
                            width: 16; height: 16; radius: 8
                            color: Colors.on_Primary
                            anchors.verticalCenter: parent.verticalCenter
                            x: NetworkService.btEnabled ? 20 : 4
                            Behavior on x { NumberAnimation { duration: Theme.hoverFadeDuration; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: NetworkService.btAdapter !== null
                            onClicked: NetworkService.setBtEnabled(!NetworkService.btEnabled)
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: NetworkService.btEnabled

                    Repeater {
                        model: NetworkService.btDevices

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            height: 36
                            radius: 8
                            color: "transparent"

                            RowLayout {
                                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                spacing: 8

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
                                    font.pixelSize: 14
                                    color: Colors.onSurface
                                }

                                Text {
                                    text: modelData.name
                                    font.family: Fonts.font
                                    font.pixelSize: 11
                                    color: Colors.onSurface
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

                                Rectangle {
                                    width: 56; height: 22; radius: 11
                                    color: disconnectHover.containsMouse
                                        ? Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.15)
                                        : "transparent"
                                    border.width: 1
                                    border.color: Colors.error

                                    Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Disconnect"
                                        font.family: Fonts.font
                                        font.pixelSize: 9
                                        color: Colors.error
                                    }

                                    HoverHandler { id: disconnectHover }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: modelData.connected = false
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

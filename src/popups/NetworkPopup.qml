import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland

import qs.src.services
import qs.src.state
import qs.src.theme
import qs.src.components
import qs.src.popups.network

PanelWindow {
    id: root

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        right: true
    }

    implicitWidth: 400
    implicitHeight: root.screen ? root.screen.height : 800

    WlrLayershell.layer: WlrLayer.Overlay

    visible: slide.windowVisible

    property var selectedNetwork: null

    onVisibleChanged: {
        if (!visible)
            root.selectedNetwork = null;
    }

    Connections {
        target: root.selectedNetwork
        function onConnectedChanged() {
            if (root.selectedNetwork?.connected)
                root.selectedNetwork = null;
        }
    }

    Binding {
        target: NetworkService
        property: "scannerActive"
        value: Popups.networkOpen
    }

    mask:
        Region {
            x: root.implicitWidth - connectivityCard.width - Theme.barMargin
            y: Theme.barHeight + 8
            width: connectivityCard.width
            height: connectivityCard.height
        }

    PopupSlide {
        id: slide

        anchors.fill: parent
        edge: "top"
        open: Popups.networkOpen
        onCloseRequested: Popups.networkOpen = false

        Rectangle {
            id: connectivityCard

            anchors {
                top: parent.top
                right: parent.right
                topMargin: Theme.barHeight + 8
                rightMargin: Theme.barMargin
            }

            width: 380
            height: mainColumn.implicitHeight + 24
            radius: Theme.popupRadius

            color: Colors.surfaceContainer

            border.width: Theme.popupBorder
            border.color: Colors.outlineVariant

            clip: true

            ColumnLayout {
                id: mainColumn

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: 14
                    leftMargin: 14
                    rightMargin: 14
                    bottomMargin: 14
                }

                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Connectivity"

                        font.family: Fonts.font
                        font.pixelSize: 16
                        font.bold: true

                        color: Colors.on_Surface

                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14

                        color: closeHover.hovered ? Colors.surfaceContainerHighest : "transparent"

                        HoverHandler {
                            id: closeHover
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"

                            font.family: Fonts.fontM
                            font.pixelSize: 15

                            color: Colors.outline
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Popups.networkOpen = false
                        }
                    }
                }

                ConnectivityStatusCards {
                    Layout.fillWidth: true
                }

                TabBar {
                    Layout.fillWidth: true
                    orientation: "horizontal"

                    currentPage: [ "wifi", "bluetooth", "hotspot" ][Popups.networkTab]

                    model: [
                        {
                            key: "wifi",
                            icon: "󰤨",
                            label: "Wi-Fi"
                        },
                        {
                            key: "bluetooth",
                            icon: "󰂯",
                            label: "Bluetooth"
                        },
                        {
                            key: "hotspot",
                            icon: "󰀂",
                            label: "Hotspot"
                        }
                    ]

                    onPageChanged: (key) => {
                            const index = [ "wifi", "bluetooth", "hotspot" ].indexOf(key);

                            if (index >= 0)
                                Popups.networkTab = index;
                        }
                }

                WifiTab {
                    visible: Popups.networkTab === 0
                    selectedNetwork: root.selectedNetwork

                    onNetworkSelected: (network) => {
                            root.selectedNetwork = network;
                        }
                }

                BluetoothTab { visible: Popups.networkTab === 1 }
                HotspotTab { visible: Popups.networkTab === 2 }
            }
        }
    }
}

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

    required property var screen

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        right: true
        left: true
    }

    implicitWidth: 400
    implicitHeight: root.screen ? root.screen.height : 800
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    visible: slide.windowVisible

    property var selectedNetwork: null
    readonly property bool hasWifi: NetworkService.wifiDevice !== null
    readonly property bool hasBluetooth: NetworkService.bluetooth.available

    readonly property var tabModel: {
        const tabs = [];

        if (root.hasWifi) {
            tabs.push({
                key: "wifi",
                icon: "󰤨",
                label: "Wi-Fi"
            });
        }

        if (root.hasBluetooth) {
            tabs.push({
                key: "bluetooth",
                icon: "󰂯",
                label: "Bluetooth"
            });
        }

        return tabs;
    }

    readonly property string currentTabKey: {
        if (Popups.networkTab === 0 && root.hasWifi) return "wifi";
        if (Popups.networkTab === 1 && root.hasBluetooth) return "bluetooth";
        if (root.hasWifi) return "wifi";
        if (root.hasBluetooth) return "bluetooth";
        return "";
    }

    property int tabDirection: 1

    function ensureValidTab() {
        if (root.hasWifi && root.hasBluetooth) {
            if (Popups.networkTab !== 0 && Popups.networkTab !== 1) Popups.networkTab = 0;
            return;
        }
        if (root.hasWifi) {
            if (Popups.networkTab !== 0) Popups.networkTab = 0;
            return;
        }
        if (root.hasBluetooth) {
            if (Popups.networkTab !== 1) Popups.networkTab = 1;
            return;
        }
        Popups.networkTab = 0;
    }

    onVisibleChanged: {
        if (!visible) root.selectedNetwork = null;
    }

    onHasWifiChanged: root.ensureValidTab()
    onHasBluetoothChanged: root.ensureValidTab()

    Component.onCompleted: root.ensureValidTab()

    Connections {
        target: Popups
        function onNetworkOpenChanged() {
            if (Popups.networkOpen) root.ensureValidTab();
        }
    }

    Connections {
        target: root.selectedNetwork
        function onConnectedChanged() {
            if (root.selectedNetwork?.connected) root.selectedNetwork = null;
        }
    }

    Binding {
        target: NetworkService
        property: "scannerActive"
        value: Popups.networkOpen
    }

    mask:
        Region {
            x: connectivityCard.x
            y: Theme.barHeight + 8
            width: connectivityCard.width
            height: connectivityCard.height
        }

    PopupSlide {
        id: slide

        anchors.fill: parent
        edge: "top"
        open: Popups.networkOpen && Popups.networkScreen === root.screen
        onCloseRequested: Popups.networkOpen = false

        Rectangle {
            id: connectivityCard

            anchors {
                top: parent.top
                topMargin: Theme.barHeight + 8
            }
            x: Popups.networkAnchorX - width / 2

            width: 380
            height: mainColumn.implicitHeight + 32
            radius: Theme.popupRadius
            color: Colors.surfaceContainer
            border.width: Theme.popupBorder
            border.color: Colors.outlineVariant
            clip: true

            Behavior on height {
                NumberAnimation {
                    duration: Theme.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                id: mainColumn

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: 16
                    leftMargin: 16
                    rightMargin: 16
                    bottomMargin: 16
                }

                spacing: 10

                ConnectivityStatusCards {
                    Layout.fillWidth: true
                    activeTab: root.currentTabKey
                    onWifiClicked: {
                        if (!root.hasWifi) return;
                        root.tabDirection = root.currentTabKey === "bluetooth" ? -1 : 1;
                        Popups.networkTab = 0;
                    }
                    onBluetoothClicked: {
                        if (!root.hasBluetooth) return;
                        root.tabDirection = root.currentTabKey === "wifi" ? 1 : -1;
                        Popups.networkTab = 1;
                    }
                }

                Item {
                    id: tabContent
                    Layout.fillWidth: true

                    implicitHeight: {
                        if (root.currentTabKey === "wifi") return wifiTab.implicitHeight;
                        if (root.currentTabKey === "bluetooth") return bluetoothTab.implicitHeight;
                        return 0;
                    }

                    clip: true

                    ColumnLayout {
                        id: wifiTab

                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }

                        spacing: 0
                        opacity: root.currentTabKey === "wifi" ? 1 : 0
                        enabled: root.currentTabKey === "wifi"

                        transform: Translate {
                            x: root.currentTabKey === "wifi" ? 0 : (root.tabDirection > 0 ? -32 : 32)
                            Behavior on x {
                                NumberAnimation {
                                    duration: Theme.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.animDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        WifiTab {
                            Layout.fillWidth: true
                            selectedNetwork: root.selectedNetwork
                            onNetworkSelected: (network) => {
                                root.selectedNetwork = network;
                            }
                        }
                    }

                    ColumnLayout {
                        id: bluetoothTab

                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }

                        spacing: 0
                        opacity: root.currentTabKey === "bluetooth" ? 1 : 0
                        enabled: root.currentTabKey === "bluetooth"

                        transform: Translate {
                            x: root.currentTabKey === "bluetooth" ? 0 : (root.tabDirection > 0 ? 32 : -32)
                            Behavior on x {
                                NumberAnimation {
                                    duration: Theme.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.animDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        BluetoothTab { Layout.fillWidth: true }
                    }
                }
            }
        }
    }
}

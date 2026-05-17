// src/services/NetworkService.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth

Singleton {
    id: root

    // ── WiFi ─────────────────────────────────────────────────────────────────

    /// The first WiFi device found, or null
    readonly property var wifiDevice: {
        const devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wifi) return devs[i];
        }
        return null;
    }

    /// The currently connected WifiNetwork, or null
    readonly property var activeNetwork: {
        if (!root.wifiDevice) return null;
        const nets = root.wifiDevice.networks.values;
        for (let i = 0; i < nets.length; i++) {
            if (nets[i].connected) return nets[i];
        }
        return null;
    }

    readonly property string ssid:          root.activeNetwork?.name         ?? ""
    readonly property real   signalStrength: root.activeNetwork?.signalStrength ?? 0.0
    readonly property bool   wifiConnected:  root.wifiDevice?.connected       ?? false
    readonly property bool   wifiEnabled:    Networking.wifiEnabled

    function setWifiEnabled(val) {
        Networking.wifiEnabled = val;
    }

    /// Sorted list of all visible networks (connected first, then by signal strength)
    readonly property var networks: {
        if (!root.wifiDevice) return [];
        const nets = root.wifiDevice.networks.values.slice();
        nets.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            return b.signalStrength - a.signalStrength;
        });
        return nets;
    }

    // Enable scanner whenever the popup is open — caller sets this
    property bool scannerActive: false
    onScannerActiveChanged: {
        if (root.wifiDevice) root.wifiDevice.scannerEnabled = root.scannerActive;
    }
    onWifiDeviceChanged: {
        if (root.wifiDevice) root.wifiDevice.scannerEnabled = root.scannerActive;
    }

    // ── Bluetooth ─────────────────────────────────────────────────────────────

    readonly property var btAdapter:       Bluetooth.defaultAdapter
    readonly property bool btEnabled:      root.btAdapter?.enabled      ?? false
    readonly property var btDevices:       Bluetooth.connectedDevices?.values ?? []

    function setBtEnabled(val) {
        if (root.btAdapter) root.btAdapter.enabled = val;
    }
}

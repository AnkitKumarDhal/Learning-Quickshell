pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    // ── Wi-Fi ────────────────────────────────────────────────────────────────

    readonly property bool wifiHardwareEnabled:
        Networking.wifiHardwareEnabled

    readonly property var wifiDevice: {
        const devices = Networking.devices.values;

        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi)
                return devices[i];
        }

        return null;
    }

    readonly property var activeNetwork: {
        if (!root.wifiDevice)
            return null;

        const networks = root.wifiDevice.networks.values;

        for (let i = 0; i < networks.length; i++) {
            if (networks[i].connected)
                return networks[i];
        }

        return null;
    }

    readonly property string ssid:
        root.activeNetwork?.name ?? ""

    readonly property real signalStrength:
        root.activeNetwork?.signalStrength ?? 0

    readonly property bool wifiConnected:
        root.wifiDevice?.connected ?? false

    readonly property bool wifiEnabled:
        Networking.wifiEnabled

    function setWifiEnabled(value) {
        Networking.wifiEnabled = value;
    }

    // ── Wi-Fi scanning ───────────────────────────────────────────────────────

    property bool scannerActive: false
    readonly property bool wifiScanning: root.wifiDevice?.scannerEnabled ?? false

    function _updateScanner() {
        if (root.wifiDevice)
            root.wifiDevice.scannerEnabled = root.scannerActive && !HotspotService.active;
    }

    Connections {
        target:
            HotspotService

        function onActiveChanged() {
            root._updateScanner();
        }
    }

    function scanWifi() {
        if (!root.wifiDevice || !root.wifiEnabled) {
            return;
        }

        root.wifiDevice.scannerEnabled = false;

        Qt.callLater(function() {
            if (root.wifiDevice && root.scannerActive && root.wifiEnabled) {
                root.wifiDevice.scannerEnabled = true;
            }
        })
    }

    onScannerActiveChanged: root._updateScanner()
    onWifiDeviceChanged: root._updateScanner()

    // ── Bluetooth ────────────────────────────────────────────────────────────

    readonly property var bluetooth:
        BluetoothService

    // ── Convenience status ──────────────────────────────────────────────────

    readonly property bool hasWifi:
        root.wifiDevice !== null

    readonly property bool hasBluetooth:
        root.bluetooth.available

    readonly property bool connectivityAvailable:
        root.hasWifi ||
        root.hasBluetooth
}

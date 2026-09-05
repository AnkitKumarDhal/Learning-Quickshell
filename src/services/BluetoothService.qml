pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: root.adapter !== null
    readonly property var state: root.adapter?.state
    readonly property bool enabled: root.state === BluetoothAdapterState.Enabled
    readonly property bool enabling: root.state === BluetoothAdapterState.Enabling
    readonly property bool disabling: root.state === BluetoothAdapterState.Disabling
    readonly property bool blocked: root.state === BluetoothAdapterState.Blocked
    readonly property bool discovering: root.adapter?.discovering ?? false
    readonly property bool scanning: root.discovering

    readonly property var devices: root.adapter ? root.adapter.devices.values : []
    readonly property var connectedDevices: root.devices.filter(device => device.connected)
    readonly property var pairedDevices: root.devices.filter(device => device.paired && !device.connected)
    readonly property var availableDevices: root.devices.filter(device => !device.paired && !device.connected)
    readonly property int connectedDeviceCount: root.connectedDevices.length
    readonly property bool operational: root.enabled || root.connectedDeviceCount > 0

    readonly property string stateText: {
        if (!root.available) return "Unavailable";
        if (root.enabling) return "Enabling";
        if (root.disabling) return "Disabling";
        if (root.blocked) return "Blocked";
        if (root.connectedDeviceCount > 0) return root.connectedDeviceCount + " conn.";
        if (root.state === BluetoothAdapterState.Disabled) return "Disabled";
        if (root.state === BluetoothAdapterState.Enabled) return "Ready";
        return "Unavailable";
    }

    function isPairing(address) {
        const device = root.devices.find(item => item.address === address);
        return device?.pairing ?? false;
    }

    function isConnecting(address) {
        const device = root.devices.find(item => item.address === address);
        return device?.state === BluetoothDeviceState.Connecting;
    }

    function scan() {
        if (!root.adapter || !root.enabled) return;
        root.adapter.discovering = true;
    }

    function stopScan() {
        if (!root.adapter) return;
        root.adapter.discovering = false;
    }

    function pair(address) {
        const device = root.devices.find(item => item.address === address);
        if (!device || !root.enabled || root.isPairing(address)) return;
        device.pair();
    }

    function cancelPair(address) {
        const device = root.devices.find(item => item.address === address);
        if (!device || !device.pairing) return;
        device.cancelPair();
    }

    function connect(address) {
        const device = root.devices.find(item => item.address === address);
        if (!device || !root.enabled || root.isConnecting(address)) return;
        device.connect();
    }

    function disconnect(address) {
        const device = root.devices.find(item => item.address === address);
        if (!device) return;
        device.disconnect();
    }

    function remove(address) {
        const device = root.devices.find(item => item.address === address);
        if (!device) return;
        device.forget();
    }

    function setEnabled(value) {
        if (!root.adapter) return;
        root.adapter.enabled = value;
    }
}

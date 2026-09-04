pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: root.adapter !== null
    readonly property bool enabled: root.adapter?.enabled ?? false
    readonly property bool discovering: root.adapter?.discovering ?? false
    readonly property bool scanning: root.discovering

    readonly property var devices: root.adapter ? root.adapter.devices.values : []
    readonly property var connectedDevices: root.devices.filter(device => device.connected)
    readonly property var pairedDevices: root.devices.filter(device => device.paired && !device.connected)
    readonly property var availableDevices: root.devices.filter(device => !device.paired && !device.connected)
    readonly property int connectedDeviceCount: root.connectedDevices.length

    property var pairingDevices: ({})
    property var connectingDevices: ({})
    readonly property int operationTimeout: 30000

    function isPairing(address) {
        return root.pairingDevices[address] !== undefined;
    }

    function isConnecting(address) {
        return root.connectingDevices[address] !== undefined;
    }

    function _clearPairing(address) {
        if (!root.isPairing(address)) return;
        delete root.pairingDevices[address];
        root.pairingDevicesChanged();
    }

    function _clearConnecting(address) {
        if (!root.isConnecting(address)) return;
        delete root.connectingDevices[address];
        root.connectingDevicesChanged();
    }

    function _updateOperationStates() {
        const now = Date.now();
        Object.keys(root.pairingDevices).forEach(address => {
            const device = root.devices.find(item => item.address === address);
            if (!device || device.paired || now - root.pairingDevices[address] >= root.operationTimeout) {
                root._clearPairing(address);
            }
        });

        Object.keys(root.connectingDevices).forEach(address => {
            const device = root.devices.find(item => item.address === address);
            if (!device || device.connected || now - root.connectingDevices[address] >= root.operationTimeout) {
                root._clearConnecting(address);
            }
        });
    }

    Timer {
        interval: 250
        repeat: true
        running: Object.keys(root.pairingDevices).length > 0 || Object.keys(root.connectingDevices).length > 0
        onTriggered: root._updateOperationStates()
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
        root.pairingDevices[address] = Date.now();
        root.pairingDevicesChanged();
        device.pair();
    }

    function connect(address) {
        const device = root.devices.find(item => item.address === address);
        if (!device || !root.enabled || root.isConnecting(address)) return;
        root.connectingDevices[address] = Date.now();
        root.connectingDevicesChanged();
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
        if (!value) {
            root.pairingDevices = ({});
            root.connectingDevices = ({});
            root.pairingDevicesChanged();
            root.connectingDevicesChanged();
        }
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

Singleton {
    id: root

    // ── Adapter state ────────────────────────────────────────────────────────

    readonly property var adapter:
        Bluetooth.defaultAdapter

    readonly property bool available:
        root.adapter !== null

    readonly property bool enabled:
        root.adapter?.enabled ?? false

    readonly property bool discovering:
        root.adapter?.discovering ?? false

    readonly property bool scanning:
        root.adapter?.discovering ?? scanProcess.running

    // ── Device model ─────────────────────────────────────────────────────────
    //
    // Each entry looks like:
    //
    // {
    //     address: "AA:BB:CC:DD:EE:FF",
    //     name: "Device",
    //     alias: "Device",
    //     icon: "audio-headphones",
    //     paired: true,
    //     connected: true,
    //     trusted: false,
    //     batteryAvailable: true,
    //     battery: 0.82
    // }

    property var devices: []

    readonly property var connectedDevices:
        root.devices.filter(device => device.connected)

    readonly property var pairedDevices:
        root.devices.filter(device => device.paired && !device.connected)

    readonly property var availableDevices:
        root.devices.filter(device => !device.paired && !device.connected)

    readonly property int connectedDeviceCount:
        root.connectedDevices.length

    // ── Refresh timer ────────────────────────────────────────────────────────

    Timer {
        id: refreshTimer

        interval: 5000
        repeat: true
        running: root.enabled && !scanProcess.running

        onTriggered: root.refresh()
    }

    // ── Inventory refresh ────────────────────────────────────────────────────

    Process {
        id: inventoryProcess

        stdout: StdioCollector {
            onStreamFinished: root._applyInventory(this.text)
        }

        stderr: StdioCollector {}
    }

    function refresh() {
        if (!root.available || !root.enabled) {
            root.devices = [];
            return;
        }

        inventoryProcess.exec({
            command: [
                "bash",
                "-lc",
                [
                    "export LC_ALL=C",

                    "bluetoothctl devices",

                    "echo '__PAIRED__'",
                    "bluetoothctl devices Paired",

                    "echo '__CONNECTED__'",
                    "bluetoothctl devices Connected",

                    "for addr in $(bluetoothctl devices Connected | awk '{print $2}'); do",
                    "    echo \"__INFO__ $addr\"",
                    "    bluetoothctl info \"$addr\"",
                    "done"
                ].join("\n")
            ]
        });
    }

    function _parseDeviceLine(line, destination) {
        const match = line.match(
            /^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/
        );

        if (!match)
            return false;

        const address = match[1].toUpperCase();
        const name = match[2].trim();

        if (!destination[address]) {
            destination[address] = {
                address: address,
                name: name,
                alias: name,
                icon: "",
                paired: false,
                connected: false,
                trusted: false,
                batteryAvailable: false,
                battery: 0
            };
        } else if (name.length > 0) {
            destination[address].name = name;
            destination[address].alias = name;
        }

        return true;
    }

    function _applyInventory(output) {
        const lines = output.split(/\r?\n/);

        const records = {};
        const paired = {};
        const connected = {};

        let section = "all";
        let infoAddress = "";

        for (const rawLine of lines) {
            const line = rawLine.trim();

            if (!line)
                continue;

            if (line === "__PAIRED__") {
                section = "paired";
                continue;
            }

            if (line === "__CONNECTED__") {
                section = "connected";
                continue;
            }

            if (line.startsWith("__INFO__ ")) {
                infoAddress = line.substring("__INFO__ ".length).trim().toUpperCase();
                section = "info";

                if (!records[infoAddress]) {
                    records[infoAddress] = {
                        address: infoAddress,
                        name: infoAddress,
                        alias: infoAddress,
                        icon: "",
                        paired: false,
                        connected: false,
                        trusted: false,
                        batteryAvailable: false,
                        battery: 0
                    };
                }

                continue;
            }

            if (section === "all") {
                root._parseDeviceLine(line, records);
                continue;
            }

            if (section === "paired") {
                root._parseDeviceLine(line, paired);
                continue;
            }

            if (section === "connected") {
                root._parseDeviceLine(line, connected);
                continue;
            }

            if (section === "info" && infoAddress !== "") {
                const current = records[infoAddress];

                if (line.startsWith("Name:")) {
                    current.name =
                        line.substring("Name:".length).trim();
                    current.alias = current.name;
                } else if (line.startsWith("Alias:")) {
                    current.alias =
                        line.substring("Alias:".length).trim();
                } else if (line.startsWith("Icon:")) {
                    current.icon =
                        line.substring("Icon:".length).trim();
                } else if (line.startsWith("Paired:")) {
                    current.paired =
                        line.substring("Paired:".length).trim() === "yes";
                } else if (line.startsWith("Connected:")) {
                    current.connected =
                        line.substring("Connected:".length).trim() === "yes";
                } else if (line.startsWith("Trusted:")) {
                    current.trusted =
                        line.substring("Trusted:".length).trim() === "yes";
                } else if (line.startsWith("Battery Percentage:")) {
                    const batteryMatch =
                        line.match(/\((\d+)\)/);

                    if (batteryMatch) {
                        current.batteryAvailable = true;
                        current.battery =
                            Math.max(
                                0,
                                Math.min(
                                    1,
                                    Number(batteryMatch[1]) / 100
                                )
                            );
                    }
                }
            }
        }

        for (const address in paired) {
            if (!records[address])
                records[address] = paired[address];

            records[address].paired = true;
        }

        for (const address in connected) {
            if (!records[address])
                records[address] = connected[address];

            records[address].connected = true;
        }

        const result = Object.values(records);

        result.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;

            if (a.paired !== b.paired)
                return a.paired ? -1 : 1;

            return a.name.localeCompare(
                b.name,
                undefined,
                { sensitivity: "base" }
            );
        });

        root.devices = result;
    }

    // ── Scanning ─────────────────────────────────────────────────────────────

    Process {
        id: scanProcess

        stdout: StdioCollector {
            onStreamFinished: root.refresh()
        }

        stderr: StdioCollector {}

        onExited: {
            if (!running)
                root.refresh();
        }
    }

    function scan() {
        if (!root.available || !root.enabled)
            return;

        if (scanProcess.running)
            return;

        scanProcess.exec({
            command: [
                "bluetoothctl",
                "--timeout",
                "8",
                "scan",
                "on"
            ]
        });
    }

    function stopScan() {
        if (!scanProcess.running)
            return;

        scanProcess.running = false;
    }

    // ── Device actions ───────────────────────────────────────────────────────

    property string busyAddress: ""
    property string busyAction: ""

    Process {
        id: actionProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.busyAddress = "";
                root.busyAction = "";
                root.refresh();
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.busyAddress = "";
                root.busyAction = "";
                root.refresh();
            }
        }
    }

    function _runAction(action, address, timeout = 20) {
        if (!address || !root.enabled)
            return;

        if (actionProcess.running)
            return;

        root.busyAddress = address;
        root.busyAction = action;

        actionProcess.exec({
            command: [
                "bluetoothctl",
                "--timeout",
                String(timeout),
                action,
                address
            ]
        });
    }

    function pair(address) {
        root._runAction("pair", address, 30);
    }

    function connect(address) {
        root._runAction("connect", address, 20);
    }

    function disconnect(address) {
        root._runAction("disconnect", address, 20);
    }

    function remove(address) {
        root._runAction("remove", address, 20);
    }

    // ── Power ────────────────────────────────────────────────────────────────

    function setEnabled(value) {
        if (!root.adapter)
            return;

        root.adapter.enabled = value;

        if (!value) {
            root.stopScan();
            root.devices = [];
        } else {
            Qt.callLater(root.refresh);
        }
    }

    Connections {
        target: root.adapter

        function onEnabledChanged() {
            if (root.enabled)
                root.refresh();
            else
                root.devices = [];
        }
    }

    Component.onCompleted: {
        if (root.enabled)
            root.refresh();
    }
}

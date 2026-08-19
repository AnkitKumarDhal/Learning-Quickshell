pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── Configuration ────────────────────────────────────────────────────────

    readonly property string connectionName:
        "Quickshell Hotspot"

    property string ssid:
        "Quickshell Hotspot"

    property string password:
        ""

    // ── State ────────────────────────────────────────────────────────────────

    property bool active:
        false

    property bool busy:
        false

    property string errorMessage:
        ""

    property string _lastError:
        ""

    readonly property bool available:
        root.wifiDeviceName !== ""

    readonly property string wifiDeviceName:
        NetworkService.wifiDevice?.name ?? ""

    // Current Wi-Fi channel information.
    //
    // When the laptop is connected to Wi-Fi, the hotspot is created
    // on the same band/channel so the adapter can keep both the
    // managed Wi-Fi connection and the AP active simultaneously.

    property string wifiBand:
        ""

    property int wifiChannel:
        0

    // ── Password generation ──────────────────────────────────────────────────

    function generatePassword() {
        const chars =
            "ABCDEFGHJKLMNPQRSTUVWXYZ" +
            "abcdefghijkmnopqrstuvwxyz" +
            "23456789";

        let result = "";

        for (let i = 0; i < 10; i++) {
            result +=
                chars.charAt(
                    Math.floor(
                        Math.random() *
                        chars.length
                    )
                );
        }

        root.password =
            result;
    }

    // ── Active-state polling ─────────────────────────────────────────────────

    Timer {
        id:
            refreshTimer

        interval:
            1500

        repeat:
            true

        running:
            true

        onTriggered:
            root.refresh()
    }

    Process {
        id:
            statusProcess

        stdout:
            StdioCollector {
                onStreamFinished:
                    root._applyStatus(
                        this.text
                    )
            }

        stderr:
            StdioCollector {}
    }

    function refresh() {
        if (!root.available) {
            root.active =
                false;

            return;
        }

        if (statusProcess.running)
            return;

        statusProcess.exec({
            command: [
                "nmcli",
                "-g",
                "NAME",
                "connection",
                "show",
                "--active"
            ]
        });
    }

    function _applyStatus(output) {
        const names =
            output
                .split(/\r?\n/)
                .map(line => line.trim())
                .filter(
                    line =>
                        line.length > 0
                );

        root.active =
            names.indexOf(
                root.connectionName
            ) >= 0;

        if (root.active)
            root.errorMessage = "";
    }

    // ── Delete stale hotspot profile ─────────────────────────────────────────

    Process {
        id:
            deleteProfileProcess

        stdout:
            StdioCollector {}

        stderr:
            StdioCollector {}

        onExited: {
            // It is fine if the profile didn't exist.
            // Continue regardless of nmcli's exit code.
            root._queryCurrentChannel();
        }
    }

    // ── Query current Wi-Fi frequency ────────────────────────────────────────

    Process {
        id:
            channelProcess

        stdout:
            StdioCollector {
                onStreamFinished:
                    root._applyCurrentFrequency(
                        this.text
                    )
            }

        stderr:
            StdioCollector {
                onStreamFinished:
                    root._lastError =
                        this.text.trim()
            }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root._finishAction(
                    root._lastError ||
                    "Could not determine the current Wi-Fi channel."
                );

                return;
            }

            root._createHotspot();
        }
    }

    function _queryCurrentChannel() {
        root.wifiBand = "";
        root.wifiChannel = 0;

        if (
            !root.wifiDeviceName ||
            !NetworkService.wifiConnected
        ) {
            root._createHotspot();
            return;
        }

        root._lastError = "";

        channelProcess.exec({
            command: [
                "iw",
                "dev",
                root.wifiDeviceName,
                "link"
            ]
        });
    }

    function _applyCurrentFrequency(output) {
        root.wifiBand = "";
        root.wifiChannel = 0;

        const match =
            output.match(
                /freq:\s*(\d+)/
            );

        if (!match)
            return;

        const frequency =
            Number(match[1]);

        // 6 GHz
        if (frequency >= 5925) {
            root.wifiBand =
                "6GHz";

            root.wifiChannel =
                Math.round(
                    (frequency - 5950) / 5
                ) + 1;

            return;
        }

        // 5 GHz
        if (frequency >= 5000) {
            root.wifiBand =
                "a";

            root.wifiChannel =
                Math.round(
                    (frequency - 5000) / 5
                );

            return;
        }

        // 2.4 GHz channel 14
        if (frequency === 2484) {
            root.wifiBand =
                "bg";

            root.wifiChannel =
                14;

            return;
        }

        // 2.4 GHz
        if (frequency >= 2412) {
            root.wifiBand =
                "bg";

            root.wifiChannel =
                Math.round(
                    (frequency - 2407) / 5
                );
        }
    }

    // ── Create hotspot ───────────────────────────────────────────────────────

    Process {
        id:
            createProcess

        stdout:
            StdioCollector {}

        stderr:
            StdioCollector {
                onStreamFinished:
                    root._lastError =
                        this.text.trim()
            }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root._finishAction();
            } else {
                root._finishAction(
                    root._lastError ||
                    "Failed to create the hotspot."
                );
            }
        }
    }

    function _createHotspot() {
        if (!root.wifiDeviceName) {
            root._finishAction(
                "No Wi-Fi device is available."
            );

            return;
        }

        const command = [
            "nmcli",
            "device",
            "wifi",
            "hotspot",

            "ifname",
            root.wifiDeviceName,

            "con-name",
            root.connectionName,

            "ssid",
            root.ssid
        ];

        // Lock the hotspot to the same channel as the
        // current Wi-Fi connection when possible.
        //
        // Your adapter reports:
        //
        // #{ managed } <= 1,
        // #{ AP, P2P-client, P2P-GO } <= 1,
        // total <= 2,
        // #channels <= 1
        //
        // Therefore managed Wi-Fi + AP must share one channel.

        if (
            root.wifiBand !== "" &&
            root.wifiChannel > 0
        ) {
            command.push(
                "band",
                root.wifiBand,

                "channel",
                String(
                    root.wifiChannel
                )
            );
        }

        command.push(
            "password",
            root.password
        );

        root._lastError = "";

        createProcess.exec({
            command:
                command
        });
    }

    // ── Start ────────────────────────────────────────────────────────────────

    function start() {
        if (!root.available)
            return;

        if (root.busy)
            return;

        if (!root.ssid.trim()) {
            root.errorMessage =
                "SSID cannot be empty.";

            return;
        }

        if (root.password.length < 8) {
            root.errorMessage =
                "Password must be at least 8 characters.";

            return;
        }

        root.errorMessage =
            "";

        root._lastError =
            "";

        root.wifiBand =
            "";

        root.wifiChannel =
            0;

        root.busy =
            true;

        // Remove the old profile first so stale SSID/password/channel
        // settings cannot interfere with the new hotspot.
        deleteProfileProcess.exec({
            command: [
                "nmcli",
                "connection",
                "delete",
                "id",
                root.connectionName
            ]
        });
    }

    // ── Stop ─────────────────────────────────────────────────────────────────

    Process {
        id:
            downProcess

        stdout:
            StdioCollector {}

        stderr:
            StdioCollector {
                onStreamFinished:
                    root._lastError =
                        this.text.trim()
            }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root._finishAction();
            } else {
                root._finishAction(
                    root._lastError ||
                    "Failed to stop the hotspot."
                );
            }
        }
    }

    function stop() {
        if (
            !root.active ||
            root.busy
        ) {
            return;
        }

        root.errorMessage =
            "";

        root._lastError =
            "";

        root.wifiBand =
            "";

        root.wifiChannel =
            0;

        root.busy =
            true;

        downProcess.exec({
            command: [
                "nmcli",
                "connection",
                "down",
                "id",
                root.connectionName
            ]
        });
    }

    // ── Finish action ────────────────────────────────────────────────────────

    function _finishAction(
        errorText = "",
        outputText = ""
    ) {
        if (!root.busy)
            return;

        if (
            errorText &&
            errorText.trim().length > 0
        ) {
            root.errorMessage =
                errorText.trim();
        }

        root.busy =
            false;

        Qt.callLater(
            root.refresh
        );
    }

    Component.onCompleted: {
        if (!root.password)
            root.generatePassword();

        root.refresh();
    }
}

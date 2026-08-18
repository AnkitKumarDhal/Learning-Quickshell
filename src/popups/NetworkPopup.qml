import QtQuick
import QtQuick.Controls
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

    color: "transparent"

    exclusionMode:
        ExclusionMode.Ignore

    anchors {
        top: true
        right: true
    }

    implicitWidth: 400
    implicitHeight:
        root.screen
            ? root.screen.height
            : 800

    WlrLayershell.layer:
        WlrLayer.Overlay

    WlrLayershell.keyboardFocus:
        WlrKeyboardFocus.OnDemand

    visible:
        slide.windowVisible

    // ── State ────────────────────────────────────────────────────────────────

    property var selectedNetwork: null

    readonly property bool selectedNetworkSupportsPsk:
        root.selectedNetwork !== null &&
        (
            root.selectedNetwork.security === WifiSecurityType.WpaPsk ||
            root.selectedNetwork.security === WifiSecurityType.Wpa2Psk ||
            root.selectedNetwork.security === WifiSecurityType.Sae
        )

    onVisibleChanged: {
        if (!visible)
            root.selectedNetwork = null;
    }

    // If the selected network becomes connected, close the editor.
    Connections {
        target: root.selectedNetwork

        function onConnectedChanged() {
            if (root.selectedNetwork?.connected)
                root.selectedNetwork = null;
        }
    }

    // ── Wi-Fi model ──────────────────────────────────────────────────────────

    ScriptModel {
        id: wifiNetworkModel

        objectProp: "name"

        values: {
            if (!NetworkService.wifiDevice)
                return [];

            return [
                ...NetworkService.wifiDevice.networks.values
            ].sort((a, b) => {
                if (a.connected !== b.connected)
                    return a.connected ? -1 : 1;

                return b.signalStrength - a.signalStrength;
            });
        }
    }

    // ── Bluetooth models ─────────────────────────────────────────────────────

    ScriptModel {
        id: btConnectedModel

        objectProp: "address"

        values:
            NetworkService.bluetooth.connectedDevices
    }

    ScriptModel {
        id: btPairedModel

        objectProp: "address"

        values:
            NetworkService.bluetooth.pairedDevices
    }

    ScriptModel {
        id: btAvailableModel

        objectProp: "address"

        values:
            NetworkService.bluetooth.availableDevices
    }

    // ── Scanner lifecycle ────────────────────────────────────────────────────

    Binding {
        target: NetworkService
        property: "scannerActive"
        value: Popups.networkOpen
    }

    // ── Popup mask ───────────────────────────────────────────────────────────

    mask: Region {
        x:
            root.implicitWidth -
            connectivityCard.width -
            Theme.barMargin

        y:
            Theme.barHeight + 8

        width:
            connectivityCard.width

        height:
            connectivityCard.height
    }

    // ── Slide wrapper ────────────────────────────────────────────────────────

    PopupSlide {
        id: slide

        anchors.fill: parent

        edge: "top"

        open:
            Popups.networkOpen

        onCloseRequested:
            Popups.networkOpen = false

        // ── Main card ─────────────────────────────────────────────────────────

        Rectangle {
            id: connectivityCard

            anchors {
                top: parent.top
                right: parent.right

                topMargin:
                    Theme.barHeight + 8

                rightMargin:
                    Theme.barMargin
            }

            width: 380

            height:
                mainColumn.implicitHeight + 24

            radius:
                Theme.popupRadius

            color:
                Colors.surfaceContainer

            border.width:
                Theme.popupBorder

            border.color:
                Colors.outlineVariant

            clip: true

            // ── Main content ────────────────────────────────────────────────

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

                // ── Header ──────────────────────────────────────────────────

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text:
                            "Connectivity"

                        font.family:
                            Fonts.font

                        font.pixelSize: 16
                        font.bold: true

                        color:
                            Colors.on_Surface

                        Layout.fillWidth: true
                    }

                    Text {
                        text: "󰅖"

                        font.family:
                            Fonts.fontM
                        font.pixelSize: 15

                        color:
                            Colors.outline

                        MouseArea {
                            anchors.fill: parent

                            cursorShape:
                                Qt.PointingHandCursor

                            onClicked:
                                Popups.networkOpen = false
                        }
                    }
                }

                // ── Status cards ─────────────────────────────────────────────

                RowLayout {
                    Layout.fillWidth: true

                    spacing: 8

                    // Wi-Fi status card
                    Rectangle {
                        Layout.fillWidth: true

                        implicitHeight: 66

                        radius: 12

                        color:
                            NetworkService.wifiConnected
                                ? Colors.primaryContainer
                                : Colors.surfaceContainerHigh

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.hoverFadeDuration
                            }
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 12
                                rightMargin: 12
                            }

                            spacing: 10

                            Text {
                                text: {
                                    if (!NetworkService.wifiEnabled)
                                        return "󰤭";

                                    if (!NetworkService.wifiConnected)
                                        return "󰤭";

                                    const s =
                                        NetworkService.signalStrength;

                                    if (s < 0.25)
                                        return "󰤟";

                                    if (s < 0.50)
                                        return "󰤢";

                                    if (s < 0.75)
                                        return "󰤥";

                                    return "󰤨";
                                }

                                font.family:
                                    Fonts.fontM

                                font.pixelSize: 20

                                color:
                                    NetworkService.wifiConnected
                                        ? Colors.on_PrimaryContainer
                                        : Colors.outline
                            }

                            ColumnLayout {
                                Layout.fillWidth: true

                                spacing: 1

                                Text {
                                    text: "Wi-Fi"

                                    font.family:
                                        Fonts.font

                                    font.pixelSize: 10
                                    font.bold: true

                                    color:
                                        NetworkService.wifiConnected ? Colors.surfaceContainerHighest : Colors.on_SurfaceVariant
                                }

                                Text {
                                    text:
                                        !NetworkService.wifiEnabled
                                            ? "Disabled"
                                            : NetworkService.wifiConnected
                                                ? (NetworkService.ssid || "Connected")
                                                : "Not connected"

                                    font.family:
                                        Fonts.font

                                    font.pixelSize: 11
                                    font.bold: true

                                    color: NetworkService.wifiConnected ? Colors.on_PrimaryContainer : Colors.on_Surface
                                    elide:
                                        Text.ElideRight

                                    Layout.fillWidth: true
                                }
                            }

                            Rectangle {
                                width: 38
                                height: 22
                                radius: 11

                                color:
                                    NetworkService.wifiEnabled
                                        ? Colors.primary
                                        : Colors.surfaceContainerHighest

                                border.width:
                                    NetworkService.wifiEnabled
                                        ? 0
                                        : 1

                                border.color:
                                    Colors.outlineVariant

                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 8

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    x:
                                        NetworkService.wifiEnabled
                                            ? 19
                                            : 3

                                    color:
                                        NetworkService.wifiEnabled
                                            ? Colors.on_Primary
                                            : Colors.outline

                                    Behavior on x {
                                        NumberAnimation {
                                            duration:
                                                Theme.hoverFadeDuration

                                            easing.type:
                                                Easing.OutCubic
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent

                                    enabled:
                                        NetworkService.wifiHardwareEnabled ?? true

                                    cursorShape:
                                        Qt.PointingHandCursor

                                    onClicked:
                                        NetworkService.setWifiEnabled(
                                            !NetworkService.wifiEnabled
                                        )
                                }
                            }
                        }
                    }

                    // Bluetooth status card
                    Rectangle {
                        Layout.fillWidth: true

                        implicitHeight: 66

                        radius: 12

                        color:
                            NetworkService.bluetooth.connectedDeviceCount > 0
                                ? Colors.primaryContainer
                                : Colors.surfaceContainerHigh

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.hoverFadeDuration
                            }
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 12
                                rightMargin: 12
                            }

                            spacing: 10

                            Text {
                                text:
                                    NetworkService.bluetooth.enabled
                                        ? "󰂯"
                                        : "󰂲"

                                font.family:
                                    Fonts.fontM

                                font.pixelSize: 20

                                color:
                                    NetworkService.bluetooth.connectedDeviceCount > 0
                                        ? Colors.on_PrimaryContainer
                                        : Colors.outline
                            }

                            ColumnLayout {
                                Layout.fillWidth: true

                                spacing: 1

                                Text {
                                    text: "Bluetooth"

                                    font.family:
                                        Fonts.font

                                    font.pixelSize: 10
                                    font.bold: true

                                    color:
                                        NetworkService.bluetooth.connectedDeviceCount > 0 ? Colors.surfaceContainerHighest : Colors.on_SurfaceVariant
                                }

                                Text {
                                    text:
                                        !NetworkService.bluetooth.available
                                            ? "Unavailable"
                                            : !NetworkService.bluetooth.enabled
                                                ? "Disabled"
                                                : NetworkService.bluetooth.connectedDeviceCount > 0
                                                    ? NetworkService.bluetooth.connectedDeviceCount + " connected"
                                                    : "Ready"

                                    font.family:
                                        Fonts.font

                                    font.pixelSize: 11
                                    font.bold: true

                                    color: NetworkService.bluetooth.connectedDeviceCount > 0 ? Colors.on_PrimaryContainer : Colors.on_Surface

                                    Layout.fillWidth: true
                                }
                            }

                            Rectangle {
                                width: 38
                                height: 22
                                radius: 11

                                color:
                                    NetworkService.bluetooth.enabled
                                        ? Colors.primary
                                        : Colors.surfaceContainerHighest

                                border.width:
                                    NetworkService.bluetooth.enabled
                                        ? 0
                                        : 1

                                border.color:
                                    Colors.outlineVariant

                                opacity:
                                    NetworkService.bluetooth.available
                                        ? 1
                                        : 0.45

                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 8

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    x:
                                        NetworkService.bluetooth.enabled
                                            ? 19
                                            : 3

                                    color:
                                        NetworkService.bluetooth.enabled
                                            ? Colors.on_Primary
                                            : Colors.outline

                                    Behavior on x {
                                        NumberAnimation {
                                            duration:
                                                Theme.hoverFadeDuration

                                            easing.type:
                                                Easing.OutCubic
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent

                                    enabled:
                                        NetworkService.bluetooth.available

                                    cursorShape:
                                        Qt.PointingHandCursor

                                    onClicked:
                                        NetworkService.bluetooth.setEnabled(
                                            !NetworkService.bluetooth.enabled
                                        )
                                }
                            }
                        }
                    }
                }

                // ── Detail tabs ──────────────────────────────────────────────

                TabBar {
                    Layout.fillWidth: true

                    orientation:
                        "horizontal"

                    currentPage:
                        [
                            "wifi",
                            "bluetooth",
                            "hotspot"
                        ][Popups.networkTab]

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
                        const index =
                            [
                                "wifi",
                                "bluetooth",
                                "hotspot"
                            ].indexOf(key);

                        if (index >= 0)
                            Popups.networkTab = index;
                    }
                }

                // ═════════════════════════════════════════════════════════════
                // Wi-Fi
                // ═════════════════════════════════════════════════════════════

                ColumnLayout {
                    visible:
                        Popups.networkTab === 0

                    Layout.fillWidth: true

                    spacing: 8

                    // Selected connection editor
                    Rectangle {
                        visible:
                            root.selectedNetwork !== null

                        Layout.fillWidth: true

                        implicitHeight:
                            selectedEditorColumn.implicitHeight + 20

                        radius: 12

                        color:
                            Colors.primaryContainer

                        border.width: 1

                        border.color:
                            Colors.primary

                        ColumnLayout {
                            id: selectedEditorColumn

                            anchors {
                                fill: parent
                                margins: 10
                            }

                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text:
                                        "󰤨"

                                    font.family:
                                        Fonts.fontM

                                    font.pixelSize: 16

                                    color:
                                        Colors.on_PrimaryContainer
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true

                                    spacing: 1

                                    Text {
                                        text:
                                            root.selectedNetwork?.name ??
                                            ""

                                        font.family:
                                            Fonts.font

                                        font.pixelSize: 12
                                        font.bold: true

                                        color:
                                            Colors.on_PrimaryContainer
                                    }

                                    Text {
                                        text:
                                            root.selectedNetworkSupportsPsk
                                                ? "Enter Wi-Fi password"
                                                : "Additional authentication may be required"

                                        font.family:
                                            Fonts.font

                                        font.pixelSize: 9

                                        color:
                                            Colors.on_SurfaceVariant
                                    }
                                }

                                Text {
                                    text: "󰅖"

                                    font.family:
                                        Fonts.fontM

                                    font.pixelSize: 13

                                    color:
                                        Colors.on_PrimaryContainer

                                    MouseArea {
                                        anchors.fill: parent

                                        cursorShape:
                                            Qt.PointingHandCursor

                                        onClicked:
                                            root.selectedNetwork = null
                                    }
                                }
                            }

                            // PSK editor
                            RowLayout {
                                visible:
                                    root.selectedNetworkSupportsPsk

                                Layout.fillWidth: true

                                spacing: 8

                                TextField {
                                    id: passwordField

                                    Layout.fillWidth: true

                                    height: 34

                                    placeholderText:
                                        "Password"

                                    echoMode:
                                        TextInput.Password

                                    font.family:
                                        Fonts.font

                                    font.pixelSize: 11

                                    color:
                                        Colors.on_Surface

                                    placeholderTextColor:
                                        Colors.outline

                                    background: Rectangle {
                                        radius: 8

                                        color:
                                            Colors.surfaceContainer

                                        border.width: 1

                                        border.color:
                                            passwordField.activeFocus
                                                ? Colors.primary
                                                : Colors.outlineVariant
                                    }

                                    Keys.onReturnPressed: {
                                        if (
                                            root.selectedNetworkSupportsPsk &&
                                            text.length > 0
                                        ) {
                                            root.selectedNetwork.connectWithPsk(
                                                text
                                            );

                                            text = "";
                                        }
                                    }

                                    Component.onCompleted:
                                        forceActiveFocus()
                                }

                                Rectangle {
                                    width: 34
                                    height: 28

                                    radius: 8

                                    color: Colors.on_Surface

                                    Text {
                                        anchors.centerIn: parent

                                        text: "󰌑"

                                        font.family:
                                            Fonts.fontM

                                        font.pixelSize: 14

                                        color: Colors.on_Primary
                                    }

                                    HoverHandler {
                                        id: confirmHover
                                    }

                                    MouseArea {
                                        anchors.fill: parent

                                        cursorShape:
                                            Qt.PointingHandCursor

                                        onClicked: {
                                            if (
                                                passwordField.text.length > 0 &&
                                                root.selectedNetworkSupportsPsk
                                            ) {
                                                root.selectedNetwork.connectWithPsk(
                                                    passwordField.text
                                                );

                                                passwordField.text = "";
                                            }
                                        }
                                    }
                                }
                            }

                            // Non-PSK secured network
                            Rectangle {
                                visible:
                                    root.selectedNetwork !== null &&
                                    !root.selectedNetworkSupportsPsk &&
                                    root.selectedNetwork.security !== WifiSecurityType.Open

                                Layout.fillWidth: true

                                implicitHeight: 34

                                radius: 8

                                color:
                                    Colors.surfaceContainer

                                Text {
                                    anchors.centerIn: parent

                                    text:
                                        "This network does not use PSK authentication."

                                    font.family:
                                        Fonts.font

                                    font.pixelSize: 9

                                    color:
                                        Colors.on_SurfaceVariant
                                }
                            }
                        }
                    }

                    // Network list
                    Flickable {
                        Layout.fillWidth: true

                        Layout.preferredHeight:
                            Math.min(
                                wifiListColumn.implicitHeight,
                                300
                            )

                        contentHeight:
                            wifiListColumn.implicitHeight

                        clip: true

                        boundsBehavior:
                            Flickable.StopAtBounds

                        visible:
                            NetworkService.wifiEnabled

                        ColumnLayout {
                            id: wifiListColumn

                            width:
                                parent.width

                            spacing: 4

                            Repeater {
                                model:
                                    wifiNetworkModel

                                delegate: NetworkRow {
                                    required property var modelData

                                    Layout.fillWidth: true

                                    network:
                                        modelData

                                    onNetworkSelected: (network) => {
                                        root.selectedNetwork = network;

                                        if (
                                            network.security ===
                                            WifiSecurityType.Open
                                        ) {
                                            network.connect();
                                        }
                                    }
                                }
                            }

                            Text {
                                visible:
                                    wifiNetworkModel.values.length === 0

                                Layout.alignment:
                                    Qt.AlignHCenter

                                text:
                                    "Scanning…"

                                font.family:
                                    Fonts.font

                                font.pixelSize: 10

                                color:
                                    Colors.outline

                                topPadding: 8
                                bottomPadding: 8
                            }
                        }
                    }

                    Text {
                        visible:
                            !NetworkService.wifiEnabled

                        Layout.alignment:
                            Qt.AlignHCenter

                        text:
                            "Wi-Fi is disabled"

                        font.family:
                            Fonts.font

                        font.pixelSize: 10

                        color:
                            Colors.outline

                        topPadding: 8
                        bottomPadding: 8
                    }
                }

                // ═════════════════════════════════════════════════════════════
                // Bluetooth
                // ═════════════════════════════════════════════════════════════

                ColumnLayout {
                    visible:
                        Popups.networkTab === 1

                    Layout.fillWidth: true

                    spacing: 8

                    // Scan control
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text:
                                NetworkService.bluetooth.scanning
                                    ? "Scanning for devices…"
                                    : "Bluetooth devices"

                            font.family:
                                Fonts.font

                            font.pixelSize: 11
                            font.bold: true

                            color:
                                Colors.on_SurfaceVariant

                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width:
                                scanLabel.implicitWidth + 20

                            height: 28

                            radius: 14

                            color:
                                NetworkService.bluetooth.scanning
                                    ? Colors.primary
                                    : Colors.surfaceContainerHighest

                            Text {
                                id: scanLabel

                                anchors.centerIn: parent

                                text:
                                    NetworkService.bluetooth.scanning
                                        ? "Stop"
                                        : "Scan"

                                font.family:
                                    Fonts.font

                                font.pixelSize: 10
                                font.bold: true

                                color:
                                    NetworkService.bluetooth.scanning
                                        ? Colors.on_Primary
                                        : Colors.on_Surface
                            }

                            MouseArea {
                                anchors.fill: parent

                                cursorShape:
                                    Qt.PointingHandCursor

                                onClicked: {
                                    if (
                                        NetworkService.bluetooth.scanning
                                    ) {
                                        NetworkService.bluetooth.stopScan();
                                    } else {
                                        NetworkService.bluetooth.scan();
                                    }
                                }
                            }
                        }
                    }

                    // Connected
                    Text {
                        visible:
                            btConnectedModel.values.length > 0

                        text:
                            "Connected"

                        font.family:
                            Fonts.font

                        font.pixelSize: 10
                        font.bold: true

                        color:
                            Colors.on_SurfaceVariant

                        topPadding: 4
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        spacing: 4

                        Repeater {
                            model:
                                btConnectedModel

                            delegate: Rectangle {
                                required property var modelData

                                Layout.fillWidth: true

                                implicitHeight: 52

                                radius: 10

                                color:
                                    Colors.primaryContainer

                                RowLayout {
                                    anchors {
                                        fill: parent
                                        leftMargin: 12
                                        rightMargin: 10
                                    }

                                    spacing: 9

                                    Text {
                                        text:
                                            modelData.icon
                                                .includes("headphones")
                                                ? "󰋋"
                                                : modelData.icon
                                                    .includes("keyboard")
                                                    ? "󰌌"
                                                    : modelData.icon
                                                        .includes("mouse")
                                                        ? "󰍽"
                                                        : "󰂯"

                                        font.family:
                                            Fonts.fontM

                                        font.pixelSize: 17

                                        color:
                                            Colors.primary
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true

                                        spacing: 1

                                        Text {
                                            text:
                                                modelData.name

                                            font.family:
                                                Fonts.font

                                            font.pixelSize: 11
                                            font.bold: true

                                            color:
                                                Colors.on_Surface

                                            elide:
                                                Text.ElideRight

                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text:
                                                modelData.batteryAvailable
                                                    ? Math.round(
                                                        modelData.battery * 100
                                                    ) + "%"
                                                    : "Connected"

                                            font.family:
                                                Fonts.font

                                            font.pixelSize: 9

                                            color:
                                                Colors.outline
                                        }
                                    }

                                    Rectangle {
                                        width:
                                            disconnectLabel.implicitWidth + 18

                                        height: 24

                                        radius: 12

                                        color:
                                            Colors.surfaceContainerHighest

                                        Text {
                                            id: disconnectLabel

                                            anchors.centerIn: parent

                                            text: "Disconnect"

                                            font.family:
                                                Fonts.font

                                            font.pixelSize: 9

                                            font.bold: true

                                            color:
                                                Colors.on_Surface
                                        }

                                        MouseArea {
                                            anchors.fill: parent

                                            cursorShape:
                                                Qt.PointingHandCursor

                                            onClicked:
                                                NetworkService.bluetooth.disconnect(
                                                    modelData.address
                                                )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Paired
                    Text {
                        visible:
                            btPairedModel.values.length > 0

                        text:
                            "Paired devices"

                        font.family:
                            Fonts.font

                        font.pixelSize: 10
                        font.bold: true

                        color:
                            Colors.on_SurfaceVariant

                        topPadding: 4
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        spacing: 4

                        Repeater {
                            model:
                                btPairedModel

                            delegate: Rectangle {
                                required property var modelData

                                Layout.fillWidth: true

                                implicitHeight: 46

                                radius: 10

                                color:
                                    Colors.surfaceContainerHigh

                                RowLayout {
                                    anchors {
                                        fill: parent
                                        leftMargin: 12
                                        rightMargin: 10
                                    }

                                    spacing: 9

                                    Text {
                                        text: "󰂯"

                                        font.family:
                                            Fonts.fontM

                                        font.pixelSize: 16

                                        color:
                                            Colors.outline
                                    }

                                    Text {
                                        text:
                                            modelData.name

                                        font.family:
                                            Fonts.font

                                        font.pixelSize: 11

                                        color:
                                            Colors.on_Surface

                                        elide:
                                            Text.ElideRight

                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        width:
                                            connectLabel.implicitWidth + 18

                                        height: 24

                                        radius: 12

                                        color:
                                            Colors.primaryContainer

                                        Text {
                                            id: connectLabel

                                            anchors.centerIn: parent

                                            text: "Connect"

                                            font.family:
                                                Fonts.font

                                            font.pixelSize: 9
                                            font.bold: true

                                            color:
                                                Colors.on_PrimaryContainer
                                        }

                                        MouseArea {
                                            anchors.fill: parent

                                            cursorShape:
                                                Qt.PointingHandCursor

                                            onClicked:
                                                NetworkService.bluetooth.connect(
                                                    modelData.address
                                                )
                                        }
                                    }

                                    Text {
                                        text: "󰆴"

                                        font.family:
                                            Fonts.fontM

                                        font.pixelSize: 13

                                        color:
                                            Colors.outline

                                        MouseArea {
                                            anchors.fill: parent

                                            cursorShape:
                                                Qt.PointingHandCursor

                                            onClicked:
                                                NetworkService.bluetooth.remove(
                                                    modelData.address
                                                )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Available
                    Text {
                        visible:
                            btAvailableModel.values.length > 0

                        text:
                            "Nearby devices"

                        font.family:
                            Fonts.font

                        font.pixelSize: 10
                        font.bold: true

                        color:
                            Colors.on_SurfaceVariant

                        topPadding: 4
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        spacing: 4

                        Repeater {
                            model:
                                btAvailableModel

                            delegate: Rectangle {
                                required property var modelData

                                Layout.fillWidth: true

                                implicitHeight: 46

                                radius: 10

                                color:
                                    Colors.surfaceContainerHigh

                                RowLayout {
                                    anchors {
                                        fill: parent
                                        leftMargin: 12
                                        rightMargin: 10
                                    }

                                    spacing: 9

                                    Text {
                                        text: "󰂯"

                                        font.family:
                                            Fonts.fontM

                                        font.pixelSize: 16

                                        color:
                                            Colors.outline
                                    }

                                    Text {
                                        text:
                                            modelData.name

                                        font.family:
                                            Fonts.font

                                        font.pixelSize: 11

                                        color:
                                            Colors.on_Surface

                                        elide:
                                            Text.ElideRight

                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        width:
                                            pairLabel.implicitWidth + 18

                                        height: 24

                                        radius: 12

                                        color:
                                            Colors.primary

                                        Text {
                                            id: pairLabel

                                            anchors.centerIn: parent

                                            text: "Pair"

                                            font.family:
                                                Fonts.font

                                            font.pixelSize: 9
                                            font.bold: true

                                            color:
                                                Colors.on_Primary
                                        }

                                        MouseArea {
                                            anchors.fill: parent

                                            cursorShape:
                                                Qt.PointingHandCursor

                                            onClicked:
                                                NetworkService.bluetooth.pair(
                                                    modelData.address
                                                )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible:
                            NetworkService.bluetooth.enabled &&
                            btConnectedModel.values.length === 0 &&
                            btPairedModel.values.length === 0 &&
                            btAvailableModel.values.length === 0

                        Layout.alignment:
                            Qt.AlignHCenter

                        text:
                            "No Bluetooth devices"

                        font.family:
                            Fonts.font

                        font.pixelSize: 10

                        color:
                            Colors.outline

                        topPadding: 12
                        bottomPadding: 12
                    }

                    Text {
                        visible:
                            !NetworkService.bluetooth.enabled

                        Layout.alignment:
                            Qt.AlignHCenter

                        text:
                            NetworkService.bluetooth.available
                                ? "Bluetooth is disabled"
                                : "No Bluetooth adapter found"

                        font.family:
                            Fonts.font

                        font.pixelSize: 10

                        color:
                            Colors.outline

                        topPadding: 12
                        bottomPadding: 12
                    }
                }

                // ═════════════════════════════════════════════════════════════
                // Hotspot
                // ═════════════════════════════════════════════════════════════

                ColumnLayout {
                    visible:
                        Popups.networkTab === 2

                    Layout.fillWidth: true

                    spacing: 6

                    Text {
                        Layout.alignment:
                            Qt.AlignHCenter

                        text: "󰀂"

                        font.family:
                            Fonts.fontM

                        font.pixelSize: 32

                        color:
                            Colors.outline

                        topPadding: 12
                    }

                    Text {
                        Layout.alignment:
                            Qt.AlignHCenter

                        text:
                            "Hotspot coming soon"

                        font.family:
                            Fonts.font

                        font.pixelSize: 11

                        color:
                            Colors.outline

                        bottomPadding: 12
                    }
                }
            }
        }
    }
}

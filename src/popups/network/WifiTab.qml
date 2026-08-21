import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Quickshell
import Quickshell.Networking

import qs.src.services
import qs.src.theme

ColumnLayout {
    id: root

    property var selectedNetwork: null
    property var pendingKnownNetwork: null
    property bool showPassword: false

    signal networkSelected(var network)

    readonly property bool selectedNetworkSupportsPsk:
        root.selectedNetwork !== null &&
        (
            root.selectedNetwork.security === WifiSecurityType.WpaPsk ||
            root.selectedNetwork.security === WifiSecurityType.Wpa2Psk ||
            root.selectedNetwork.security === WifiSecurityType.Sae
        )

    Layout.fillWidth: true
    spacing: 8

    onSelectedNetworkChanged: {
        root.showPassword = false
        if (root.selectedNetworkSupportsPsk) {
            Qt.callLater(function() {
                passwordField.forceActiveFocus();
            });
        }
    }

    Connections {
        target: root.pendingKnownNetwork

        function onConnectionFailed(reason) {
            if ( reason === ConnectionFailReason.NoSecrets && root.pendingKnownNetwork !== null) {
                root.selectedNetwork = root.pendingKnownNetwork;
                root.pendingKnownNetwork = null;
            }
        }
    }

    ScriptModel {
        id: wifiConnectedModel
        objectProp: "name"
        values: {
            if (!NetworkService.wifiDevice) return [];

            return [ ...NetworkService.wifiDevice.networks.values ]
            .filter(network => network.connected)
            .sort((a, b) => b.signalStrength - a.signalStrength);
        }
    }

    ScriptModel {
        id: wifiAvailableModel
        objectProp: "name"
        values: {
            if (!NetworkService.wifiDevice) return [];

            return [...NetworkService.wifiDevice.networks.values]
            .filter(network => !network.connected && network !== root.selectedNetwork)
            .sort((a, b) => b.signalStrength - a.signalStrength);
        }
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: NetworkService.wifiScanning
                    ? "Wi-Fi networks · Scanning"
                    : "Wi-Fi networks"

            font.family: Fonts.font
            font.pixelSize: 14
            font.bold: true

            color: Colors.on_SurfaceVariant

            Layout.fillWidth: true
        }

        Rectangle {
            width: wifiScanLabel.implicitWidth + 20
            height: 28
            radius: 14

            color: wifiScanHover.hovered
                    ? Colors.primary
                    : Colors.surfaceContainerHighest

            Behavior on color {
                ColorAnimation {
                    duration: Theme.hoverFadeDuration
                }
            }

            Text {
                id: wifiScanLabel
                anchors.centerIn: parent

                text: "Scan"

                font.family: Fonts.font
                font.pixelSize: 10
                font.bold: true

                color: wifiScanHover.hovered
                        ? Colors.on_Primary
                        : Colors.on_Surface
            }

            HoverHandler {
                id: wifiScanHover
            }

            MouseArea {
                anchors.fill: parent
                enabled: NetworkService.wifiEnabled
                cursorShape: Qt.PointingHandCursor
                onClicked: NetworkService.scanWifi()
            }
        }
    }

    Flickable {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(wifiContent.implicitHeight, 320)
        contentHeight: wifiContent.implicitHeight

        clip: true
        boundsBehavior: Flickable.StopAtBounds
        visible: NetworkService.wifiEnabled

        ColumnLayout {
            id: wifiContent

            width: parent.width
            spacing: 6

            Text {
                visible: wifiConnectedModel.values.length > 0
                text: "Connected"

                font.family: Fonts.font
                font.pixelSize: 10
                font.bold: true

                color: Colors.on_SurfaceVariant

                topPadding: 2
                bottomPadding: 2
            }

            Repeater {
                model: wifiConnectedModel

                delegate:
                    NetworkRow {
                        required property var modelData

                        Layout.fillWidth: true
                        network: modelData
                        onNetworkSelected: (network) => {
                                root.networkSelected(network);
                            }
                    }
            }

            Text {
                visible: root.selectedNetwork !== null
                text: "Connect"

                font.family: Fonts.font
                font.pixelSize: 10
                font.bold: true

                color: Colors.on_SurfaceVariant

                topPadding: 6
                bottomPadding: 2
            }

            Rectangle {
                visible: root.selectedNetwork !== null

                Layout.fillWidth: true
                implicitHeight: selectedEditorColumn.implicitHeight + 20

                radius: 12
                color: Colors.primaryContainer

                border.width: 1
                border.color: Colors.primary

                ColumnLayout {
                    id: selectedEditorColumn

                    anchors {
                        fill: parent
                        margins: 10
                    }

                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Item {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 28

                            Text {
                                anchors.centerIn: parent
                                text: "󰤨"

                                font.family: Fonts.fontM
                                font.pixelSize: 18

                                color: Colors.on_PrimaryContainer
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true

                            spacing: 1

                            Text {
                                text: root.selectedNetwork?.name ?? ""

                                Layout.fillWidth: true
                                elide: Text.ElideRight

                                font.family: Fonts.font
                                font.pixelSize: 12
                                font.bold: true

                                color: Colors.on_PrimaryContainer
                            }

                            Text {
                                text: root.selectedNetworkSupportsPsk
                                        ? "Enter Wi-Fi password"
                                        : "Additional authentication may be required"

                                font.family: Fonts.font
                                font.pixelSize: 9

                                color: Colors.surfaceContainerHighest
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14

                            color: closeConnectHover.hovered
                                    ? Colors.surfaceContainerHighest
                                    : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.hoverFadeDuration
                                }
                            }

                            HoverHandler {
                                id: closeConnectHover
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"

                                font.family: Fonts.fontM
                                font.pixelSize: 14

                                color: Colors.on_PrimaryContainer
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.networkSelected(null)
                            }
                        }
                    }

                    RowLayout {
                        visible: root.selectedNetworkSupportsPsk

                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: passwordField

                            Layout.fillWidth: true
                            height: 34
                            rightPadding: 42
                            placeholderText: "Password"

                            echoMode: showPassword ? TextInput.Normal : TextInput.Password

                            font.family: Fonts.font
                            font.pixelSize: 11

                            color: Colors.on_Surface
                            placeholderTextColor: Colors.outline

                            background: Rectangle {
                                radius: 8
                                color: Colors.surfaceContainer
                                border.width: passwordField.activeFocus ? 1 : 0
                                border.color: Colors.primary
                            }

                            Rectangle {
                                id: passwordVisibilityButton

                                anchors {
                                    top: parent.top
                                    right: parent.right
                                    bottom: parent.bottom
                                }

                                width: 42
                                color: "transparent"

                                z: 10

                                HoverHandler {
                                    id: passwordVisibilityHover
                                    cursorShape: Qt.PointingHandCursor
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.showPassword ? "󰈉" : "󰈈"

                                    font.family: Fonts.fontM
                                    font.pixelSize: 15

                                    color: passwordVisibilityHover.hovered
                                            ? Colors.primary
                                            : Colors.outline

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Theme.hoverFadeDuration
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    z: 1

                                    acceptedButtons: Qt.LeftButton
                                    cursorShape: Qt.PointingHandCursor

                                    onPressed: mouse.accepted = true
                                    onReleased: mouse.accepted = true
                                    onClicked: {
                                        mouse.accepted = true;
                                        root.showPassword = !root.showPassword;
                                        passwordField.forceActiveFocus();
                                    }
                                }
                            }

                            Keys.onReturnPressed: {
                                if (root.selectedNetworkSupportsPsk && text.length > 0) {
                                    root.selectedNetwork.connectWithPsk(text);
                                    text = "";
                                }
                            }

                            Component.onCompleted: forceActiveFocus()
                        }

                        Rectangle {
                            width: 34
                            height: 34
                            radius: 8

                            color: confirmHover.hovered
                                    ? Colors.primary
                                    : Colors.on_Surface

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.hoverFadeDuration
                                }
                            }

                            HoverHandler {
                                id: confirmHover
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰌑"

                                font.family: Fonts.fontM
                                font.pixelSize: 14

                                color: Colors.on_Primary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.selectedNetworkSupportsPsk && passwordField.text.length > 0) {
                                        root.selectedNetwork.connectWithPsk(passwordField.text);
                                        passwordField.text = "";
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: root.selectedNetwork !== null && !root.selectedNetworkSupportsPsk && root.selectedNetwork.security !== WifiSecurityType.Open

                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 8

                        color: Colors.surfaceContainer

                        Text {
                            anchors.centerIn: parent
                            text: "This network does not use PSK authentication."

                            font.family: Fonts.font
                            font.pixelSize: 9

                            color: Colors.on_SurfaceVariant
                        }
                    }
                }
            }

            Text {
                visible: wifiAvailableModel.values.length > 0
                text: "Available"

                font.family: Fonts.font
                font.pixelSize: 10
                font.bold: true

                color: Colors.on_SurfaceVariant

                topPadding: 6
                bottomPadding: 2
            }

            Repeater {
                model: wifiAvailableModel

                delegate:
                    NetworkRow {
                        required property var modelData
                        Layout.fillWidth: true
                        network: modelData

                        onNetworkSelected: (network) => {
                                if (network.security === WifiSecurityType.Open) {
                                    network.connect();
                                    return;
                                }

                                if (network.known) {
                                    root.pendingKnownNetwork = network;
                                    network.connect();
                                    return;
                                }

                                root.networkSelected(network);
                            }
                    }
            }

            Text {
                visible: wifiConnectedModel.values.length === 0 && root.selectedNetwork === null && wifiAvailableModel.values.length === 0
                Layout.alignment: Qt.AlignHCenter

                text: NetworkService.wifiScanning ? "Scanning…" : "No Wi-Fi networks found"

                font.family: Fonts.font
                font.pixelSize: 10

                color: Colors.outline

                topPadding: 10
                bottomPadding: 10
            }
        }
    }

    Text {
        visible: !NetworkService.wifiEnabled

        Layout.alignment: Qt.AlignHCenter
        text: "Wi-Fi is disabled"

        font.family: Fonts.font
        font.pixelSize: 10

        color: Colors.outline

        topPadding: 8
        bottomPadding: 8
    }
}

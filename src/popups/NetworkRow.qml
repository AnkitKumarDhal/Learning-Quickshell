import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Networking
import qs.src.theme
import qs.src.components

Rectangle {
    id: row

    required property var network

    implicitHeight: innerCol.implicitHeight + 8
    radius: 8
    color: rowHover.containsMouse
        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, Theme.hoverOpacity)
        : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }

    HoverHandler { id: rowHover }

    property bool _showPsk: false

    // listen for connection failure — show psk prompt if NoSecrets
    Connections {
        target: row.network
        function onConnectionFailed(reason) {
            if (reason === ConnectionFailReason.NoSecrets) {
                row._showPsk = true;
            }
        }
    }

    ColumnLayout {
        id: innerCol
        anchors { left: parent.left; right: parent.right; margins: 8 }
        anchors.verticalCenter: undefined
        y: 4
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // signal strength icon
            Text {
                text: {
                    if (!row.network.connected && row.network.state === ConnectionState.Connecting)
                        return "󱑤"; // spinning-ish, best available
                    const s = row.network.signalStrength ?? 0;
                    if (s < 0.25) return "󰤟";
                    if (s < 0.50) return "󰤢";
                    if (s < 0.75) return "󰤥";
                    return "󰤨";
                }
                font.family: Fonts.fontM
                font.pixelSize: 14
                color: row.network.connected ? Colors.primary : Colors.on_Surface
            }

            // SSID
            Text {
                text: row.network.name
                font.family: Fonts.font
                font.pixelSize: 11
                font.weight: row.network.connected ? Font.Medium : Font.Normal
                color: row.network.connected ? Colors.primary : Colors.on_Surface
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // lock icon for secured networks
            Text {
                visible: row.network.security !== WifiSecurityType.Open
                text: "󰌾"
                font.family: Fonts.fontM
                font.pixelSize: 11
                color: Colors.outline
            }

            // connect / disconnect button
            Rectangle {
                width: row.network.connected ? 76 : 56
                height: 22; radius: 11
                visible: rowHover.containsMouse || row.network.connected || row.network.stateChanging

                color: row.network.connected
                    ? Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.15)
                    : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                border.width: 1
                border.color: row.network.connected ? Colors.error : Colors.primary

                Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
                Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (row.network.stateChanging)
                            return row.network.state === ConnectionState.Connecting ? "Connecting" : "Disconnecting";
                        return row.network.connected ? "Disconnect" : "Connect";
                    }
                    font.family: Fonts.font
                    font.pixelSize: 9
                    color: row.network.connected ? Colors.error : Colors.primary
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !row.network.stateChanging
                    onClicked: {
                        if (row.network.connected) {
                            row.network.disconnect();
                            row._showPsk = false;
                        } else {
                            row._showPsk = false;
                            row.network.connect();
                            // if NoSecrets, onConnectionFailed will flip _showPsk
                        }
                    }
                }
            }
        }

        // password prompt — appears when connection fails with NoSecrets
        RowLayout {
            visible: row._showPsk
            Layout.fillWidth: true
            spacing: 6

            TextField {
                id: pskField
                Layout.fillWidth: true
                height: 28
                placeholderText: "Password"
                echoMode: TextInput.Password
                font.family: Fonts.font
                font.pixelSize: 11
                color: Colors.on_Surface
                placeholderTextColor: Colors.outline
                background: Rectangle {
                    radius: 8
                    color: Colors.surfaceContainerHigh
                    border.width: 1
                    border.color: pskField.activeFocus ? Colors.primary : Colors.outline
                    Behavior on border.color { ColorAnimation { duration: Theme.hoverFadeDuration } }
                }
                Keys.onReturnPressed: {
                    if (text.length > 0) {
                        row.network.connectWithPsk(text);
                        text = "";
                    }
                }
            }

            // confirm button
            Rectangle {
                width: 28; height: 28; radius: 8
                color: confirmHover.containsMouse
                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)
                    : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.1)

                Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }

                HoverHandler { id: confirmHover }

                Text {
                    anchors.centerIn: parent
                    text: "󰌑"
                    font.family: Fonts.fontM
                    font.pixelSize: 14
                    color: Colors.primary
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (pskField.text.length > 0) {
                            row.network.connectWithPsk(pskField.text);
                            pskField.text = "";
                        }
                    }
                }
            }
        }
    }
}

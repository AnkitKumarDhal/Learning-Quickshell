import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Networking
import qs.src.theme
import qs.src.components

Item {
    id: root
    required property var network

    implicitHeight: innerCol.implicitHeight + 24
    property bool _showPsk: false

    Connections {
        target: root.network
        function onConnectionFailed(reason) {
            if (reason === ConnectionFailReason.NoSecrets) {
                root._showPsk = true;
            }
        }
    }

    // Background and full-row click handler
    Rectangle {
        anchors.fill: parent
        radius: 10
        color: rowHover.containsMouse
            ? Colors.surfaceContainerHighest
            : (root.network.connected 
                ? Qt.rgba(Colors.primaryContainer.r, Colors.primaryContainer.g, Colors.primaryContainer.b, 0.3) 
                : "transparent")
        
        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
            id: rowHover
            anchors.fill: parent
            enabled: !root.network.stateChanging
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.network.connected) {
                    root.network.disconnect();
                    root._showPsk = false;
                } else {
                    root._showPsk = false;
                    root.network.connect();
                }
            }
        }
    }

    // Content sits on top so the TextField can consume its own clicks safely
    ColumnLayout {
        id: innerCol
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Signal strength icon
            Text {
                text: {
                    if (!root.network.connected && root.network.state === ConnectionState.Connecting) return "󱑤";
                    const s = root.network.signalStrength ?? 0;
                    if (s < 0.25) return "󰤟";
                    if (s < 0.50) return "󰤢";
                    if (s < 0.75) return "󰤥";
                    return "󰤨";
                }
                color: root.network.connected ? Colors.primary : Colors.on_SurfaceVariant
                font.pixelSize: 16
                font.family: Fonts.fontM
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            // SSID
            Text {
                text: root.network.name
                color: root.network.connected ? Colors.on_Surface : Colors.on_SurfaceVariant
                font.pixelSize: 12
                font.bold: root.network.connected
                font.family: Fonts.font
                elide: Text.ElideRight
                Layout.fillWidth: true
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            // Lock icon
            Text {
                visible: root.network.security !== WifiSecurityType.Open && !root.network.connected
                text: "󰌾"
                font.family: Fonts.fontM
                font.pixelSize: 14
                color: Colors.outline
            }

            // "Connected" chip (mirrors DeviceRow's "Default" chip)
            Rectangle {
                visible: root.network.connected || root.network.stateChanging
                width: chipRow.implicitWidth + 16
                height: 22
                radius: 11
                color: root.network.connected ? Colors.primary : Colors.surfaceContainerHighest

                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: root.network.connected ? "󰄵" : "󱑤"
                        color: root.network.connected ? Colors.on_Primary : Colors.on_SurfaceVariant
                        font.pixelSize: 10
                        font.family: Fonts.font
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.network.connected ? "Connected" : "Connecting"
                        color: root.network.connected ? Colors.on_Primary : Colors.on_SurfaceVariant
                        font.pixelSize: 10
                        font.bold: true
                        font.family: Fonts.font
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // Password Row
        RowLayout {
            visible: root._showPsk
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 8

            TextField {
                id: pskField
                Layout.fillWidth: true
                height: 32
                placeholderText: "Password"
                echoMode: TextInput.Password
                font.family: Fonts.font
                font.pixelSize: 12
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
                        root.network.connectWithPsk(text);
                        text = "";
                    }
                }
            }

            Rectangle {
                width: 32; height: 32; radius: 8
                color: confirmHover.containsMouse 
                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2) 
                    : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.1)
                Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }
                HoverHandler { id: confirmHover }
                
                Text { anchors.centerIn: parent; text: "󰌑"; font.family: Fonts.fontM; font.pixelSize: 14; color: Colors.primary }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (pskField.text.length > 0) {
                            root.network.connectWithPsk(pskField.text);
                            pskField.text = "";
                        }
                    }
                }
            }
        }
    }
}

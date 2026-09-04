import QtQuick
import QtQuick.Layouts

import Quickshell

import qs.src.services
import qs.src.theme

ColumnLayout {
    id: root

    Layout.fillWidth: true
    spacing: 8

    ScriptModel {
        id: btConnectedModel
        objectProp: "address"
        values: NetworkService.bluetooth.connectedDevices
    }
    ScriptModel {
        id: btPairedModel
        objectProp: "address"
        values: NetworkService.bluetooth.pairedDevices
    }
    ScriptModel {
        id: btAvailableModel
        objectProp: "address"
        values: NetworkService.bluetooth.availableDevices
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: NetworkService.bluetooth.scanning ? "Scanning for devices…" : "Bluetooth devices"

            font.family: Fonts.font
            font.pixelSize: 14
            font.bold: true

            color: Colors.on_SurfaceVariant

            Layout.fillWidth: true
        }

        Rectangle {
            width: scanLabel.implicitWidth + 20
            height: 28
            radius: 14

            color: NetworkService.bluetooth.scanning || btScanHover.hovered ? Colors.primary : Colors.surfaceContainerHighest

            Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }

            Text {
                id: scanLabel

                anchors.centerIn: parent
                text: NetworkService.bluetooth.scanning ? "Stop" : "Scan"

                font.family: Fonts.font
                font.pixelSize: 10
                font.bold: true

                color: NetworkService.bluetooth.scanning || btScanHover.hovered ? Colors.on_Primary : Colors.on_Surface
            }

            HoverHandler {
                id: btScanHover
            }

            MouseArea {
                anchors.fill: parent

                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    if (NetworkService.bluetooth.scanning) {
                        NetworkService.bluetooth.stopScan();
                    } else {
                        NetworkService.bluetooth.scan();
                    }
                }
            }
        }
    }

    Flickable {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentColumn.implicitHeight, 320)

        contentHeight: contentColumn.implicitHeight
        clip: true

        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentColumn

            width: parent.width
            spacing: 6

            Text {
                visible: btConnectedModel.values.length > 0
                text: "Connected"

                font.family: Fonts.font
                font.pixelSize: 10
                font.bold: true

                color: Colors.on_SurfaceVariant
                topPadding: 2
            }

            Repeater {
                model: btConnectedModel

                delegate:
                    Rectangle {
                        required property var modelData

                        Layout.fillWidth: true

                        implicitHeight: 52
                        radius: 10

                        color: connectedHover.hovered
                                ? Colors.surfaceContainerHighest
                                : Qt.rgba(
                                    Colors.primaryContainer.r,
                                    Colors.primaryContainer.g,
                                    Colors.primaryContainer.b,
                                    0.28
                                )

                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }

                        HoverHandler {
                            id: connectedHover
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 12
                                rightMargin: 10
                            }

                            spacing: 9

                            Text {
                                text: modelData.icon.includes("headphones")
                                        ? "󰋋"
                                        : modelData.icon.includes("keyboard")
                                            ? "󰌌"
                                            : modelData.icon.includes("mouse")
                                                ? "󰍽"
                                                : "󰂯"

                                font.family: Fonts.fontM
                                font.pixelSize: 17

                                color: Colors.primary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true

                                spacing: 1

                                Text {
                                    text: modelData.name

                                    font.family: Fonts.font
                                    font.pixelSize: 11
                                    font.bold: true

                                    color: Colors.on_Surface
                                    elide: Text.ElideRight

                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "Connected"

                                    font.family: Fonts.font
                                    font.pixelSize: 9
                                    color: Colors.on_SurfaceVariant
                                }
                            }

                            Rectangle {
                                width: disconnectLabel.implicitWidth + 18
                                height: 24
                                radius: 12

                                color: disconnectHover.hovered ? Colors.primary : Colors.primary

                                Text {
                                    id: disconnectLabel

                                    anchors.centerIn: parent
                                    text: "Disconnect"

                                    font.family: Fonts.font
                                    font.pixelSize: 9
                                    font.bold: true

                                    color: Colors.on_Primary
                                }

                                HoverHandler {
                                    id: disconnectHover
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NetworkService.bluetooth.disconnect(modelData.address)
                                }
                            }
                        }
                    }
            }

            Text {
                visible: btPairedModel.values.length > 0
                text: "Paired devices"

                font.family: Fonts.font
                font.pixelSize: 10
                font.bold: true

                color: Colors.on_SurfaceVariant

                topPadding: 6
            }

            Repeater {
                model: btPairedModel

                delegate:
                    Rectangle {
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: 46
                        radius: 10

                        color: pairedHover.hovered ? Colors.surfaceContainerHighest : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }

                        HoverHandler {
                            id: pairedHover
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 12
                                rightMargin: 10
                            }

                            spacing: 9

                            Text {
                                text: "󰂯"
                                font.family: Fonts.fontM
                                font.pixelSize: 16
                                color: Colors.on_SurfaceVariant
                            }

                            Text {
                                text: modelData.name

                                font.family: Fonts.font
                                font.pixelSize: 11

                                color: Colors.on_SurfaceVariant
                                elide: Text.ElideRight

                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: connectLabel.implicitWidth + 18
                                height: 24
                                radius: 12
                                enabled: !NetworkService.bluetooth.isConnecting(modelData.address)

                                color: NetworkService.bluetooth.isConnecting(modelData.address) ? Colors.surfaceContainerHighest : pairedConnectHover.hovered ? Colors.primary : Colors.primaryContainer
                                Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }

                                HoverHandler {
                                    id: pairedConnectHover
                                }

                                Text {
                                    id: connectLabel

                                    anchors.centerIn: parent
                                    text: NetworkService.bluetooth.isConnecting(modelData.address) ? "Connecting..." : "Connect"

                                    font.family: Fonts.font
                                    font.pixelSize: 9
                                    font.bold: true

                                    color: NetworkService.bluetooth.isConnecting(modelData.address) ? Colors.on_SurfaceVariant : pairedConnectHover.hovered ? Colors.on_Primary : Colors.on_PrimaryContainer
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NetworkService.bluetooth.connect(modelData.address)
                                }
                            }

                            Rectangle {
                                width: 26
                                height: 26
                                radius: 13

                                color: removeHover.hovered ? Colors.errorContainer : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }

                                HoverHandler {
                                    id: removeHover
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰆴"

                                    font.family: Fonts.fontM
                                    font.pixelSize: 13

                                    color: removeHover.hovered ? Colors.on_ErrorContainer : Colors.outline
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NetworkService.bluetooth.remove(modelData.address)
                                }
                            }
                        }
                    }
            }

            Text {
                visible: btAvailableModel.values.length > 0
                text: "Nearby devices"

                font.family: Fonts.font
                font.pixelSize: 10
                font.bold: true

                color: Colors.on_SurfaceVariant
                topPadding: 6
            }

            Repeater {
                model: btAvailableModel

                delegate:
                    Rectangle {
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: 46
                        radius: 10

                        color: availableHover.hovered ? Colors.surfaceContainerHighest : "transparent"

                        Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }

                        HoverHandler {
                            id: availableHover
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 12
                                rightMargin: 10
                            }

                            spacing: 9

                            Text {
                                text: "󰂯"

                                font.family: Fonts.fontM
                                font.pixelSize: 16

                                color: Colors.on_SurfaceVariant
                            }

                            Text {
                                text: modelData.name

                                font.family: Fonts.font
                                font.pixelSize: 11

                                color: Colors.on_SurfaceVariant
                                elide: Text.ElideRight

                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: pairLabel.implicitWidth + 18
                                height: 24
                                radius: 12

                                color: NetworkService.bluetooth.isPairing(modelData.address) ? Colors.surfaceContainerHighest : availablePairHover.hovered ? Colors.primaryContainer : Colors.primary

                                Behavior on color { ColorAnimation { duration: Theme.hoverFadeDuration } }

                                HoverHandler {
                                    id: availablePairHover
                                }

                                Text {
                                    id: pairLabel

                                    anchors.centerIn: parent
                                    text: NetworkService.bluetooth.isPairing(modelData.address) ? "Cancel" : "Pair"

                                    font.family: Fonts.font
                                    font.pixelSize: 9
                                    font.bold: true

                                    color: NetworkService.bluetooth.isPairing(modelData.address)
                                            ? availablePairHover.hovered
                                                ? Colors.errorContainer
                                                : Colors.surfaceContainerHighest
                                            : availablePairHover.hovered
                                                ? Colors.primaryContainer
                                                : Colors.primary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (NetworkService.bluetooth.isPairing(modelData.address)) {
                                            NetworkService.bluetooth.cancelPair(modelData.address)
                                        } else {
                                            NetworkService.bluetooth.pair(modelData.address)
                                        }
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

                Layout.alignment: Qt.AlignHCenter
                text: "No Bluetooth devices"

                font.family: Fonts.font
                font.pixelSize: 10

                color: Colors.outline

                topPadding: 12
                bottomPadding: 12
            }

            Text {
                visible: !NetworkService.bluetooth.enabled
                Layout.alignment: Qt.AlignHCenter

                text: NetworkService.bluetooth.available ? "Bluetooth is disabled" : "No Bluetooth adapter found"

                font.family: Fonts.font
                font.pixelSize: 10

                color: Colors.outline

                topPadding: 12
                bottomPadding: 12
            }
        }
    }
}

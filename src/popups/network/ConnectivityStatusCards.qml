import QtQuick
import QtQuick.Layouts

import qs.src.services
import qs.src.theme

RowLayout {
    id: root

    Layout.fillWidth:
        true

    spacing:
        8

    // ── Wi-Fi ────────────────────────────────────────────────────────────────

    Rectangle {
        Layout.fillWidth:
            true

        implicitHeight:
            66

        radius:
            12

        color:
            NetworkService.wifiConnected
                ? Colors.primaryContainer
                : Colors.surfaceContainerHigh

        Behavior on color {
            ColorAnimation {
                duration:
                    Theme.hoverFadeDuration
            }
        }

        RowLayout {
            anchors {
                fill:
                    parent

                leftMargin:
                    12

                rightMargin:
                    12
            }

            spacing:
                10

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

                font.pixelSize:
                    20

                color:
                    NetworkService.wifiConnected
                        ? Colors.on_PrimaryContainer
                        : Colors.outline
            }

            ColumnLayout {
                Layout.fillWidth:
                    true

                spacing:
                    1

                Text {
                    text:
                        "Wi-Fi"

                    font.family:
                        Fonts.font

                    font.pixelSize:
                        10

                    font.bold:
                        true

                    color:
                        NetworkService.wifiConnected
                            ? Colors.on_PrimaryContainer
                            : Colors.on_SurfaceVariant
                }

                Text {
                    text:
                        !NetworkService.wifiEnabled
                            ? "Disabled"
                            : NetworkService.wifiConnected
                                ? (
                                    NetworkService.ssid ||
                                    "Connected"
                                )
                                : "Not connected"

                    font.family:
                        Fonts.font

                    font.pixelSize:
                        11

                    font.bold:
                        true

                    color:
                        NetworkService.wifiConnected
                            ? Colors.on_PrimaryContainer
                            : Colors.on_Surface

                    elide:
                        Text.ElideRight

                    Layout.fillWidth:
                        true
                }
            }

            Rectangle {
                width:
                    38

                height:
                    22

                radius:
                    11

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
                    width:
                        16

                    height:
                        16

                    radius:
                        8

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
                    anchors.fill:
                        parent

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

    // ── Bluetooth ────────────────────────────────────────────────────────────

    Rectangle {
        Layout.fillWidth:
            true

        implicitHeight:
            66

        radius:
            12

        color:
            NetworkService.bluetooth.connectedDeviceCount > 0
                ? Colors.primaryContainer
                : Colors.surfaceContainerHigh

        Behavior on color {
            ColorAnimation {
                duration:
                    Theme.hoverFadeDuration
            }
        }

        RowLayout {
            anchors {
                fill:
                    parent

                leftMargin:
                    12

                rightMargin:
                    12
            }

            spacing:
                10

            Text {
                text:
                    NetworkService.bluetooth.enabled
                        ? "󰂯"
                        : "󰂲"

                font.family:
                    Fonts.fontM

                font.pixelSize:
                    20

                color:
                    NetworkService.bluetooth.connectedDeviceCount > 0
                        ? Colors.on_PrimaryContainer
                        : NetworkService.bluetooth.enabled
                            ? Colors.primary
                            : Colors.outline
            }

            ColumnLayout {
                Layout.fillWidth:
                    true

                spacing:
                    1

                Text {
                    text:
                        "Bluetooth"

                    font.family:
                        Fonts.font

                    font.pixelSize:
                        10

                    font.bold:
                        true

                    color:
                        NetworkService.bluetooth.connectedDeviceCount > 0
                            ? Colors.on_PrimaryContainer
                            : Colors.on_SurfaceVariant
                }

                Text {
                    text:
                        !NetworkService.bluetooth.available
                            ? "Unavailable"
                            : !NetworkService.bluetooth.enabled
                                ? "Disabled"
                                : NetworkService.bluetooth.connectedDeviceCount > 0
                                    ? (
                                        NetworkService.bluetooth.connectedDeviceCount +
                                        " connected"
                                    )
                                    : "Ready"

                    font.family:
                        Fonts.font

                    font.pixelSize:
                        11

                    font.bold:
                        true

                    color:
                        NetworkService.bluetooth.connectedDeviceCount > 0
                            ? Colors.on_PrimaryContainer
                            : Colors.on_Surface

                    Layout.fillWidth:
                        true
                }
            }

            Rectangle {
                width:
                    38

                height:
                    22

                radius:
                    11

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
                    width:
                        16

                    height:
                        16

                    radius:
                        8

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
                    anchors.fill:
                        parent

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

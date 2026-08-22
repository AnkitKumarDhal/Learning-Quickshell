import QtQuick
import QtQuick.Layouts

import qs.src.services
import qs.src.services.system
import qs.src.state
import qs.src.theme
import qs.src.components

PillBase {
    id: root

    border.color: Colors.primary
    border.width: Popups.networkOpen ? 1 : 0
    Behavior on border.width { NumberAnimation { duration: 150 } }

    readonly property bool hasWifi: NetworkService.wifiDevice !== null
    readonly property bool hasEthernet: SystemStats.activeInterface !== ""
    readonly property bool hasBluetooth: NetworkService.bluetooth.available

    visible: hasWifi || hasBluetooth || hasEthernet

    readonly property string wifiIcon: {
        if (!hasWifi) return hasEthernet ? "󰈀" : "󰤭";
        if (!NetworkService.wifiEnabled) return "󰤭";
        if (!NetworkService.wifiConnected) return "󰤭";
        const signal = NetworkService.signalStrength;

        if (signal < 0.25) return "󰤟";
        if (signal < 0.50) return "󰤢";
        if (signal < 0.75) return "󰤥";
        return "󰤨";
    }

    readonly property bool wifiGood: hasWifi && NetworkService.wifiEnabled && NetworkService.wifiConnected
    readonly property string bluetoothIcon: !hasBluetooth ? "" : NetworkService.bluetooth.enabled ? "󰂯" : "󰂲"
    readonly property bool bluetoothGood: hasBluetooth && NetworkService.bluetooth.enabled
    readonly property int bluetoothCount: NetworkService.bluetooth.connectedDeviceCount

    onClicked: {
        const wasOpen = Popups.networkOpen;

        Popups.networkOpen = !wasOpen;

        if (!wasOpen) {
            Popups.networkTab = wifiGood ? 0 : bluetoothGood ? 1 : 0;
        }
    }

    onRightClicked: {
        Popups.networkOpen = true;
        Popups.networkTab = 1;
    }

    Text {
        text: root.wifiIcon

        font.family: Fonts.fontM
        font.pixelSize: 14

        color: root.wifiGood ? Colors.primary : Colors.outline

        Behavior on color {
            ColorAnimation {
                duration: Theme.hoverFadeDuration
            }
        }
    }

    Text {
        visible: root.wifiGood && NetworkService.ssid.length > 0
        text: NetworkService.ssid

        font.family: Fonts.fontM
        font.pointSize: 11
        font.bold: true

        color: Colors.primary

        elide: Text.ElideRight

        Layout.maximumWidth: 105
    }

    Rectangle {
        visible: root.hasWifi && root.hasBluetooth

        Layout.preferredWidth: 1
        Layout.preferredHeight: 13

        radius: 1
        color: Colors.outlineVariant
        opacity: 0.8
    }

    Text {
        visible: root.hasBluetooth
        text: root.bluetoothIcon

        font.family: Fonts.fontM
        font.pixelSize: 14

        color: root.bluetoothGood ? Colors.primary : Colors.outline

        Behavior on color {
            ColorAnimation {
                duration: Theme.hoverFadeDuration
            }
        }
    }

    Rectangle {
        visible: root.bluetoothCount > 0

        Layout.preferredWidth: countText.implicitWidth + 8
        Layout.preferredHeight: 16

        radius: 8

        color: Colors.primaryContainer

        Text {
            id: countText

            anchors.centerIn: parent
            text: root.bluetoothCount > 9 ? "9+" : String(root.bluetoothCount)

            font.family: Fonts.font
            font.pixelSize: 9
            font.bold: true

            color: Colors.on_PrimaryContainer
        }
    }

    Text {
        visible: !root.hasWifi && root.hasEthernet && !root.hasBluetooth
        text: SystemStats.activeInterface

        font.family: Fonts.fontM
        font.pixelSize: 12
        font.bold: true

        color: Colors.primary

        elide: Text.ElideRight
        Layout.maximumWidth: 95
    }
}

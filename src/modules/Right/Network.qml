// src/modules/Right/Network.qml
import QtQuick
import QtQuick.Layouts
import qs.src.services
import qs.src.state
import qs.src.theme
import qs.src.components

PillBase {
    id: root

    readonly property string _icon: {
        if (!NetworkService.wifiEnabled || !NetworkService.wifiConnected)
            return "󰤭";
        const s = NetworkService.signalStrength;
        if (s < 0.25) return "󰤟";
        if (s < 0.50) return "󰤢";
        if (s < 0.75) return "󰤥";
        return "󰤨";
    }

    readonly property bool _showLabel: NetworkService.wifiEnabled && NetworkService.wifiConnected

    onClicked: {
        Popups.networkOpen = !Popups.networkOpen;
        if (Popups.networkOpen) Popups.networkTab = 0;
    }

    onRightClicked: {
        Popups.networkOpen = true;
        Popups.networkTab  = 2;
    }

    Text {
        text: root._icon
        font.family: Fonts.fontM
        font.pixelSize: 14
        color: NetworkService.wifiConnected ? Colors.onBackground : Colors.outline
    }

    Text {
        text: NetworkService.ssid || "Unknown"
        font.family: Fonts.font
        font.pixelSize: 11
        color: Colors.on_Background
        visible: root._showLabel
    }
}

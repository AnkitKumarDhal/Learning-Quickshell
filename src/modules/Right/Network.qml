import QtQuick
import QtQuick.Layouts
import qs.src.services
import qs.src.services.system
import qs.src.state
import qs.src.theme
import qs.src.components

PillBase {
    id: root

    readonly property bool hasWifi: NetworkService.wifiDevice !== null
    readonly property bool hasEthernet: SystemStats.activeInterface !== ""

    visible: hasWifi || NetworkService.btAdapter !== null || hasEthernet

    readonly property string _icon: {
        if (hasWifi) {
            if (!NetworkService.wifiEnabled || !NetworkService.wifiConnected)
                return "󰤭";
            const s = NetworkService.signalStrength;
            if (s < 0.25) return "󰤟";
            if (s < 0.50) return "󰤢";
            if (s < 0.75) return "󰤥";
            return "󰤨";
        }
        return hasEthernet ? "󰈀" : "󰈂";
    }

    readonly property bool _showLabel: (hasWifi && NetworkService.wifiEnabled && NetworkService.wifiConnected) || (!hasWifi && hasEthernet)

    onClicked: {
        Popups.networkOpen = !Popups.networkOpen;
        if (Popups.networkOpen) {
            Popups.networkTab = hasWifi ? 0 : 1;
        }
    }

    onRightClicked: {
        Popups.networkOpen = true;
        Popups.networkTab  = 2;
    }

    Text {
        text: root._icon
        font.family: Fonts.fontM
        font.pixelSize: 14
        color: (hasWifi && NetworkService.wifiConnected) || (!hasWifi && hasEthernet) ? Colors.primary : Colors.outline
    }

    Text {
        text: hasWifi ? (NetworkService.ssid || "Unknown") : SystemStats.activeInterface
        font.family: Fonts.font
        font.pixelSize: 13
        color: Colors.primary
        visible: root._showLabel
    }
}

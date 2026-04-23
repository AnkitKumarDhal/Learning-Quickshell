pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // Special colors
    property color background: "#1a1b26"
    property color foreground: "#c0caf5"
    property color cursor: "#c0caf5"

    // Full palette
    property color color0:  "#1a1b26"
    property color color1:  "#f7768e"
    property color color2:  "#9ece6a"
    property color color3:  "#e0af68"
    property color color4:  "#7aa2f7"
    property color color5:  "#bb9af7"
    property color color6:  "#7dcfff"
    property color color7:  "#a9b1d6"
    property color color8:  "#414868"
    property color color9:  "#f7768e"
    property color color10: "#9ece6a"
    property color color11: "#e0af68"
    property color color12: "#7aa2f7"
    property color color13: "#bb9af7"
    property color color14: "#7dcfff"
    property color color15: "#c0caf5"

    // Derived convenience properties
    property color pillBackground: Qt.rgba(
        root.color0.r, root.color0.g, root.color0.b, 0.78
    )
    property color pillBorder: Qt.rgba(
        root.foreground.r, root.foreground.g, root.foreground.b, 0.12
    )
    property color panelBackground: Qt.rgba(
        root.color0.r, root.color0.g, root.color0.b, 0.92
    )
    property color accent:  root.color4   // primary accent
    property color accent2: root.color5   // secondary accent
    property color accent3: root.color2   // green / success
    property color warn:    root.color3   // yellow / warning
    property color urgent:  root.color1   // red / urgent
    property color muted:   root.color8   // dimmed text/icons

    // Watches the file — live reloads when wal runs
    FileView {
        id: walFile
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation)
              + "/.cache/wal/colors.json"
        onTextChanged: root.load(walFile.text)
    }

    function load(raw) {
        try {
            const data = JSON.parse(raw)
            const s = data.special
            const c = data.colors

            root.background = s.background
            root.foreground  = s.foreground
            root.cursor      = s.cursor

            root.color0  = c.color0;  root.color1  = c.color1
            root.color2  = c.color2;  root.color3  = c.color3
            root.color4  = c.color4;  root.color5  = c.color5
            root.color6  = c.color6;  root.color7  = c.color7
            root.color8  = c.color8;  root.color9  = c.color9
            root.color10 = c.color10; root.color11 = c.color11
            root.color12 = c.color12; root.color13 = c.color13
            root.color14 = c.color14; root.color15 = c.color15
        } catch(e) {
            console.warn("Colors.qml: failed to parse colors.json:", e)
        }
    }
}

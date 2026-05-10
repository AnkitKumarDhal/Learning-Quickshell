pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property var _colors: ({})

    readonly property File colorFile: File {
        path: "./Colors.json"
        onTextChanged: {
            try {
                root._colors = JSON.parse(text)
            }
            catch (e) {
                console.error("Failed to parse Colors.json", e)
            }
        }
    }

    readonly property color background: _colors.background ?? "#1a11111"
    readonly property color onBackground: _colors.on_background ?? "#f1dedd"
    
    readonly property color primary: _colors.primary ?? "#ffb3af"
    readonly property color onPrimary: _colors.on_primary ?? "#571d1c"
    readonly property color primaryContainer: _colors.primary_container ?? "#733331"
    readonly property color onPrimaryContainer: _colors.on_primary_container ?? "#ffdad7"

    readonly property color secondary: _colors.secondary ?? "#e7bdba"
    readonly property color tertiary: _colors.tertiary ?? "#e2c28c"
    
    readonly property color surface: _colors.surface ?? "#1a1111"
    readonly property color surfaceVariant: _colors.surface_variant ?? "#534342"
    readonly property color onSurfaceVariant: _colors.on_surface_variant ?? "#d8c2c0"
    
    readonly property color outline: _colors.outline ?? "#a08c8b"
    readonly property color error: _colors.error ?? "#ffb4ab"

    function get(key, fallback = "#000000") {
        return _colors[key] ?? fallback;
    }
}

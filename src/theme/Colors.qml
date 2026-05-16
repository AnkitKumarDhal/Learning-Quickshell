pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property var palette: ({})

    property FileView watcher: FileView {
        path: Quickshell.shellPath("src/theme/Colors.json")
        watchChanges: true
        onFileChanged: reload()

        onTextChanged: {
            try {
                if (text() !== "") {
                    root.palette = JSON.parse(text())
                }
            } catch (e) {}
        }
    }

    // --- Background & Surface ---
    readonly property color background:              palette.background                || "#1a1111"
    readonly property color on_Background:           palette.on_background             || "#f1dedd"
    readonly property color surface:                 palette.surface                   || "#1a1111"
    readonly property color on_Surface:              palette.on_surface                || "#f1dedd"
    readonly property color surfaceVariant:          palette.surface_variant           || "#534342"
    readonly property color on_SurfaceVariant:       palette.on_surface_variant        || "#d8c2c0"
    readonly property color surfaceContainer:        palette.surface_container         || "#271d1d"
    readonly property color surfaceContainerHigh:    palette.surface_container_high    || "#322827"
    readonly property color surfaceContainerHighest: palette.surface_container_highest || "#3d3231"

    // --- Primary ---
    readonly property color primary:                 palette.primary                   || "#ffb3af"
    readonly property color on_Primary:              palette.on_primary                || "#571d1c"
    readonly property color primaryContainer:        palette.primary_container         || "#733331"
    readonly property color on_PrimaryContainer:     palette.on_primary_container      || "#ffdad7"

    // --- Secondary ---
    readonly property color secondary:               palette.secondary                 || "#e7bdba"
    readonly property color on_Secondary:            palette.on_secondary              || "#442928"
    readonly property color secondaryContainer:      palette.secondary_container       || "#5d3f3d"
    readonly property color on_SecondaryContainer:   palette.on_secondary_container    || "#ffdad7"

    // --- Tertiary ---
    readonly property color tertiary:                palette.tertiary                  || "#e2c28c"
    readonly property color on_Tertiary:             palette.on_tertiary               || "#402d05"
    readonly property color tertiaryContainer:       palette.tertiary_container        || "#594319"
    readonly property color on_TertiaryContainer:    palette.on_tertiary_container     || "#ffdea8"

    // --- Error & Utility ---
    readonly property color error:                   palette.error                     || "#ffb4ab"
    readonly property color on_Error:                palette.on_error                  || "#690005"
    readonly property color errorContainer:          palette.error_container           || "#93000a"
    readonly property color on_ErrorContainer:       palette.on_error_container        || "#ffdad6"
    readonly property color outline:                 palette.outline                   || "#a08c8b"
    readonly property color outlineVariant:          palette.outline_variant           || "#534342"
    readonly property color shadow:                  palette.shadow                    || "#000000"
}

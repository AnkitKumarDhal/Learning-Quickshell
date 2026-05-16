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
    readonly property string background:              palette.background                || "#1a1111"
    readonly property string on_Background:           palette.on_background             || "#f1dedd"
    readonly property string surface:                 palette.surface                   || "#1a1111"
    readonly property string on_Surface:              palette.on_surface                || "#f1dedd"
    readonly property string surfaceVariant:          palette.surface_variant           || "#534342"
    readonly property string on_SurfaceVariant:       palette.on_surface_variant        || "#d8c2c0"
    readonly property string surfaceContainer:        palette.surface_container         || "#271d1d"
    readonly property string surfaceContainerHighest: palette.surface_container_highest || "#3d3231"

    // --- Primary ---
    readonly property string primary:                 palette.primary                   || "#ffb3af"
    readonly property string on_Primary:              palette.on_primary                || "#571d1c"
    readonly property string primaryContainer:        palette.primary_container         || "#733331"
    readonly property string on_PrimaryContainer:     palette.on_primary_container      || "#ffdad7"

    // --- Secondary ---
    readonly property string secondary:               palette.secondary                 || "#e7bdba"
    readonly property string on_Secondary:            palette.on_secondary              || "#442928"
    readonly property string secondaryContainer:      palette.secondary_container       || "#5d3f3d"
    readonly property string on_SecondaryContainer:   palette.on_secondary_container    || "#ffdad7"

    // --- Tertiary ---
    readonly property string tertiary:                palette.tertiary                  || "#e2c28c"
    readonly property string on_Tertiary:             palette.on_tertiary               || "#402d05"
    readonly property string tertiaryContainer:       palette.tertiary_container        || "#594319"
    readonly property string on_TertiaryContainer:    palette.on_tertiary_container     || "#ffdea8"

    // --- Error & Utility ---
    readonly property string error:                   palette.error                     || "#ffb4ab"
    readonly property string on_Error:                palette.on_error                  || "#690005"
    readonly property string errorContainer:          palette.error_container           || "#93000a"
    readonly property string on_ErrorContainer:       palette.on_error_container        || "#ffdad6"
    readonly property string outline:                 palette.outline                   || "#a08c8b"
    readonly property string outlineVariant:          palette.outline_variant           || "#534342"
    readonly property string shadow:                  palette.shadow                    || "#000000"
}

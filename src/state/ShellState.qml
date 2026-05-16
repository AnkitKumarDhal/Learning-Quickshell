pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    // ── Top bar notch widths (written by TopBar, read by PopupDismiss) ─────────
    property int topBarLWidth: 0
    property int topBarCWidth: 0
    property int topBarRWidth: 0

    // ── Focus mode ────────────────────────────────────────────────────────────
    // true = bar collapses to thin strip
    readonly property bool focusMode: _isFullscreen && !_manualOverride

    property bool _isFullscreen:   false
    property bool _manualOverride: false

    // Called by keybind via IPC or GlobalShortcut
    function toggleManualOverride() {
        // Only meaningful when fullscreen is active
        if (_isFullscreen)
            _manualOverride = !_manualOverride
    }

    // Reset override when fullscreen exits so bar returns to full automatically
    on_IsFullscreenChanged: {
        if (!_isFullscreen)
            _manualOverride = false
    }

    // ── Hyprland fullscreen detection ─────────────────────────────────────────
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "fullscreen") {
                // data is "1" when entering fullscreen, "0" when leaving
                root._isFullscreen = (event.data === "1")
            }
        }
    }
}

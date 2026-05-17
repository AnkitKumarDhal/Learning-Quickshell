//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.src.windows
import qs.src.popups
import qs.src.state

ShellRoot {
    // ── Per-screen scope ──────────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Scope {
                required property var modelData

                // ── Bar ───────────────────────────────────────────────────────
                TopBar { screen: modelData }

                // ── Popup dismiss overlay ─────────────────────────────────────
                PopupDismiss { screen: modelData }

                // ── Toasts ────────────────────────────────────────────────────
                NotificationToast { screen: modelData }

                // ── Popups ────────────────────────────────────────────────────
                // All popups are instantiated here and nowhere else.
                // Add new popups to this list as they are built.

                NotificationPanel   { screen: modelData }
                SystemPopup         { screen: modelData }
                VolumePopup         { screen: modelData }
            }
        }
    }

    // ── Focus mode keybind (SUPER+Z) ──────────────────────────────────────────
    // Hyprland lua config bind:
    //   bind = SUPER, Z, global, quickshell:focusModeToggle
    GlobalShortcut {
        appid:       "quickshell"
        name:        "focusModeToggle"
        description: "Toggle bar visibility in fullscreen"
        onPressed:   ShellState.toggleManualOverride()
    }
}

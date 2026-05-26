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
                NetworkPopup        { screen: modelData }
                MediaPopup          { screen: modelData }
                Launcher            { screen: modelData }
                ClipboardPopup      { screen: modelData }
                EmojiPicker         { screen: modelData }
            }
        }
    }

    // ── Global Keybinds ───────────────────────────────────────────────────────
    // Hyprland lua config bind:
    GlobalShortcut {
        appid:       "quickshell"
        name:        "focusModeToggle"
        description: "Toggle bar visibility in fullscreen"
        onPressed:   ShellState.toggleManualOverride()
    }
    GlobalShortcut {
        appid:       "quickshell"
        name:        "barHideToggle"
        description: "Toggle bar visibility anytime"
        onPressed:   ShellState.toggleManualHide()
    }
    GlobalShortcut {
        appid:       "quickshell"
        name:        "launcherToggle"
        description: "Toggle app launcher"
        onPressed:   Popups.launcherOpen = !Popups.launcherOpen
    }
    GlobalShortcut {
        appid:       "quickshell"
        name:        "clipboardToggle"
        description: "Toggle Clipboard Manager overlay"
        onPressed:   Popups.clipboardOpen = !Popups.clipboardOpen
    }
    GlobalShortcut {
        appid:       "quickshell"
        name:        "emojiPickerToggle"
        description: "Toggle Emoji Picker"
        onPressed:   Popups.emojiOpen = !Popups.emojiOpen
    }
    GlobalShortcut {
        appid:       "quickshell"
        name:        "mediaPlayerPopup"
        description: "Toggle Media Player Popup"
        onPressed:   Popups.mediaOpen = !Popups.mediaOpen
    }
}

//@ pragma UseQApplication
//@ pragma IconTheme BeautySolar
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.src.windows
import qs.src.popups
import qs.src.state
import qs.src.components
import qs.src.services

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

                PopupLoader {
                    open: Popups.notificationsOpen
                    popup: Component {
                        NotificationPanel {
                            screen: modelData
                        }
                    }
                }

                PopupLoader {
                    open: Popups.systemOpen
                    popup: Component {
                        SystemPopup {
                            screen: modelData
                        }
                    }
                }

                PopupLoader {
                    open: Popups.volumeOpen
                    popup: Component {
                        VolumePopup {
                            screen: modelData
                        }
                    }
                }

                PopupLoader {
                    open: Popups.networkOpen
                    popup: Component {
                        NetworkPopup {
                            screen: modelData
                        }
                    }
                }

                PopupLoader {
                    open: Popups.mediaOpen
                    popup: Component {
                        MediaPopup {
                            screen: modelData
                        }
                    }
                }

                PopupLoader {
                    open: Popups.launcherOpen
                    popup: Component {
                        Launcher {
                            screen: modelData
                        }
                    }
                }

                PopupLoader {
                    open: Popups.clipboardOpen
                    popup: Component {
                        ClipboardPopup {
                            screen: modelData
                        }
                    }
                }

                PopupLoader {
                    open: Popups.emojiOpen
                    popup: Component {
                        EmojiPicker {
                            screen: modelData
                        }
                    }
                }

                PopupLoader {
                    open: Popups.wallpaperOpen
                    popup: Component {
                        WallpaperPopup {
                            screen: modelData
                        }
                    }
                }

                PopupLoader {
                    open: Popups.batteryOpen
                    popup: Component {
                        BatteryPopup {
                            screen: modelData
                        }
                    }
                }

                PolkitPopup {
                    screen: modelData
                }
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
    GlobalShortcut {
        appid:       "quickshell"
        name:        "wallpaperPickerToggle"
        description: "Toggle Wallpaper Picker"
        onPressed:   Popups.wallpaperOpen = !Popups.wallpaperOpen
    }
}

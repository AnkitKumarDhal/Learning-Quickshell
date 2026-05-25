# Quickshell Shell Configuration

A modern, modular shell configuration built with Quickshell for Hyprland Wayland compositor. Features a sleek top bar with dynamic modules, animated popups, and deep system integration.

## 📚 Documentation

- **[Wiki](https://github.com/AnkitKumarDhal/Learning-Quickshell/wiki)** - Comprehensive guides, architecture details, and customization options
- [Quickshell Documentation](https://quickshell.org/docs/v0.3.0/types/)
- [Hyprland Wiki](https://wiki.hypr.land/)

---

## ⚡ Quick Start

### Prerequisites

| Dependency | Minimum Version |
|------------|-----------------|
| Hyprland | 0.55.0 |
| Quickshell | 0.3.0 |
| Qt6 | 6.6.0 |
| Matugen | 0.10.0 |

### Installation

1. **Clone the configuration**:
```bash
mkdir -p ~/.config/quickshell
git clone https://github.com/yourusername/quickshell-config.git ~/.config/quickshell
# OR copy manually:
# cp -r /path/to/repo/* ~/.config/quickshell/
```

2. **Install dependencies** (Arch Linux):
```bash
sudo pacman -S hyprland qt6-base qt6-declarative
yay -S quickshell matugen
```

3. **Configure Matugen** - Add to `~/.config/matugen/config.toml`:
```toml
[[templates]]
path = "~/.config/quickshell/src/theme/quickshell.json.hbs"
output = "~/.config/quickshell/src/theme/Colors.json"
```

4. **Generate colors from wallpaper**:
```bash
matugen image /path/to/your/wallpaper.jpg
```

5. **Add keybindings to Hyprland** (`~/.config/hypr/hyprland.lua`):
```lua
local mainMod = "SUPER"

hl.bind(mainMod .. " + X", hl.dsp.global("quickshell:barHideToggle"))
hl.bind(mainMod .. " + SPACE", hl.dsp.global("quickshell:launcherToggle"))
hl.bind(mainMod .. " + V", hl.dsp.global("quickshell:clipboardToggle"))
```

6. **Start Quickshell**:
```bash
quickshell &
```

---

## 🎯 Keybindings

| Key Combination | Action |
|-----------------|--------|
| `SUPER + X` | Toggle bar visibility |
| `SUPER + Space` | Open application launcher |
| `SUPER + V` | Open clipboard manager |

> 💡 See the [Wiki](https://github.com/yourusername/quickshell-config/wiki/Keybindings) for adding custom keybindings.

---

## ✨ Features

- **Top Bar** - Three-module layout (Left, Center, Right) with dynamic content
- **Application Launcher** - Fuzzy-search with results list
- **Clipboard Manager** - History-based with paste functionality
- **Media Controls** - Player controls with progress and track info
- **Notification Panel** - Toast notifications with stacking
- **Network Popup** - WiFi, Bluetooth, VPN management
- **System Monitor** - Real-time CPU, memory, disk usage
- **Volume Control** - Per-application volume with device selection
- **Auto-theming** - Material Design 3 colors from wallpaper via Matugen

### Known Limitations

- ⚠️ Focus mode (auto-hide on fullscreen) is currently broken
- ⚠️ VPN and Hotspot tabs are work in progress
- ⚠️ Per-application volume mixer not yet available

See [Known Issues](https://github.com/yourusername/quickshell-config/wiki/Known-Issues) for details.

---

## 🛠️ Basic Configuration

### Change Wallpaper & Regenerate Colors
```bash
matugen image /new/wallpaper/path.jpg
# Quickshell automatically reloads Colors.json
```

### Toggle Modules
Edit `src/state/ShellState.qml` to customize bar behavior and focus mode.

### Customize Popups
Edit `src/state/Popups.qml` to modify default popup states and behaviors.

> 📖 For detailed customization guides, visit the [Wiki](https://github.com/yourusername/quickshell-config/wiki/Customization).

---

## 📁 Project Structure

```
~/.config/quickshell/
├── shell.qml              # Entry point
├── src/
│   ├── components/        # Reusable UI components
│   ├── modules/           # Top bar modules (Left, Center, Right)
│   ├── popups/            # Popup windows
│   ├── services/          # Background system services
│   ├── state/             # Global state management
│   ├── theme/             # Colors, fonts, themes
│   └── windows/           # Window definitions
└── LICENSE
```

> 📚 Complete file structure and architecture documentation available on the [Wiki](https://github.com/yourusername/quickshell-config/wiki/Architecture).

---

## ❓ Troubleshooting

### Common Issues

**Launcher loses keyboard focus after using clipboard**  
→ See [Issue #2](https://github.com/yourusername/quickshell-config/wiki/Known-Issues#clipboard-focus-conflict)

**Volume slider not working with certain apps**  
→ See [Issue #3](https://github.com/yourusername/quickshell-config/wiki/Known-Issues#volume-control-limitations)

**Toast animations janky or stacking inverted**  
→ See [Issue #1](https://github.com/yourusername/quickshell-config/wiki/Known-Issues#notification-toast-issues)

For more help, check the [Troubleshooting Guide](https://github.com/yourusername/quickshell-config/wiki/Troubleshooting) or open an issue.

---

## 🤝 Contributing

- 🐛 Report bugs via [Issues](https://github.com/yourusername/quickshell-config/issues)
- 💡 Suggest features on the [Discussions](https://github.com/yourusername/quickshell-config/discussions)
- 🔧 Submit PRs with clear descriptions

Please include your environment details (Hyprland/Quickshell/Qt versions) when reporting issues.

---

## 📄 License

See [LICENSE](LICENSE) file.

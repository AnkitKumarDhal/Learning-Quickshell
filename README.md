# Quickshell Shell Configuration

A modern, feature-rich shell configuration built with **Quickshell** for the **Hyprland** Wayland compositor. This project provides a beautiful and functional desktop experience with a top bar, popups, and various system utilities.

## Features

### 🎨 Top Bar
- **Left Module**: Arch Linux logo, window name display, workspace switcher
- **Center Module**: Media player controls, clock/date display, idle inhibitor toggle
- **Right Module**: Battery status, volume control, system tray, system monitor, network status, notification button

### 🔔 Popups & Panels
- **Notification Panel**: View and manage notifications
- **System Popup**: CPU, memory, disk, and network usage monitoring
- **Volume Popup**: Audio device selection and volume control
- **Network Popup**: Network connection management
- **Media Popup**: Media playback controls with album art
- **Launcher**: Application launcher with search functionality
- **Clipboard Popup**: Clipboard history manager
- **Notification Toast**: In-app notification previews

### ⚡ Keybindings
| Shortcut | Action |
|----------|--------|
| `SUPER + Z` | Toggle focus mode (hide bar in fullscreen) |
| `SUPER + (bar hide)` | Toggle bar visibility anytime |
| `SUPER + (launcher)` | Toggle application launcher |
| `SUPER + (clipboard)` | Toggle clipboard manager |

## Project Structure

```
qs/
├── shell.qml              # Main entry point
├── src/
│   ├── components/        # Reusable UI components
│   │   ├── PillBase.qml
│   │   ├── PopupPage.qml
│   │   ├── PopupSlide.qml
│   │   ├── TabBar.qml
│   │   └── TrayContextMenu.qml
│   ├── modules/           # Top bar modules
│   │   ├── Left/          # Left section modules
│   │   ├── Center/        # Center section modules
│   │   └── Right/         # Right section modules
│   ├── popups/            # Popup windows
│   │   ├── media/         # Media-related components
│   │   ├── launcher/      # Launcher components
│   │   ├── system/        # System monitor components
│   │   └── ...
│   ├── services/          # Backend services
│   │   ├── VolumeService.qml
│   │   ├── BatteryService.qml
│   │   ├── NotificationService.qml
│   │   ├── ClipboardService.qml
│   │   ├── NetworkService.qml
│   │   └── system/        # System monitoring services
│   ├── state/             # State management
│   │   ├── Popups.qml
│   │   └── ShellState.qml
│   ├── theme/             # Theme configuration
│   │   ├── Colors.json
│   │   ├── Colors.qml
│   │   ├── Fonts.qml
│   │   └── Theme.qml
│   └── windows/           # Window definitions
│       ├── TopBar.qml
│       └── PopupDismiss.qml
└── .gitignore
```

## Requirements

- **Wayland Compositor**: Hyprland
- **Quickshell**: Qt-based shell framework
- **Qt6**: Qt Quick and related modules

## Installation

1. Clone or copy this configuration to your Quickshell config directory:
   ```bash
   mkdir -p ~/.config/quickshell
   cp -r * ~/.config/quickshell/
   ```

2. Ensure you have the required dependencies installed.

3. Restart Quickshell or reload the configuration.

## Configuration

### Theme
The theme is configured in `src/theme/`:
- **Colors**: Defined in `Colors.json` (Material Design 3 color scheme)
- **Theme.qml**: Contains geometry, animation durations, and styling constants

### Keybindings
Configure keybindings in your Hyprland configuration to trigger Quickshell actions:
```ini
# Example Hyprland keybindings
bind = SUPER, Z, global, quickshell:focusModeToggle
bind = SUPER, B, global, quickshell:barHideToggle
bind = SUPER, SPACE, global, quickshell:launcherToggle
bind = SUPER, V, global, quickshell:clipboardToggle
```

## Customization

### Adding New Modules
1. Create a new QML file in the appropriate `src/modules/` subdirectory
2. Import and instantiate it in `src/windows/TopBar.qml`

### Modifying Colors
Edit `src/theme/Colors.json` to change the color scheme. The project uses a Material Design 3 inspired palette.

### Adjusting Animations
Modify animation durations in `src/theme/Theme.qml`:
- `animDuration`: General animation duration (default: 250ms)
- `slideInDuration`: Popup slide-in animation (default: 400ms)

## Services

The project includes several backend services:
- **VolumeService**: Audio control via PipeWire/PulseAudio
- **BatteryService**: Battery status monitoring
- **NotificationService**: Desktop notification handling
- **ClipboardService**: Clipboard history management
- **NetworkService**: Network connection monitoring
- **SystemStats**: CPU, memory, and disk usage monitoring

## License

This project is provided as-is for personal use. Feel free to modify and distribute as needed.

## Acknowledgments

- Built with [Quickshell](https://github.com/pop-os/quickshell)
- Designed for [Hyprland](https://hyprland.org/)
- Icons and assets from community resources

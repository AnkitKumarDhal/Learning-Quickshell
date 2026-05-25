# Quickshell Shell Configuration

A modern, modular shell configuration built with Quickshell for Hyprland Wayland compositor. Features a sleek top bar with dynamic modules, animated popups, and deep system integration.

## Resources

- [Quickshell Documentation](https://quickshell.io/)
- [Hyprland Lua Configuration](https://wiki.hyprland.org/Configuring/Using-lua/)
- [License](LICENSE)

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Complete File Structure](#complete-file-structure)
3. [Architecture and Data Flow](#architecture-and-data-flow)
4. [Module System](#module-system)
5. [Popup System](#popup-system)
6. [Service Layer](#service-layer)
7. [State Management](#state-management)
8. [Theme System](#theme-system)
9. [Keybindings](#keybindings)
10. [Installation](#installation)
11. [Configuration](#configuration)
12. [Component Interactions](#component-interactions)
13. [Known Issues](#known-issues)
14. [Roadmap](#roadmap)
15. [Contributing](#contributing)

---

## Project Overview

This Quickshell configuration provides a comprehensive desktop shell experience with:

- **Top Bar**: Three-module layout (Left, Center, Right) with dynamic content
- **Popups**: Animated overlays for notifications, media control, launcher, clipboard, and system settings
- **Services**: Background QML services for battery, network, volume, clipboard, and notifications
- **Theming**: Material Design 3 color system generated from wallpaper using Matugen
- **Animations**: Smooth transitions and slide effects for all UI elements

### Key Features

| Feature | Description | Location |
|---------|-------------|----------|
| Focus Mode | Auto-hides bar during fullscreen, manual toggle available | ShellState.qml |
| Application Launcher | Fuzzy-search application finder with results list | src/popups/Launcher.qml |
| Clipboard Manager | History-based clipboard with paste functionality | src/popups/ClipboardPopup.qml |
| Media Controls | Player controls with progress, volume, and track info | src/popups/MediaPopup.qml |
| Notification Panel | Toast notifications with stacking and dismiss actions | src/popups/NotificationPanel.qml |
| Network Popup | WiFi, Bluetooth, VPN, and Hotspot management tabs | src/popups/NetworkPopup.qml |
| System Monitor | Real-time CPU, memory, disk, and network usage graphs | src/popups/SystemPopup.qml |
| Volume Control | Per-application volume mixer with device selection | src/popups/VolumePopup.qml |

---

## Complete File Structure

```
/workspace/
├── LICENSE
├── README.md
├── shell.qml
└── src/
    ├── components/
    │   ├── PillBase.qml
    │   ├── PopupPage.qml
    │   ├── PopupSlide.qml
    │   ├── TabBar.qml
    │   └── TrayContextMenu.qml
    ├── modules/
    │   ├── Center/
    │   │   ├── ClockDate.qml
    │   │   ├── IdleInhibitor.qml
    │   │   └── Media.qml
    │   ├── Left/
    │   │   ├── ArchLogo.qml
    │   │   ├── WindowName.qml
    │   │   └── Workspaces.qml
    │   └── Right/
    │       ├── Battery.qml
    │       ├── Network.qml
    │       ├── NotificationButton.qml
    │       ├── SystemMonitor.qml
    │       ├── Tray.qml
    │       └── Volume.qml
    ├── popups/
    │   ├── launcher/
    │   │   ├── LauncherAppLoader.qml
    │   │   ├── LauncherResultItem.qml
    │   │   ├── LauncherResultsList.qml
    │   │   └── LauncherSearchBar.qml
    │   ├── media/
    │   │   ├── MediaArt.qml
    │   │   ├── MediaControls.qml
    │   │   ├── MediaProgress.qml
    │   │   ├── MediaTrackInfo.qml
    │   │   └── MediaVolumeRow.qml
    │   ├── system/
    │   │   ├── DiskBar.qml
    │   │   ├── NetworkGraph.qml
    │   │   └── Speedometer.qml
    │   ├── ClipboardPopup.qml
    │   ├── DeviceRow.qml
    │   ├── Launcher.qml
    │   ├── MediaPopup.qml
    │   ├── NetworkPopup.qml
    │   ├── NetworkRow.qml
    │   ├── NotificationPanel.qml
    │   ├── NotificationToast.qml
    │   ├── SystemPopup.qml
    │   ├── ToastItem.qml
    │   ├── VolumePopup.qml
    │   └── VolumeSlider.qml
    ├── services/
    │   ├── system/
    │   │   └── SystemStats.qml
    │   ├── BatteryService.qml
    │   ├── ClipboardService.qml
    │   ├── NetworkService.qml
    │   ├── NotificationService.qml
    │   └── VolumeService.qml
    ├── state/
    │   ├── Popups.qml
    │   └── ShellState.qml
    ├── theme/
    │   ├── Colors.json
    │   ├── Colors.qml
    │   ├── Fonts.qml
    │   ├── Theme.qml
    │   └── quickshell.json.hbs
    └── windows/
        ├── PopupDismiss.qml
        └── TopBar.qml
```

---

## Architecture and Data Flow

### High-Level Architecture

The shell follows a layered architecture pattern:

```
┌─────────────────────────────────────────────────────────────┐
│                      Entry Point                            │
│                       shell.qml                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Windows Layer                          │
│                    TopBar, PopupDismiss                     │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐         ┌─────────────────────────┐
│     Modules Layer       │         │      Popups Layer       │
│  Left, Center, Right    │         │  Launcher, Media, etc.  │
└─────────────────────────┘         └─────────────────────────┘
              │                               │
              └───────────────┬───────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Services Layer                          │
│    Battery, Network, Volume, Clipboard, Notification        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      State Layer                            │
│              ShellState.qml, Popups.qml                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Theme Layer                            │
│         Colors.json, Colors.qml, Fonts.qml, Theme.qml       │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow Patterns

#### 1. Service to Module Flow
```
[System Event] → [Service] → [Property Change] → [Module UI Update]
     │              │              │                    │
     ▼              ▼              ▼                    ▼
  DBus/Pipe    BatteryService   batteryLevel       Battery.qml
               NetworkService   connectionStatus   Network.qml
               VolumeService    currentVolume      Volume.qml
```

#### 2. User Input to Action Flow
```
[User Click] → [Module/Popup] → [State Change] → [Popup Visibility]
     │              │                │                  │
     ▼              ▼                ▼                  ▼
  Mouse Event    Network.qml    networkOpen=true    NetworkPopup.qml
```

#### 3. Theme Application Flow
```
[Matugen Generate] → [Colors.json] → [Colors.qml] → [All Components]
        │                │               │               │
        ▼                ▼               ▼               ▼
   Wallpaper       JSON File      Qt Singleton    Color Properties
```

---

## Module System

Modules are the building blocks of the top bar, organized into three sections: Left, Center, and Right.

### Left Module Files

| File | Purpose | Dependencies | Properties Exposed |
|------|---------|--------------|-------------------|
| `src/modules/Left/ArchLogo.qml` | Arch Linux logo with context menu popup | Popups.qml, TrayContextMenu.qml | archMenuOpen state |
| `src/modules/Left/WindowName.qml` | Displays active window title | Hyprland IPC | windowTitle property |
| `src/modules/Left/Workspaces.qml` | Workspace switcher buttons | Hyprland IPC | workspaceList array |

### Center Module Files

| File | Purpose | Dependencies | Properties Exposed |
|------|---------|--------------|-------------------|
| `src/modules/Center/ClockDate.qml` | Current time and date display | QtQuick.Time | currentTime, currentDate |
| `src/modules/Center/IdleInhibitor.qml` | Toggle for preventing idle/sleep | PowerManagement DBus | inhibitorActive boolean |
| `src/modules/Center/Media.qml` | Now playing indicator | MediaService, Popups.qml | currentTrack, isPlaying |

### Right Module Files

| File | Purpose | Dependencies | Properties Exposed |
|------|---------|--------------|-------------------|
| `src/modules/Right/Battery.qml` | Battery level and charging status | BatteryService | batteryPercent, isCharging |
| `src/modules/Right/Network.qml` | Network connectivity icons | NetworkService | wifiStatus, bluetoothStatus |
| `src/modules/Right/NotificationButton.qml` | Notification count and panel toggle | NotificationService, Popups.qml | notificationCount |
| `src/modules/Right/SystemMonitor.qml` | Mini CPU/memory usage indicator | SystemStats | cpuUsage, memoryUsage |
| `src/modules/Right/Tray.qml` | System tray icons with context menus | StatusNotifierWatcher | trayItems array |
| `src/modules/Right/Volume.qml` | Volume level indicator | VolumeService | volumeLevel, isMuted |

---

## Popup System

Popups are overlay windows that appear on user interaction or system events.

### Popup Files and Responsibilities

| File | Type | Trigger | Animation | Parent Component |
|------|------|---------|-----------|------------------|
| `src/popups/Launcher.qml` | Application search | SUPER+Space | Slide from center | shell.qml Variants |
| `src/popups/ClipboardPopup.qml` | Clipboard history | SUPER+V | Slide from top | shell.qml Variants |
| `src/popups/MediaPopup.qml` | Media player controls | Click center media module | Slide from top-right | shell.qml Variants |
| `src/popups/NetworkPopup.qml` | Network settings | Click network icon | Slide from top-right | shell.qml Variants |
| `src/popups/VolumePopup.qml` | Volume mixer | Click volume icon | Slide from top-right | shell.qml Variants |
| `src/popups/SystemPopup.qml` | System monitor details | Click system monitor | Slide from top-right | shell.qml Variants |
| `src/popups/NotificationPanel.qml` | Notification center | Click notification button | Slide from top-right | shell.qml Variants |
| `src/popups/NotificationToast.qml` | Toast notifications | New notification | Slide in from edge | shell.qml Variants |

### Popup Helper Components

| File | Purpose | Used By |
|------|---------|---------|
| `src/components/PopupPage.qml` | Base page wrapper with padding and background | All popups |
| `src/components/PopupSlide.qml` | Slide animation controller | Launcher, ClipboardPopup |
| `src/components/TabBar.qml` | Tab navigation bar | NetworkPopup |
| `src/components/PillBase.qml` | Rounded container style | Multiple popups |

### Popup Sub-Components

#### Launcher Sub-Components
| File | Purpose |
|------|---------|
| `src/popups/launcher/LauncherAppLoader.qml` | Loads and filters application list |
| `src/popups/launcher/LauncherSearchBar.qml` | Search input field |
| `src/popups/launcher/LauncherResultsList.qml` | Scrollable results container |
| `src/popups/launcher/LauncherResultItem.qml` | Individual result row |

#### Media Popup Sub-Components
| File | Purpose |
|------|---------|
| `src/popups/media/MediaArt.qml` | Album artwork display |
| `src/popups/media/MediaControls.qml` | Play/pause/skip buttons |
| `src/popups/media/MediaProgress.qml` | Progress bar with seek |
| `src/popups/media/MediaTrackInfo.qml` | Track title and artist |
| `src/popups/media/MediaVolumeRow.qml` | Per-app volume slider |

#### System Popup Sub-Components
| File | Purpose |
|------|---------|
| `src/popups/system/DiskBar.qml` | Disk usage visualization |
| `src/popups/system/NetworkGraph.qml` | Network traffic graph |
| `src/popups/system/Speedometer.qml` | CPU speed indicator |

#### Notification Sub-Components
| File | Purpose |
|------|---------|
| `src/popups/ToastItem.qml` | Individual toast notification |
| `src/popups/DeviceRow.qml` | Network device list item |
| `src/popups/NetworkRow.qml` | WiFi network list item |
| `src/popups/VolumeSlider.qml` | Custom volume slider control |

---

## Service Layer

Services run in the background, monitoring system state and exposing properties to QML components.

### Service Files

| File | Monitors | DBus Interface | Update Frequency |
|------|----------|----------------|------------------|
| `src/services/BatteryService.qml` | Battery level, charging state, power profile | org.freedesktop.UPower | Event-driven |
| `src/services/ClipboardService.qml` | Clipboard history, paste operations | wlroots-data-control | Event-driven |
| `src/services/NetworkService.qml` | WiFi, Bluetooth, VPN, hotspot status | org.freedesktop.NetworkManager | Event-driven |
| `src/services/NotificationService.qml` | Incoming notifications, dismissal | org.freedesktop.Notifications | Event-driven |
| `src/services/VolumeService.qml` | Audio sinks, sources, volume levels | org.pulseaudio.Server | Event-driven |
| `src/services/system/SystemStats.qml` | CPU, memory, disk, network statistics | /proc filesystem | 1 second interval |

### Service Properties and Methods

#### BatteryService
| Property | Type | Description |
|----------|------|-------------|
| `batteryPercent` | real | Current battery percentage (0-100) |
| `isCharging` | bool | Charging state |
| `timeToEmpty` | int | Estimated minutes until empty |
| `timeToFull` | int | Estimated minutes until full |

#### ClipboardService
| Property | Type | Description |
|----------|------|-------------|
| `history` | var | Array of clipboard entries |
| `maxItems` | int | Maximum history size |

| Method | Parameters | Returns |
|--------|------------|---------|
| `addToHistory` | text: string | void |
| `clearHistory` | none | void |
| `pasteItem` | index: int | void |

#### NetworkService
| Property | Type | Description |
|----------|------|-------------|
| `wifiEnabled` | bool | WiFi adapter state |
| `wifiConnected` | bool | WiFi connection state |
| `bluetoothEnabled` | bool | Bluetooth adapter state |
| `activeConnections` | var | List of active connections |

| Method | Parameters | Returns |
|--------|------------|---------|
| `toggleWifi` | none | void |
| `toggleBluetooth` | none | void |
| `getNetworks` | none | array |
| `connectToNetwork` | ssid: string, password: string | void |

#### NotificationService
| Property | Type | Description |
|----------|------|-------------|
| `notifications` | var | Array of active notifications |
| `dndMode` | bool | Do Not Disturb state |

| Method | Parameters | Returns |
|--------|------------|---------|
| `sendNotification` | summary, body, urgency | uint (id) |
| `dismissNotification` | id: uint | void |
| `clearAll` | none | void |

#### VolumeService
| Property | Type | Description |
|----------|------|-------------|
| `defaultSink` | object | Default output device |
| `defaultSource` | object | Default input device |
| `sinkInputs` | var | Per-application volumes |

| Method | Parameters | Returns |
|--------|------------|---------|
| `setVolume` | value: real | void |
| `toggleMute` | none | void |
| `setAppVolume` | index: int, value: real | void |

---

## State Management

State is managed through two singleton QML files that serve as the central source of truth for shell behavior.

### ShellState.qml

Manages global shell state including focus mode and bar visibility.

| Property | Type | Description |
|----------|------|-------------|
| `topBarLWidth` | int | Width of left bar section (written by TopBar) |
| `topBarCWidth` | int | Width of center bar section |
| `topBarRWidth` | int | Width of right bar section |
| `focusMode` | bool | Computed: true when bar should collapse |
| `_isFullscreen` | bool | Internal: fullscreen window detected |
| `_manualHide` | bool | Internal: user toggled hide via keybind |
| `_manualOverride` | bool | Internal: override auto-hide in fullscreen |

| Function | Parameters | Description |
|----------|------------|-------------|
| `toggleManualOverride` | none | Toggles bar visibility in fullscreen mode |
| `toggleManualHide` | none | Toggles bar visibility anytime |

### Popups.qml

Manages visibility state for all popups.

| Property | Type | Description |
|----------|------|-------------|
| `notificationsOpen` | bool | Notification panel visibility |
| `systemOpen` | bool | System monitor popup visibility |
| `archMenuOpen` | bool | Arch logo context menu visibility |
| `calendarOpen` | bool | Calendar popup visibility |
| `mediaOpen` | bool | Media player popup visibility |
| `idleInhibitorOpen` | bool | Idle inhibitor popup visibility |
| `volumeOpen` | bool | Volume popup visibility |
| `launcherOpen` | bool | Application launcher visibility |
| `clipboardOpen` | bool | Clipboard manager visibility |
| `networkOpen` | bool | Network popup visibility |
| `networkTab` | int | Active tab in network popup (0=WiFi, 1=Bluetooth, 2=VPN, 3=Hotspot) |
| `anyOpen` | bool | Computed: true if any popup is open |

| Function | Parameters | Description |
|----------|------------|-------------|
| `closeAll` | none | Closes all open popups |

---

## Theme System

The theme system uses Material Design 3 color tokens generated from the user's wallpaper using Matugen.

### Theme Files

| File | Purpose | Format |
|------|---------|--------|
| `src/theme/quickshell.json.hbs` | Handlebars template for Matugen color generation | HBS |
| `src/theme/Colors.json` | Generated color values (user must generate) | JSON |
| `src/theme/Colors.qml` | QML singleton exposing colors to components | QML |
| `src/theme/Fonts.qml` | Font family definitions | QML |
| `src/theme/Theme.qml` | Master theme aggregator | QML |

### Matugen Configuration

To generate the `Colors.json` file from your wallpaper, add the following to your Matugen configuration file (typically `~/.config/matugen/config.toml`):

```toml
[templates.quickshell]
input_path  = "~/.config/quickshell/src/theme/quickshell.json.hbs"
output_path = "~/.config/quickshell/src/theme/Colors.json"
```

Then run Matugen with your wallpaper:
```bash
matugen image /path/to/wallpaper.jpg
```

This will process the wallpaper, extract dominant colors, apply Material Design 3 color algorithms, and output the generated `Colors.json` file.

### Available Color Tokens

The following color tokens are available after generation:

| Token | Description | Usage |
|-------|-------------|-------|
| `background` | Main background color | Panel backgrounds |
| `on_background` | Text on background | Primary text |
| `primary` | Primary accent color | Buttons, highlights |
| `on_primary` | Text on primary | Button text |
| `primary_container` | Container variant of primary | Card backgrounds |
| `secondary` | Secondary accent | Secondary elements |
| `tertiary` | Tertiary accent | Decorative elements |
| `error` | Error state color | Error messages |
| `surface` | Surface elevation color | Elevated panels |
| `surface_variant` | Alternative surface | Alternate panels |
| `outline` | Border color | Dividers, borders |
| `inverse_surface` | Inverted surface | High contrast areas |

### Using Colors in Components

```qml
import qs.src.theme

Rectangle {
    color: Colors.background
    border.color: Colors.outline
    
    Text {
        color: Colors.on_background
        font.family: Fonts.sans
    }
}
```

---

## Keybindings

Keybindings are defined in `shell.qml` using Quickshell's GlobalShortcut component with Hyprland IPC integration.

### Active Keybindings

| Key Combination | Action | Handler | Description |
|-----------------|--------|---------|-------------|
| `SUPER + X` | Toggle bar visibility | `ShellState.toggleManualHide()` | Shows/hides the top bar |
| `SUPER + Space` | Toggle application launcher | `Popups.launcherOpen = !Popups.launcherOpen` | Opens/closes app launcher |
| `SUPER + V` | Toggle clipboard manager | `Popups.clipboardOpen = !Popups.clipboardOpen` | Opens/closes clipboard history |

### Hyprland Lua Configuration

To enable these keybindings in Hyprland, add the following to your Lua configuration file (typically `~/.config/hypr/hyprland.lua` or similar):

```lua
local hl = require("hyprland")

-- Define modifier key
local mainMod = "SUPER"

-- Quickshell keybindings
hl.bind(mainMod .. " + X", hl.dsp.global("quickshell:barHideToggle"))
hl.bind(mainMod .. " + SPACE", hl.dsp.global("quickshell:launcherToggle"))
hl.bind(mainMod .. " + V", hl.dsp.global("quickshell:clipboardToggle"))
```

### Adding Custom Keybindings

To add a new keybinding:

1. Add a new `GlobalShortcut` block in `shell.qml`:
```qml
GlobalShortcut {
    appid:       "quickshell"
    name:        "yourActionName"
    description: "Description of action"
    onPressed:   // Your handler code
}
```

2. Add corresponding binding in Hyprland Lua config:
```lua
hl.bind(mainMod .. " + KEY", hl.dsp.global("quickshell:yourActionName"))
```

---

## Installation

### Prerequisites

| Dependency | Minimum Version | Purpose |
|------------|-----------------|---------|
| Hyprland | 0.40.0 | Wayland compositor |
| Quickshell | 0.6.0 | Shell framework |
| Qt6 | 6.6.0 | UI toolkit |
| Matugen | 0.10.0 | Color generation |
| Node.js | 18.0.0 | Build tools (optional) |

### Installation Steps

1. **Clone or copy the configuration**:
```bash
mkdir -p ~/.config/quickshell
cp -r /path/to/this/repo/* ~/.config/quickshell/
```

2. **Install dependencies**:
```bash
# Arch Linux
sudo pacman -S hyprland qt6-base qt6-declarative nodejs

# Install Quickshell (from AUR or build from source)
yay -S quickshell

# Install Matugen (from AUR)
yay -S matugen
```

3. **Configure Matugen**:
Add the template configuration to your Matugen config as described in the [Theme System](#theme-system) section.

4. **Generate colors**:
```bash
matugen image /path/to/your/wallpaper.jpg
```

5. **Configure Hyprland**:
Add the keybindings from the [Keybindings](#keybindings) section to your Hyprland configuration.

6. **Start Quickshell**:
Add to your Hyprland config or start manually:
```bash
quickshell &
```

---

## Configuration

### User Configuration Files

| File | Location | Purpose |
|------|----------|---------|
| Colors.json | `~/.config/quickshell/src/theme/Colors.json` | Generated color values |
| Hyprland Lua | `~/.config/hypr/hyprland.lua` | Keybindings |
| Matugen Config | `~/.config/matugen/config.toml` | Template paths |

### Customization Options

#### Changing Wallpaper and Regenerating Colors
```bash
matugen image /new/wallpaper/path.jpg
# Quickshell will automatically reload Colors.json
```

#### Adjusting Popup Behavior
Edit `src/state/Popups.qml` to modify:
- Default open/close states
- Aggregate `anyOpen` logic
- Custom popup state properties

#### Modifying Bar Behavior
Edit `src/state/ShellState.qml` to adjust:
- Fullscreen detection sensitivity
- Focus mode conditions
- Manual override behavior

---

## Component Interactions

### How Files Work Together

#### TopBar Integration
`shell.qml` instantiates `TopBar.qml` for each screen. `TopBar.qml` contains three module containers (Left, Center, Right) and reports their widths back to `ShellState.qml` for proper popup positioning.

```
shell.qml (creates per-screen scope)
    │
    ├─→ TopBar.qml (renders bar)
    │       │
    │       ├─→ Left modules (ArchLogo, WindowName, Workspaces)
    │       ├─→ Center modules (ClockDate, IdleInhibitor, Media)
    │       └─→ Right modules (Battery, Network, NotificationButton, SystemMonitor, Tray, Volume)
    │
    └─→ Writes widths to ShellState.topBarLWidth, topBarCWidth, topBarRWidth
```

#### Popup Lifecycle

1. **Instantiation**: All popups are created once in `shell.qml` within the `Variants` delegate for each screen.
2. **Visibility Control**: Popup visibility is controlled by boolean properties in `Popups.qml`.
3. **Dismissal**: `PopupDismiss.qml` creates an invisible overlay that captures clicks outside popups to close them.
4. **Animation**: `PopupSlide.qml` and `PopupPage.qml` handle entrance/exit animations.

```
User presses SUPER+Space
    │
    ├─→ GlobalShortcut.onPressed fires
    │
    ├─→ Popups.launcherOpen toggles
    │
    ├─→ Launcher.qml opacity/visible binding updates
    │
    ├─→ PopupSlide.qml animates position
    │
    └─→ PopupDismiss.qml becomes active (captures outside clicks)
```

#### Service-to-UI Data Flow

```
System DBus Event (e.g., volume change)
    │
    ├─→ VolumeService.qml receives signal
    │
    ├─→ volumeLevel property updates
    │
    ├─→ Volume.qml (module) updates slider position
    │
    ├─→ VolumePopup.qml updates mixer sliders
    │
    └─→ Visual feedback to user
```

#### Theme Propagation

```
Matugen generates Colors.json
    │
    ├─→ Colors.qml reads JSON file on startup
    │
    ├─→ Colors singleton exposes properties (Colors.background, etc.)
    │
    ├─→ All components import Colors.qml
    │
    └─→ UI updates with new colors (requires restart or hotreload)
```

---

## Known Issues

The following issues are currently present in the shell configuration:

### 1. Notification Toast Animation and Stacking

**Issue**: Toast notifications exhibit janky animation behavior, and the stacking order is inverted. Newest notifications appear at the bottom of the stack instead of at the top, requiring users to scroll down to see the most recent notifications.

**Expected Behavior**: Newest notifications should appear at the top of the stack with smooth entrance animations, pushing older notifications downward.

**Affected Files**: 
- `src/popups/NotificationToast.qml`
- `src/popups/ToastItem.qml`
- `src/services/NotificationService.qml`

**Priority**: Medium

---

### 2. Clipboard Manager Keyboard Focus Conflict

**Issue**: Opening the clipboard manager even once causes the application launcher to lose keyboard focus capture. After the clipboard has been opened, the launcher will not receive keyboard input unless the mouse is moved in any direction, which then restores focus.

**Expected Behavior**: The application launcher should always capture keyboard focus immediately upon opening, regardless of whether the clipboard manager has been used.

**Affected Files**:
- `src/popups/ClipboardPopup.qml`
- `src/popups/Launcher.qml`
- `src/state/Popups.qml`

**Priority**: High

---

### 3. YouTube Music (Pear Desktop) Volume Slider

**Issue**: When using the YouTube Music application via Pear Desktop, the volume slider in the media player popup does not respond to adjustments. This issue has not been tested against Spotify, but volume control works correctly for browser-based media players and phone audio via KDE Connect.

**Expected Behavior**: The volume slider should control playback volume for all MPRIS-compatible media players, including Pear Desktop applications.

**Affected Files**:
- `src/popups/MediaPopup.qml`
- `src/popups/media/MediaVolumeRow.qml`
- `src/services/VolumeService.qml`

**Priority**: Low

---

## Roadmap

The following features and improvements are planned for future development:

- [ ] **User Panel Popup**: Create a user profile panel popup triggered by clicking the Arch logo in the left module, displaying user information, session options, and quick settings.

- [ ] **Visual Workspace Switcher**: Enhance the workspace module with visual indicators showing window distribution across workspaces, workspace names, and smooth transition animations.

- [ ] **Calendar and Productivity Suite**: Expand the clock/calendar module with a comprehensive popup containing:
  - Full calendar view with event display
  - Pomodoro timer with configurable intervals and normal mode option
  - Focus mode toggle with customizable duration
  - Task history and completion statistics
  - Integrated planner with note-taking capability

- [ ] **Enhanced Media Player**: Redesign the media player popup with:
  - Sleeker, more modern visual design
  - Improved entrance and transition animations
  - Optional lyrics display (synchronized with playback)
  - Better handling of multiple simultaneous players

- [ ] **Idle Inhibitor Popup**: Create a dedicated popup for the idle inhibitor module with visual feedback, timer display, and customizable inhibition rules.

- [ ] **Unified Connectivity Module**: Merge Bluetooth, WiFi, brightness, and battery modules into a single cohesive module:
  - WiFi icon click opens network popup on WiFi tab
  - Bluetooth icon click opens network popup on Bluetooth tab
  - Brightness icon click reveals slider with resolution and refresh rate options
  - Battery icon click opens enhanced battery popup (see below)
  - Maintain separate tabs for Hotspot and VPN functionality

- [ ] **Advanced Battery Management**: Enhance the battery module with:
  - Power profile selection (performance, balanced, power-saver)
  - Accurate estimated time remaining calculation
  - Real-time charging wattage display
  - Historical usage statistics and graphs
  - Battery health monitoring

- [ ] **Custom Tray Context Menus**: Implement fully customized context menus for system tray icons, replacing default renderer with styled QML components matching the shell aesthetic.

- [ ] **Emoji Picker Popup**: Develop an emoji picker popup similar to the clipboard manager, featuring:
  - Category-based organization
  - Search functionality
  - Recently used tracking
  - Quick insert capability

- [ ] **Wallpaper and Theme Manager**: Create a GUI wallpaper selector that:
  - Displays available wallpapers in a grid
  - Automatically triggers Matugen color generation on selection
  - Supports Pywal integration for terminal themes
  - Provides preview of generated color scheme
  - Manages wallpaper history and favorites

- [ ] **GUI Settings Manager**: Build a comprehensive graphical settings interface for users uncomfortable with manual configuration file editing:
  - Visual keybinding editor
  - Theme customization panel
  - Module enable/disable toggles
  - Popup behavior configuration
  - Import/export settings functionality

---

## Contributing

### Reporting Issues

When reporting issues, please include:

1. **Environment Details**:
   - Hyprland version
   - Quickshell version
   - Qt6 version
   - Distribution and version

2. **Steps to Reproduce**: Clear, numbered steps to reproduce the issue.

3. **Expected vs Actual Behavior**: Describe what should happen and what actually happens.

4. **Screenshots/Logs**: Include relevant screenshots or log output when applicable.

5. **Affected Components**: Identify which files or modules appear to be involved.

### Submitting Suggestions

New feature suggestions and improvement ideas are welcome. Please submit suggestions via the project's issue tracker with the following information:

- Feature description and use case
- Proposed implementation approach (if known)
- Priority assessment (nice-to-have vs essential)
- Potential impact on existing functionality

### Code Contributions

Before submitting code contributions:

1. Ensure code follows existing style conventions (2-space indentation, camelCase naming)
2. Test changes thoroughly in your environment
3. Update documentation if adding new features
4. Submit pull requests with clear descriptions of changes

### Community Engagement

Users are strongly encouraged to:
- Report bugs and unexpected behavior
- Suggest new features and improvements
- Share custom themes and configurations
- Help other users with troubleshooting

Your feedback helps improve the shell for everyone. No suggestion is too small, and all issues deserve attention.

---

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.

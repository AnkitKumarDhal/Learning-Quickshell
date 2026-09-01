# Quickshell Shell Configuration

A modern, modular shell configuration built with Quickshell for the Hyprland Wayland compositor. It provides a polished top bar, system controls, application launcher, clipboard manager, wallpaper selector, notifications, media controls, and other desktop utilities while keeping the configuration modular and easy to customize.

## Resources

* [Quickshell Documentation](https://quickshell.org/docs/v0.3.0/types/)
* [Hyprland Wiki](https://wiki.hypr.land/)
* [License](LICENSE)

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Installation](#installation)
3. [Known Issues](#known-issues)
4. [Core Components](#core-components)
5. [Keybindings](#keybindings)
6. [Configuration](#configuration)
7. [Roadmap](#roadmap)
8. [Contributing](#contributing)

---

## Project Overview

Velox-Q is a modular Quickshell configuration designed primarily for Hyprland and Wayland.

The configuration is split into independent modules, popups, services, state, and theme components so that individual parts of the shell can be developed and customized without turning the entire configuration into one large file.

### Key Features

#### Desktop Shell

* Modular top bar divided into Left, Center, and Right sections
* Hyprland workspace integration
* Current time and date
* Active media information
* System tray integration
* Notification indicator
* Battery status
* Network status
* Volume status
* Compact system monitoring
* Multi-monitor support
* Animated popup system
* Dynamic Material-style theming through Matugen

#### System Controls

* Battery status and charging information
* Battery time remaining
* Performance profile selection
* Charging mode selection
* Display refresh-rate selection
* WiFi management and scanning
* Bluetooth integration
* Brightness controls
* PipeWire audio controls
* Input and output volume control
* Caffeine / idle inhibition
* Session management
* Polkit authentication interface

#### Application Launcher

* Fuzzy application search
* Exact, prefix, substring, acronym, keyword, comment, and category matching
* Persistent pinned applications
* Persistent recent applications
* Quick-access section
* Application action menu
* Existing-window detection
* Existing-window focusing
* Keyboard-driven navigation
* Direct command execution using `>`
* Web search using `?`
* Google search using `!g`
* Startpage search using `!s`
* Built-in calculator
* Unit conversion
* Currency conversion as an optional online feature

#### Clipboard Manager

* Persistent clipboard history
* Searchable clipboard entries
* Text, image, link, and code classification
* Category filtering
* Pinned clipboard entries
* Usage tracking
* Relative recency information
* Image previews
* Cached clipboard images
* Full-text clipboard search
* Individual entry deletion
* Full history clearing with confirmation
* Keyboard-first interaction

#### Wallpaper Selector

* Dedicated graphical wallpaper picker
* Wallpaper directory selection
* Wallpaper scanning and rescanning
* Thumbnail previews
* Carousel-based browsing
* Current wallpaper detection
* Wallpaper metadata display
* Keyboard navigation
* Apply and re-apply controls
* Matugen integration for dynamic theme generation

#### Additional Utilities

* Categorized emoji picker
* Emoji search
* Calendar popup
* Graphical keybind viewer
* Notification panel
* Notification toasts
* Custom system-tray menus
* Nested tray menu support
* Detailed system monitor

### Project Evolution

Velox-Q started as a relatively small Quickshell configuration centered around a top bar and a handful of basic popups and services.

Since the original v1 implementation, the project has progressively been rebuilt into a much more complete desktop shell.

The major stages of that development include:

#### Initial Shell

* Three-part top bar
* Workspace management
* Clock and date
* Media indicator
* Battery indicator
* Network indicator
* Volume indicator
* Notification indicator
* Basic system monitoring
* Initial launcher
* Initial clipboard manager
* Initial network, media, volume, and system popups
* Initial notification system
* Matugen-based theme system

#### Shell and Popup Architecture

* Shared popup components
* Central popup state management
* Popup loading infrastructure
* Popup dismissal handling
* Reusable slide animations
* Per-screen popup instances
* Popup mutual exclusion
* Additional dedicated popup windows
* More consistent theme and animation handling

#### System Integration Expansion

* Dedicated battery service
* Bluetooth service
* Brightness service
* Caffeine service
* Session service
* Polkit service
* Keybind service
* Expanded system statistics
* PipeWire-based audio integration
* More complete network integration

#### System Monitor Revamp

* Expanded CPU monitoring
* Memory and swap information
* GPU monitoring
* VRAM monitoring
* GPU temperature
* Disk and partition information
* Network throughput
* Network history graphs
* Thermal sensor information
* Dedicated detailed system popup

#### Battery Revamp

* Dedicated battery popup
* Battery time estimation
* Charging status improvements
* Performance profiles
* Charging profiles
* 80% charge conservation mode
* Full-charge mode
* Refresh-rate controls
* Improved low-battery feedback
* Better separation between battery UI and system logic

#### Media and Notification Improvements

* Dedicated media controls popup
* Richer media information
* Media progress and controls
* Dedicated media subcomponents
* Notification panel
* Notification toast system
* Dismissal handling
* Centralized notification state

#### System Tray Revamp

* Dedicated tray component
* Custom context menus
* Nested menu support
* Improved menu handling
* Shared styling with the rest of the shell

#### Emoji Picker

* Dedicated emoji picker popup
* Category navigation
* Emoji grid
* Search interface
* Generated emoji search data
* Dedicated utility for generating search data

#### Wallpaper Revamp

* Complete graphical wallpaper selector
* Dedicated wallpaper model
* Directory management
* Wallpaper scanning
* Thumbnail-based browsing
* Carousel interface
* Current-wallpaper detection
* Metadata display
* Dedicated controls
* Improved separation between wallpaper logic and UI

#### Launcher Revamp

* Fuzzy ranking overhaul
* Persistent pinned applications
* Persistent recent applications
* Quick access
* Application actions
* Existing-window focus
* Better keyboard navigation
* Command execution
* Web search
* Google search
* Startpage search
* Calculator
* Unit conversion
* Currency conversion
* Dedicated launcher subcomponents and services

#### Clipboard Revamp

* Search and filtering
* Clipboard categories
* Image detection
* Image preview caching
* Full-text search
* Pinned entries
* Usage tracking
* Recency information
* Individual deletion
* Full-history wipe
* Confirmation UI
* Improved keyboard selection and Enter-to-copy behavior

#### Codebase Cleanup

* More modular QML organization
* Smaller feature-specific components
* Dedicated singleton services
* Reduced duplication
* Cleaner popup structure
* More consistent formatting
* Improved separation between presentation and system logic
* Additional performance-focused cleanup throughout the configuration

---

## Installation

### Prerequisites

Velox-Q is primarily intended for an Arch Linux + Hyprland environment.

The installer handles the core packages required by Velox-Q, along with the AUR packages and native helper build required by the current shell.

Some optional features may rely on additional system services or applications already present on the system.

### Core Dependencies

| Dependency      | Purpose                       |
| --------------- | ----------------------------- |
| `git`           | Repository management         |
| `rust`          | Native helper builds          |
| Hyprland        | Wayland compositor            |
| Quickshell-git  | Shell framework               |
| Qt6             | UI framework                  |
| Matugen         | Dynamic color generation      |
| PipeWire        | Audio                         |
| WirePlumber     | PipeWire session management   |
| `cliphist`      | Clipboard history             |
| `wl-clipboard`  | Clipboard integration         |
| `brightnessctl` | Brightness management         |
| `awww`          | Wallpaper application         |
| `pywal16`       | Wallpaper and color support   |
| `imagemagick`   | Wallpaper metadata and thumbnails|

Depending on the features you use, additional system packages or services may be required for:

* Bluetooth
* Session management
* Polkit authentication
* Hardware monitoring

Power and battery management is handled separately by the installer when a battery is detected.

### Install

The installer is the recommended way to install Velox-Q.

#### Installer

Run:

```bash
curl -fsSL https://raw.githubusercontent.com/AnkitKumarDhal/Velox-Q/refs/heads/main/install.sh | bash
```

The installer will:

* Install required system packages
* Install or bootstrap an AUR helper when necessary
* Install the required AUR packages
* Verify the wallpaper backend dependencies
* Install Velox-Q into `~/.config/quickshell`
* Back up an existing non-Velox-Q configuration to `~/.config/quickshell.bak`
* Update an existing Velox-Q installation in place
* Build the native Velox-Q battery backend
* Detect battery and power-management capabilities
* Configure TLP and `tlp-pd` when appropriate
* Configure the required Velox-Q sudoers permissions when TLP charging control is available

The installer does not install or configure power-management software on systems without a battery.

#### Updating

Running the same installer command again will update an existing Velox-Q installation in place.

When the repository is already up to date, the installer avoids rebuilding the native battery backend unnecessarily.

The installer will stop if the existing Velox-Q installation contains local Git changes. Commit or stash those changes before updating.

When `~/.config/quickshell` exists but is not recognized as a Velox-Q Git installation, the installer preserves it by moving it to:

```text
~/.config/quickshell.bak
```

If that backup path already exists, a timestamped backup path is created instead.

#### Power Management

Power-management setup is performed only when a battery is detected.

The installer respects an already-active power-management backend.

The current selection behavior is:

```text
TLP active
    → use TLP and ensure tlp-pd is available

power-profiles-daemon active
    → leave the existing backend unchanged

TLP installed but inactive
    → enable TLP and tlp-pd

power-profiles-daemon installed but inactive
    → enable power-profiles-daemon

neither installed
    → install TLP and tlp-pd
```

Systems without a battery skip this setup entirely.

#### TLP Charging Privileges

When TLP is active and a battery exposes the supported `charge_types` interface, the installer creates:

```text
/etc/sudoers.d/velox-q
```

The generated rule is restricted to the charging operations required by Velox-Q.

The sudoers configuration is validated with `visudo` before it is installed.

The installer manages only `/etc/sudoers.d/velox-q`; unrelated sudoers configuration is not modified.

#### Manual Installation

The installer is the recommended installation method.

Manual installation is mainly intended for users who want to inspect or modify the configuration themselves.

1. Clone the repository:

```bash
git clone https://github.com/AnkitKumarDhal/Velox-Q.git
```

2. Copy the configuration into your Quickshell directory:

```bash
mkdir -p ~/.config/quickshell
cp -r Velox-Q/* ~/.config/quickshell/
```

3. Install the main dependencies on Arch Linux:

```bash
sudo pacman -S git rust hyprland qt6-base qt6-declarative pipewire wireplumber wl-clipboard cliphist imagemagick brightnessctl awww
```

4. Install the required AUR packages:

```bash
yay -S quickshell-git matugen-bin python-pywal16
```

5. Build the native battery backend:

```bash
cd ~/.config/quickshell/tools/battery/velox-battery
cargo build --release
mkdir -p ../bin
install -m 755 target/release/velox-battery ../bin/velox-battery
```

6. Start the shell:

```bash
quickshell
```

7. Add the Quickshell template to your Matugen configuration:

```toml
[templates.quickshell]
input_path  = "~/.config/quickshell/src/theme/quickshell.json.hbs"
output_path = "~/.config/quickshell/src/theme/Colors.json"
```

8. Generate the colors from your wallpaper:

```bash
matugen image /path/to/wallpaper.jpg
```

9. Add Quickshell to your Hyprland startup configuration:

```hyprlang
exec-once = quickshell
```

Or, when using the Lua version of Hyprland:

```lua
hl.exec_cmd("quickshell")
```

The exact configuration syntax may differ depending on how your Hyprland configuration is structured.

---

## Known Issues

* Fullscreen-aware bar visibility can still depend on Hyprland's fullscreen state reporting and the compositor configuration.

* Notification toast animation and stacking may require additional visual tuning, especially when several notifications arrive in rapid succession.

* Currency conversion requires network access when a cached exchange rate is unavailable. This is an optional (turned on by default) online feature rather than a required shell dependency.

---

## Core Components

### Module System

The top bar is divided into three module groups.

#### Left

* Arch Linux entry
* System monitor
* Workspace switcher

#### Center

* Clock and date
* Idle inhibition
* Media indicator

#### Right

* Battery
* Network
* Notifications
* System tray
* Volume

The modules are intentionally kept focused on presentation and interaction, with system-level functionality handled by the service layer.

### Popup System

The shell provides dedicated popups for the major interactive features.

* Application launcher
* Clipboard manager
* Emoji picker
* Wallpaper selector
* Media controls
* Network controls
* Volume controls
* System monitor
* Battery controls
* Calendar
* Caffeine
* Session manager
* Keybind viewer
* Polkit authentication
* Notifications

Shared popup components provide consistent animation, layout, dismissal, and styling.

### Service System

Services handle the system-facing and persistent parts of the shell.

* Battery
* Bluetooth
* Brightness
* Caffeine
* Clipboard
* Keybinds
* Launcher
* Unit and currency conversion
* Media
* Network
* Notifications
* Polkit
* Session
* Volume
* CPU
* Memory
* GPU
* Disk
* Network statistics
* Thermal statistics

This keeps system interaction separate from the visual QML components.

### State Management

Global shell state is centralized in two main singleton files.

#### `ShellState.qml`

Handles:

* Bar visibility
* Fullscreen behavior
* Manual hide/show behavior
* Fullscreen visibility override
* Top-bar layout information

#### `Popups.qml`

Handles:

* Popup visibility
* Popup coordination
* Popup mutual exclusion
* Network tab state
* Aggregate popup-open state
* Closing all open popups

---

## Keybindings

Keybindings are defined in `shell.qml` using Quickshell's `GlobalShortcut` component.

### Available Global Actions

| Shortcut Name           | Action                         | Handler                             | Description                                   |
| ----------------------- | ------------------------------ | ----------------------------------- | --------------------------------------------- |
| `focusModeToggle`       | Toggle fullscreen bar override | `ShellState.toggleManualOverride()` | Changes bar visibility behavior in fullscreen |
| `barHideToggle`         | Toggle bar visibility          | `ShellState.toggleManualHide()`     | Manually hides/shows the bar                  |
| `launcherToggle`        | Toggle launcher                | `Popups.launcherOpen`               | Opens/closes launcher                         |
| `clipboardToggle`       | Toggle clipboard manager       | `Popups.clipboardOpen`              | Opens/closes clipboard popup                  |
| `emojiPickerToggle`     | Toggle emoji picker            | `Popups.emojiOpen`                  | Opens/closes emoji popup                      |
| `mediaPlayerPopup`      | Toggle media popup             | `Popups.mediaOpen`                  | Opens/closes media controls                   |
| `wallpaperPickerToggle` | Toggle wallpaper picker        | `Popups.wallpaperOpen`              | Opens/closes wallpaper selector               |
| `keybindsToggle`        | Toggle keybind viewer          | `Popups.keybindsOpen`               | Opens/closes keybind viewer                   |
| `sessionToggle`         | Toggle session manager         | `Popups.sessionOpen`                | Opens/closes session popup                    |

### Common Default Bindings

```text
SUPER + X
    Toggle bar visibility

SUPER + Space
    Toggle launcher

SUPER + V
    Toggle clipboard manager
```

Additional keybindings can be mapped in the Hyprland configuration.

For a Lua-based Hyprland configuration:

```lua
local mainMod = "SUPER"

hl.bind(mainMod .. " + X", hl.dsp.global("quickshell:barHideToggle"))
hl.bind(mainMod .. " + SPACE", hl.dsp.global("quickshell:launcherToggle"))
hl.bind(mainMod .. " + V", hl.dsp.global("quickshell:clipboardToggle"))
```

---

## Configuration

### Launcher

The launcher supports the following syntax:

```text
> command
? web search
!g google search
!s startpage search
```

Examples:

```text
> htop
? how does Wayland work
!g Quickshell documentation
!s Linux news
```

Calculator examples:

```text
2 + 2
sqrt(144)
sin(30)
2^10
```

Unit conversion examples:

```text
10 km to mi
100 kmh to mph
2 gb to mb
```

Currency conversion examples:

```text
100 USD to INR
50 EUR to USD
```

Currency conversion is optional (turned on by default) and requires online exchange-rate access when no cached rate is available.

The default web search engine can be customized through:

```bash
export LAUNCHER_SEARCH_URL="https://www.google.com/search?q="
```

### Clipboard Manager

The clipboard manager can be customized through its service and popup components.

The available categories are:

```text
All
Text
Images
Links
Code
Pinned
```

Clipboard state is persisted using Quickshell's state storage, while image and search data use the Quickshell cache directory.

### Wallpaper Selector

The wallpaper picker can browse a configured directory and rescan it directly from the popup.

Wallpaper-related customization is primarily contained within:

```text
src/popups/wallpaper/
```

The wallpaper directory defaults to:

```text
~/wallpapers/
```

### Theme

Theme generation is handled through Matugen and Pywal16.

Generate a new theme from a wallpaper:

```bash
matugen image /path/to/wallpaper.jpg
```

The generated colors are written to:

```text
~/.config/quickshell/src/theme/Colors.json
```

### Environment

The launcher can optionally use:

```bash
LAUNCHER_SEARCH_URL
```

to change the default web search endpoint.

---

## Roadmap

The following features and improvements are planned for future development:

* [x] **Application Launcher Revamp**: Fuzzy search, pinned applications, recent applications, quick access, actions, special commands, conversions, and existing-window focusing.

* [x] **Clipboard Manager Revamp**: Search, filtering, categories, pinned entries, image previews, usage tracking, full-text search, deletion, and wipe confirmation.

* [x] **Wallpaper Selector**: Graphical wallpaper browsing with previews, directory selection, metadata, navigation, and apply controls.

* [x] **Battery Management**: Dedicated battery popup with performance, charging, and refresh-rate controls.

* [x] **System Monitor Expansion**: CPU, memory, GPU, VRAM, disk, network, swap, and temperature information.

* [x] **Emoji Picker**: Categorized emoji picker with search support.

* [x] **Session Manager**: Dedicated session and power controls.

* [x] **Keybind Viewer**: Dedicated graphical keybind viewer.

* [x] **Custom Tray Menus**: Custom system tray context menus and nested menu handling.

* [x] **Popup Infrastructure**: Shared popup loading, dismissal, animations, and centralized popup state.

* [x] **PipeWire Audio Integration**: Audio handling migrated to the current PipeWire-based service model.

* [x] **Dedicated System Services**: System functionality split into focused singleton services.

* [ ] **Enhanced Media Player**: Continue improving the media popup with richer controls, better multi-player handling, and optional lyrics.

* [ ] **Advanced Calendar / Productivity Suite**: Expand the calendar into a broader productivity interface.

* [ ] **Enhanced Idle Inhibitor**: Add richer status information, timers, and additional configuration options.

* [ ] **Advanced Battery Analytics**: Add battery health information, charging history, usage statistics, and additional hardware information.

* [ ] **GUI Settings Manager**: Provide graphical configuration for shell settings instead of requiring manual file editing.

* [ ] **Unified Hyprland + Quickshell Settings**: Provide one settings interface for both the compositor and shell.

* [ ] **Further Performance Optimization**: Continue optimizing dynamic components, state handling, and resource usage.

* [x] **Installer Script**: Dedicated installer for Velox-Q and its required dependencies, including installation, updates, backup handling, battery-aware power-management setup, native helper builds, and required privilege configuration.

---

## Contributing

### Reporting Issues

When reporting an issue, include:

1. **Environment**

   * Distribution
   * Hyprland version
   * Quickshell version
   * Qt version

2. **Steps to Reproduce**

   * Clear steps showing how the issue occurs

3. **Expected vs Actual Behavior**

   * What should happen
   * What actually happens

4. **Logs / Screenshots**

   * Quickshell output
   * Relevant screenshots
   * Hyprland logs where applicable

5. **Affected Component**

   * Module
   * Popup
   * Service
   * State
   * Theme

### Code Contributions

Please follow the existing project structure and style.

For new functionality, prefer:

```text
src/modules/
src/popups/
src/services/
src/state/
src/theme/
src/components/
```

Keep UI logic in UI components and system-facing logic in services wherever practical.

When adding a new feature:

* Keep the implementation modular
* Reuse existing components where possible
* Avoid duplicating popup/state logic
* Test on an actual Hyprland + Quickshell environment
* Update the README when the user-facing feature set changes

### Suggestions

Feature suggestions and improvement ideas are welcome.

Useful suggestions include:

* New shell features
* UI improvements
* Performance improvements
* Hardware compatibility
* Better Wayland / Hyprland integration
* Configuration improvements
* Documentation improvements

---

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.

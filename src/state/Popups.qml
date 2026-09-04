pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // ── Popup States ──────────────────────────────────────────────────────────
    property bool notificationsOpen: false
    property bool archMenuOpen:      false
    property bool calendarOpen:      false
    property bool mediaOpen:         false
    property bool idleInhibitorOpen: false
    property bool volumeOpen:        false
    property bool launcherOpen:      false
    property bool clipboardOpen:     false
    property bool emojiOpen:         false
    property bool wallpaperOpen:     false
    property bool batteryOpen:       false
    property bool keybindsOpen:      false
    property bool sessionOpen:       false
    property bool caffeineOpen:      false
    property int  networkTab:        0

    property bool systemOpen:        false
    property var  systemScreen:      null
    property real systemAnchorX:     0

    property bool networkOpen:       false
    property var  networkScreen:     null
    property real networkAnchorX:    0

    // ── Mutual Exclusion ──────────────────────────────────────────────────────
    // Opening any popup closes all others.
    // calendarOpen and idleInhibitorOpen are excluded — they're companion
    // states managed alongside other popups rather than independent panels.
    onNotificationsOpenChanged: if (notificationsOpen) _closeOthers("notifications")
    onSystemOpenChanged:        if (systemOpen)        _closeOthers("system")
    onMediaOpenChanged:         if (mediaOpen)         _closeOthers("media")
    onVolumeOpenChanged:        if (volumeOpen)        _closeOthers("volume")
    onNetworkOpenChanged:       if (networkOpen)       _closeOthers("network")
    onLauncherOpenChanged:      if (launcherOpen)      _closeOthers("launcher")
    onClipboardOpenChanged:     if (clipboardOpen)     _closeOthers("clipboard")
    onEmojiOpenChanged:         if (emojiOpen)         _closeOthers("emoji")
    onArchMenuOpenChanged:      if (archMenuOpen)      _closeOthers("archMenu")
    onWallpaperOpenChanged:     if (wallpaperOpen)     _closeOthers("wallpaper")
    onBatteryOpenChanged:       if (batteryOpen)       _closeOthers("battery")
    onKeybindsOpenChanged:      if (keybindsOpen)      _closeOthers("keybinds")
    onSessionOpenChanged:       if (sessionOpen)       _closeOthers("session")
    onCaffeineOpenChanged:      if (caffeineOpen)      _closeOthers("caffeine")
    onCalendarOpenChanged:      if (calendarOpen)      _closeOthers("calendar")

    function _closeOthers(keep) {
        if (keep !== "emoji")         emojiOpen         = false
        if (keep !== "media")         mediaOpen         = false
        if (keep !== "system")        systemOpen        = false
        if (keep !== "volume")        volumeOpen        = false
        if (keep !== "network")       networkOpen       = false
        if (keep !== "archMenu")      archMenuOpen      = false
        if (keep !== "launcher")      launcherOpen      = false
        if (keep !== "clipboard")     clipboardOpen     = false
        if (keep !== "notifications") notificationsOpen = false
        if (keep !== "wallpaper")     wallpaperOpen     = false
        if (keep !== "battery")       batteryOpen       = false
        if (keep !== "keybinds")      keybindsOpen      = false
        if (keep !== "session")       sessionOpen       = false
        if (keep !== "caffeine")      caffeineOpen      = false
        if (keep !== "calendar")      calendarOpen      = false
    }

    // ── Aggregate State ───────────────────────────────────────────────────────
    readonly property bool anyOpen:
        notificationsOpen ||
        systemOpen        ||
        archMenuOpen      ||
        mediaOpen         ||
        volumeOpen        ||
        clipboardOpen     ||
        launcherOpen      ||
        emojiOpen         ||
        wallpaperOpen     ||
        batteryOpen       ||
        networkOpen       ||
        sessionOpen       ||
        caffeineOpen      ||
        keybindsOpen      ||
        calendarOpen

    // ── Methods ───────────────────────────────────────────────────────────────
    function closeAll() {
        notificationsOpen = false
        systemOpen        = false
        archMenuOpen      = false
        mediaOpen         = false
        volumeOpen        = false
        networkOpen       = false
        clipboardOpen     = false
        launcherOpen      = false
        emojiOpen         = false
        wallpaperOpen     = false
        batteryOpen       = false
        keybindsOpen      = false
        sessionOpen       = false
        caffeineOpen      = false
        calendarOpen      = false
    }
}

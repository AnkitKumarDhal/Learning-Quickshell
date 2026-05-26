pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // ── Popup States ──────────────────────────────────────────────────────────
    property bool notificationsOpen: false
    property bool systemOpen:        false
    property bool archMenuOpen:      false
    property bool calendarOpen:      false
    property bool mediaOpen:         false
    property bool idleInhibitorOpen: false
    property bool volumeOpen:        false
    property bool launcherOpen:      false
    property bool clipboardOpen:     false
    property bool emojiOpen:         false
    property bool networkOpen:       false
    property int  networkTab:        0

    // ── Aggregate State ───────────────────────────────────────────────────────
    readonly property bool anyOpen:
        notificationsOpen ||
        systemOpen        ||
        archMenuOpen      ||
        calendarOpen      ||
        mediaOpen         ||
        idleInhibitorOpen ||
        volumeOpen        ||
        clipboardOpen     ||
        launcherOpen      ||
        emojiOpen         ||
        networkOpen

    // ── Methods ───────────────────────────────────────────────────────────────
    function closeAll() {
        notificationsOpen = false
        systemOpen        = false
        archMenuOpen      = false
        calendarOpen      = false
        mediaOpen         = false
        idleInhibitorOpen = false
        volumeOpen        = false
        networkOpen       = false
        clipboardOpen     = false
        launcherOpen      = false
        emojiOpen         = false
    }
}

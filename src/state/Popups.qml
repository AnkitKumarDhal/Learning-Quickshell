pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // ── Timing Constants ──────────────────────────────────────────────────────
    // Read by PopupSlide
    readonly property int slideDuration:   400
    readonly property int hoverCloseDelay: 300

    // ── Popup States ──────────────────────────────────────────────────────────
    property bool notificationsOpen: false
    property bool systemOpen:        false
    property bool archMenuOpen:      false
    property bool calendarOpen:      false
    property bool mediaOpen:         false
    property bool idleInhibitorOpen: false
    property bool volumeOpen:        false

    // Note: Tray context menu is managed internally by TrayContextMenu.
    // No open bool needed here; TrayContextMenu owns its own state.

    // ── Aggregate State ───────────────────────────────────────────────────────
    readonly property bool anyOpen:
        notificationsOpen ||
        systemOpen        ||
        archMenuOpen      ||
        calendarOpen      ||
        mediaOpen         ||
        idleInhibitorOpen ||
        volumeOpen

    // ── Methods ───────────────────────────────────────────────────────────────
    function closeAll() {
        notificationsOpen = false
        systemOpen        = false
        archMenuOpen      = false
        calendarOpen      = false
        mediaOpen         = false
        idleInhibitorOpen = false
        volumeOpen        = false
    }
}

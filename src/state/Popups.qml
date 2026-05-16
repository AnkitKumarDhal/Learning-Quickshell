pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // ── Timing constants (read by PopupSlide) ─────────────────────────────────
    readonly property int slideDuration:  400
    readonly property int hoverCloseDelay: 300

    // ── Notification panel ────────────────────────────────────────────────────
    property bool notificationsOpen: false

    // ── System monitor ────────────────────────────────────────────────────────
    property bool systemOpen: false

    // ── Tray context menu — managed internally by TrayContextMenu ─────────────
    // No open bool needed here; TrayContextMenu owns its own state

    // ── Control Panel (Arch menu) ─────────────────────────────────────────────
    property bool archMenuOpen: false

    // ── Calendar Popup ────────────────────────────────────────────────────────
    property bool calendarOpen: false

    // ── Media Player ──────────────────────────────────────────────────────────
    property bool mediaOpen: false

    // ── Idle Inhibitor ────────────────────────────────────────────────────────
    property bool idleInhibitorOpen: false

    // ── Volume ────────────────────────────────────────────────────────────────
    property bool volumeOpen: false

    // ── Aggregate ─────────────────────────────────────────────────────────────
    readonly property bool anyOpen:
        notificationsOpen ||
        systemOpen        ||
        archMenuOpen      ||
        calendarOpen      ||
        mediaOpen         ||
        idleInhibitorOpen ||
        volumeOpen

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

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
    property string systemMode: "cpu"   // "cpu" | "mem"

    // ── Tray context menu — managed internally by TrayContextMenu ────────────
    // No open bool needed here; TrayContextMenu owns its own state

    // ── Aggregate ─────────────────────────────────────────────────────────────
    readonly property bool anyOpen:
        notificationsOpen ||
        systemOpen

    function closeAll() {
        notificationsOpen = false
        systemOpen        = false
    }
}

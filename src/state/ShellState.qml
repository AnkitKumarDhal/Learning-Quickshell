pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // ── Top bar notch widths (written by TopBar, read by PopupDismiss) ────────
    property int topBarLWidth: 0
    property int topBarCWidth: 0
    property int topBarRWidth: 0

    // ── Focus / distraction-free mode ─────────────────────────────────────────
    // Set true to collapse the bar to a thin border strip
    property bool focusMode: false
}

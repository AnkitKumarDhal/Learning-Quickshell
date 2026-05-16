pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root

    // ── Pill geometry ─────────────────────────────────────────────────────────
    readonly property int borderWidth:   3
    readonly property int barHeight:     36
    readonly property int pillHeight:    30
    readonly property int pillRadius:    15
    readonly property int pillPadding:   32   // added to content width
    readonly property int barSpacing:    10   // spacing between pills
    readonly property int barMargin:     8    // outer margin inside bar

    // ── Popup geometry ────────────────────────────────────────────────────────
    readonly property int popupRadius:   14
    readonly property int popupBorder:   1

    // ── Animation ─────────────────────────────────────────────────────────────
    readonly property int animDuration:      250
    readonly property int hoverFadeDuration: 150
    readonly property int slideInDuration:   400

    // Bezier curve used on popup open/close (matches your SystemPopup)
    readonly property var slideCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]

    // ── Hover ─────────────────────────────────────────────────────────────────
    readonly property real hoverOpacity:     0.15  // primary at 15% for pill hover bg
    readonly property int  hoverWidthGain:   10    // pill expands by this on hover
}

# Fix: Network module pill expanding too wide for long WiFi names

## Problem
The SSID Text element in `src/modules/Right/Network.qml` has `elide: Text.ElideRight` but no width constraint, so it expands to fit the full text length, causing the pill to cover other modules.

## Solution
Add `Layout.maximumWidth: 120` to the SSID Text element so long names get truncated with ellipsis instead of expanding the pill indefinitely.

## Changes

### `src/modules/Right/Network.qml`
- Add `Layout.maximumWidth: 120` to the SSID Text element (line ~52-58)

```qml
Text {
    text: hasWifi ? (NetworkService.ssid || "Unknown") : SystemStats.activeInterface
    font.family: Fonts.font
    font.pixelSize: 13
    color: Colors.primary
    visible: root._showLabel
    elide: Text.ElideRight
    Layout.maximumWidth: 120  // NEW
}
```

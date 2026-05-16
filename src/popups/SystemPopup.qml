import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services.system
import qs.src.services

PanelWindow {
    id: root

    property var screen

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top:   true
        right: true
    }

    implicitWidth:  420
    implicitHeight: root.screen ? root.screen.height : 800

    WlrLayershell.layer: WlrLayer.Overlay
    visible: slidePanel.windowVisible

    PopupSlide {
        id: slidePanel
        anchors.fill: parent
        edge: "top"
        open: Popups.systemOpen
        onCloseRequested: Popups.systemOpen = false
    }

    // ── Popup card ────────────────────────────────────────────────────────────
    Rectangle {
        anchors {
            top:         parent.top
            right:       parent.right
            topMargin:   Theme.barHeight + 8
            rightMargin: Theme.barMargin
        }
        width:        400
        height:       cardCol.implicitHeight + 24
        radius:       Theme.popupRadius
        color:        Colors.surfaceContainer
        border.color: Colors.outlineVariant
        border.width: Theme.popupBorder
        clip:         true

        ColumnLayout {
            id: cardCol
            anchors {
                top:   parent.top
                left:  parent.left
                right: parent.right
                margins: 16
            }
            spacing: 16

            // ── Header ────────────────────────────────────────────────────────
            Text {
                text:           "System"
                color:          Colors.on_Surface
                font.pixelSize: 14
                font.bold:      true
                font.family:    Fonts.font
                Layout.topMargin: 4
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height:  1
                color:   Colors.outlineVariant
                opacity: 0.5
            }

            // ── Speedometers row ──────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Speedometer {
                    label:   "CPU"
                    value:   SystemStats.cpuUsage
                    color:   Colors.primary
                    Layout.fillWidth: true
                }

                Speedometer {
                    label:   "RAM"
                    value:   SystemStats.memUsage
                    color:   Colors.secondary
                    Layout.fillWidth: true
                }

                // GPU — only shown on AMD
                Speedometer {
                    visible: SystemStats.hasGpu
                    label:   "GPU"
                    value:   SystemStats.gpuUsage
                    color:   Colors.tertiary
                    Layout.fillWidth: true
                }
            }

            // ── Disk bars ─────────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: SystemStats.diskPartitions

                    delegate: DiskBar {
                        required property var modelData
                        Layout.fillWidth: true

                        mountPoint: modelData.mount
                        usedBytes:  modelData.used
                        totalBytes: modelData.total
                        label:      modelData.mount === "/" ? "Root" : modelData.mount
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height:  1
                color:   Colors.outlineVariant
                opacity: 0.5
            }

            // ── Network graph ─────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text:           "Network  " + SystemStats.activeInterface
                        color:          Colors.on_SurfaceVariant
                        font.pixelSize: 11
                        font.family:    Fonts.font
                        Layout.fillWidth: true
                    }

                    Text {
                        text:           "↑ " + SystemStats.formatBytes(SystemStats.netUpRate)
                                      + "  ↓ " + SystemStats.formatBytes(SystemStats.netDownRate)
                        color:          Colors.on_Surface
                        font.pixelSize: 11
                        font.bold:      true
                        font.family:    Fonts.font
                    }
                }

                NetworkGraph {
                    Layout.fillWidth: true
                    height:           60
                    upHistory:        SystemStats.netUpHistory
                    downHistory:      SystemStats.netDownHistory
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height:  1
                color:   Colors.outlineVariant
                opacity: 0.5
            }

            // ── Temperature ───────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 4

                Text {
                    text:           "󰔏  Temperature"
                    color:          Colors.on_SurfaceVariant
                    font.pixelSize: 11
                    font.family:    Fonts.font
                    Layout.fillWidth: true
                }

                Text {
                    text: SystemStats.temperature > 0
                              ? SystemStats.temperature + " °C"
                              : "N/A"
                    color: SystemStats.temperature >= 80
                               ? Colors.error
                               : SystemStats.temperature >= 60
                                   ? Colors.tertiary
                                   : Colors.on_Surface
                    font.pixelSize: 12
                    font.bold:      true
                    font.family:    Fonts.font

                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }
    }
}

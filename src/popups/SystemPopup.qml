import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.services.system
import qs.src.popups.system

PanelWindow {
    id: root

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

    mask: Region {
        x:      root.implicitWidth - sysCard.width - Theme.barMargin
        y:      Theme.barHeight + 8
        width:  sysCard.width
        height: sysCard.height
    }

    PopupSlide {
        id: slidePanel
        anchors.fill: parent
        edge: "top"
        open: Popups.systemOpen && Popups.systemScreen === root.screen
        onCloseRequested: Popups.systemOpen = false

        Rectangle {
            id: sysCard
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
                spacing: 12

                // ── Header ────────────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text:           "System"
                            color:          Colors.on_Surface
                            font.pixelSize: 14
                            font.bold:      true
                            font.family:    Fonts.font
                        }

                        Text {
                            text:           "Live system overview"
                            color:          Colors.on_SurfaceVariant
                            font.pixelSize: 9
                            font.family:    Fonts.font
                        }
                    }

                    Text {
                        text:           SystemStats.activeInterface !== ""
                                      ? SystemStats.activeInterface
                                      : "Offline"
                        color:          SystemStats.activeInterface !== ""
                                      ? Colors.primary
                                      : Colors.outline
                        font.pixelSize: 10
                        font.bold:      true
                        font.family:    Fonts.font
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height:  1
                    color:   Colors.outlineVariant
                    opacity: 0.5
                }

                // ── CPU / Memory / GPU overview ────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    MetricCard {
                        label:    "CPU"
                        value:    Math.round(SystemStats.cpuUsage * 100) + "%"
                        detail:   SystemStats.cpuFrequencyGhz > 0
                                  ? SystemStats.cpuFrequencyGhz.toFixed(1) + " GHz"
                                  : SystemStats.cpuCores.length + " cores"
                        progress: SystemStats.cpuUsage
                        accent:   Colors.primary
                        Layout.fillWidth: true
                    }

                    MetricCard {
                        label:    "RAM"
                        value:    Math.round(SystemStats.memUsage * 100) + "%"
                        detail:   SystemStats.memUsedGb.toFixed(1) + " / " + SystemStats.memTotalGb.toFixed(1) + " GB"
                        progress: SystemStats.memUsage
                        accent:   Colors.secondary
                        Layout.fillWidth: true
                    }

                    MetricCard {
                        visible:  SystemStats.hasGpu
                        label:    "GPU"
                        value:    Math.round(SystemStats.gpuUsage * 100) + "%"
                        detail:   SystemStats.gpuName !== ""
                                  ? SystemStats.gpuName
                                  : "Graphics processor"
                        progress: SystemStats.gpuUsage
                        accent:   Colors.tertiary
                        Layout.fillWidth: true
                    }
                }

                // ── CPU cores ──────────────────────────────────────────────────────
                ColumnLayout {
                    visible: SystemStats.cpuCores.length > 1
                    Layout.fillWidth: true
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text:           "CPU cores"
                            color:          Colors.on_SurfaceVariant
                            font.pixelSize: 10
                            font.family:    Fonts.font
                            Layout.fillWidth: true
                        }

                        Text {
                            text:           SystemStats.cpuFrequencyGhz > 0
                                          ? SystemStats.cpuFrequencyGhz.toFixed(1) + " GHz"
                                          : ""
                            color:          Colors.on_Surface
                            font.pixelSize: 10
                            font.bold:      true
                            font.family:    Fonts.font
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: SystemStats.cpuCores

                            delegate: Rectangle {
                                required property var modelData

                                width:  34
                                height: 18
                                radius: 5
                                color:  Colors.surfaceContainerHighest

                                Rectangle {
                                    anchors {
                                        left:   parent.left
                                        bottom: parent.bottom
                                    }
                                    width:  parent.width * modelData.usage
                                    height: parent.height
                                    radius: parent.radius
                                    color:  modelData.usage >= 0.9
                                                ? Colors.error
                                                : modelData.usage >= 0.7
                                                    ? Colors.tertiary
                                                    : Colors.primary
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text:             Math.round(modelData.usage * 100) + "%"
                                    color:            Colors.on_Surface
                                    font.pixelSize:   8
                                    font.bold:        true
                                    font.family:      Fonts.font
                                    z:                2
                                }
                            }
                        }
                    }
                }

                // ── Memory / GPU detail ────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text:           "Available " + SystemStats.memAvailableGb.toFixed(1) + " GB"
                        color:          Colors.on_SurfaceVariant
                        font.pixelSize: 9
                        font.family:    Fonts.font
                        Layout.fillWidth: true
                    }

                    Text {
                        text:           "Swap " + SystemStats.swapUsedGb.toFixed(1) + " / " + SystemStats.swapTotalGb.toFixed(1) + " GB"
                        color:          SystemStats.swapUsage >= 0.9 ? Colors.error : Colors.on_SurfaceVariant
                        font.pixelSize: 9
                        font.family:    Fonts.font
                    }

                    Text {
                        visible:        SystemStats.hasGpu && SystemStats.gpuVramTotalGb > 0
                        text:           "VRAM " + SystemStats.gpuVramUsedGb.toFixed(1) + " / " + SystemStats.gpuVramTotalGb.toFixed(1) + " GB"
                        color:          Colors.on_SurfaceVariant
                        font.pixelSize: 9
                        font.family:    Fonts.font
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height:  1
                    color:   Colors.outlineVariant
                    opacity: 0.5
                }

                // ── Network ────────────────────────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text:           "Network"
                            color:          Colors.on_SurfaceVariant
                            font.pixelSize: 10
                            font.bold:      true
                            font.family:    Fonts.font
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 8

                            Text {
                                text:           "↑ " + SystemStats.formatBytes(SystemStats.netUpRate)
                                color:          Colors.tertiary
                                font.pixelSize: 9
                                font.bold:      true
                                font.family:    Fonts.font
                            }

                            Text {
                                text:           "↓ " + SystemStats.formatBytes(SystemStats.netDownRate)
                                color:          Colors.primary
                                font.pixelSize: 9
                                font.bold:      true
                                font.family:    Fonts.font
                            }
                        }
                    }

                    NetworkGraph {
                        Layout.fillWidth: true
                        height:           68
                        upHistory:        SystemStats.netUpHistory
                        downHistory:      SystemStats.netDownHistory
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text:           "↑ Upload"
                            color:          Colors.tertiary
                            font.pixelSize: 8
                            font.family:    Fonts.font
                            Layout.fillWidth: true
                        }

                        Text {
                            text:           "↓ Download"
                            color:          Colors.primary
                            font.pixelSize: 8
                            font.family:    Fonts.font
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height:  1
                    color:   Colors.outlineVariant
                    opacity: 0.5
                }

                // ── Storage ────────────────────────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text:           "Storage"
                        color:          Colors.on_SurfaceVariant
                        font.pixelSize: 10
                        font.bold:      true
                        font.family:    Fonts.font
                    }

                    Repeater {
                        model: SystemStats.diskPartitions

                        delegate: DiskBar {
                            required property var modelData
                            Layout.fillWidth: true

                            mountPoint: modelData.mount
                            fsType:     modelData.fsType
                            usedBytes:  modelData.used
                            totalBytes: modelData.total
                            freeBytes:  modelData.total - modelData.used
                            label:      modelData.mount === "/" ? "Root" : modelData.mount
                        }
                    }

                    Text {
                        visible:        SystemStats.diskPartitions.length === 0
                        text:           "No filesystem data available"
                        color:          Colors.outline
                        font.pixelSize: 9
                        font.family:    Fonts.font
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height:  1
                    color:   Colors.outlineVariant
                    opacity: 0.5
                }

                // ── Temperatures ───────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text:           "󰔏  Thermals"
                        color:          Colors.on_SurfaceVariant
                        font.pixelSize: 10
                        font.bold:      true
                        font.family:    Fonts.font
                        Layout.fillWidth: true
                    }

                    Text {
                        visible:        SystemStats.temperature > 0
                        text:           SystemStats.temperature + " °C"
                        color:          SystemStats.temperature >= 80
                                       ? Colors.error
                                       : SystemStats.temperature >= 60
                                           ? Colors.tertiary
                                           : Colors.on_Surface
                        font.pixelSize: 11
                        font.bold:      true
                        font.family:    Fonts.font

                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }

                RowLayout {
                    visible: SystemStats.displayTemperatures.length > 0
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: SystemStats.displayTemperatures

                        delegate: Rectangle {
                            required property var modelData

                            Layout.fillWidth: true
                            height: 32
                            radius: 8
                            color: Colors.surfaceContainerHighest

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8

                                Text {
                                    text:           modelData.name
                                    color:          Colors.on_SurfaceVariant
                                    font.pixelSize: 8
                                    font.family:    Fonts.font
                                    elide:          Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text:           modelData.value + " °C"
                                    color:          modelData.value >= 80
                                                   ? Colors.error
                                                   : modelData.value >= 60
                                                       ? Colors.tertiary
                                                       : Colors.on_Surface
                                    font.pixelSize: 9
                                    font.bold:      true
                                    font.family:    Fonts.font
                                }
                            }
                        }
                    }

                    Text {
                        visible:        SystemStats.displayTemperatures.length === 0
                        text:           "No thermal sensors available"
                        color:          Colors.outline
                        font.pixelSize: 9
                        font.family:    Fonts.font
                    }
                }
            }
        }
    }
}

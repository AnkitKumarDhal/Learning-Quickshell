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

        on_EffectiveOpenChanged: {
            if (_effectiveOpen)
                DiskStats.refresh()
        }

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
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text:           "System"

                        font.family:    Fonts.font
                        font.pixelSize: 16
                        font.bold:      true

                        color:          Colors.on_Surface
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
                        label:    ""
                        value:    Math.round(SystemStats.cpuUsage * 100) + "%"
                        detail:   SystemStats.cpuFrequencyGhz > 0
                                  ? SystemStats.cpuFrequencyGhz.toFixed(1) + " GHz"
                                  : SystemStats.cpuCores.length + " cores"
                        progress: SystemStats.cpuUsage
                        accent:   Colors.primary
                        Layout.fillWidth: true
                    }

                    MetricCard {
                        label:    ""
                        value:    Math.round(SystemStats.memUsage * 100) + "%"
                        detail:   SystemStats.memUsedGb.toFixed(1) + " / " + SystemStats.memTotalGb.toFixed(1) + " GB"
                        progress: SystemStats.memUsage
                        accent:   Colors.secondary
                        Layout.fillWidth: true
                    }

                    MetricCard {
                        visible:  SystemStats.hasGpu
                        label:    "󰢮"
                        value:    Math.round(SystemStats.gpuUsage * 100) + "%"
                        detail:   SystemStats.gpuVramTotalGb > 0
                                  ? SystemStats.gpuVramUsedGb.toFixed(1) + " / " + SystemStats.gpuVramTotalGb.toFixed(1) + " GB VRAM"
                                  : SystemStats.gpuName
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
                            text:           " CPU cores"

                            font.family:    Fonts.font
                            font.pointSize: 10
                            font.bold:      true

                            color:          Colors.on_SurfaceVariant

                            Layout.fillWidth: true
                        }

                        Text {
                            text:           SystemStats.cpuFrequencyGhz > 0
                                          ? SystemStats.cpuFrequencyGhz.toFixed(1) + " GHz"
                                          : ""

                            font.family:    Fonts.font
                            font.pixelSize: 11
                            font.bold:      true

                            color:          Colors.on_Surface
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

                                    font.family:      Fonts.font
                                    font.pixelSize:   10
                                    font.bold:        true

                                    color:            Colors.on_Surface

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

                        font.family:    Fonts.font
                        font.pixelSize: 10
                        font.bold:      true

                        color:          Colors.on_SurfaceVariant

                        Layout.fillWidth: true
                    }

                    Text {
                        text:           "Swap " + SystemStats.swapUsedGb.toFixed(1) + " / " + SystemStats.swapTotalGb.toFixed(1) + " GB"

                        font.family:    Fonts.font
                        font.pixelSize: 10
                        font.bold:      true

                        color:          SystemStats.swapUsage >= 0.9
                                        ? Colors.error
                                        : Colors.on_SurfaceVariant
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
                            text:           "󰤥 Network"

                            font.family:    Fonts.font
                            font.pointSize: 10
                            font.bold:      true

                            color:          Colors.on_SurfaceVariant

                            Layout.fillWidth: true
                        }

                        Text {
                            text:           SystemStats.activeInterface !== ""
                                          ? SystemStats.activeInterface
                                          : "Offline"

                            font.family:    Fonts.font
                            font.pixelSize: 11
                            font.bold:      true

                            color:          SystemStats.activeInterface !== ""
                                          ? Colors.primary
                                          : Colors.outline
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text:           "↑ " + SystemStats.formatBytes(SystemStats.netUpRate)

                            font.family:    Fonts.font
                            font.pixelSize: 11
                            font.bold:      true

                            color:          Colors.tertiary
                        }

                        Text {
                            text:           "↓ " + SystemStats.formatBytes(SystemStats.netDownRate)

                            font.family:    Fonts.font
                            font.pixelSize: 11
                            font.bold:      true

                            color:          Colors.primary
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

                            font.family:    Fonts.font
                            font.pixelSize: 10
                            font.bold:      true

                            color:          Colors.tertiary

                            Layout.fillWidth: true
                        }

                        Text {
                            text:           "↓ Download"

                            font.family:    Fonts.font
                            font.pixelSize: 10
                            font.bold:      true

                            color:          Colors.primary
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
                        text:           " Storage"

                        font.family:    Fonts.font
                        font.pointSize: 10
                        font.bold:      true

                        color:          Colors.on_SurfaceVariant
                    }

                    Repeater {
                        model: SystemStats.diskPartitions

                        delegate: DiskBar {
                            required property var modelData
                            Layout.fillWidth: true

                            device:      modelData.name
                            mountPoint:  modelData.mountPoint
                            fsType:      modelData.fsType
                            usedBytes:   modelData.used
                            totalBytes:  modelData.size
                            percentage:  modelData.percentage
                        }
                    }

                    Text {
                        visible:        SystemStats.diskPartitions.length === 0
                        text:           "No disk usage data available"

                        font.family:    Fonts.font
                        font.pixelSize: 10
                        font.bold:      true

                        color:          Colors.outline
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
                        text:           "󰔏 Thermals"

                        font.family:    Fonts.font
                        font.pointSize: 10
                        font.bold:      true

                        color:          Colors.on_SurfaceVariant

                        Layout.fillWidth: true
                    }

                    Text {
                        visible:        SystemStats.temperature > 0
                        text:           SystemStats.temperature + " °C"

                        font.family:    Fonts.font
                        font.pixelSize: 11
                        font.bold:      true

                        color:          SystemStats.temperature >= 80
                                       ? Colors.error
                                       : SystemStats.temperature >= 60
                                           ? Colors.tertiary
                                           : Colors.on_Surface

                        Behavior on color {
                            ColorAnimation {
                                duration: 300
                            }
                        }
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

                                    font.family:    Fonts.font
                                    font.pixelSize: 10
                                    font.bold:      true

                                    color:          Colors.on_SurfaceVariant

                                    elide:          Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text:           modelData.value + " °C"

                                    font.family:    Fonts.font
                                    font.pixelSize: 10
                                    font.bold:      true

                                    color:          modelData.value >= 80
                                                   ? Colors.error
                                                   : modelData.value >= 60
                                                       ? Colors.tertiary
                                                       : Colors.on_Surface
                                }
                            }
                        }
                    }

                    Text {
                        visible:        SystemStats.displayTemperatures.length === 0
                        text:           "No thermal sensors available"

                        font.family:    Fonts.font
                        font.pixelSize: 10
                        font.bold:      true

                        color:          Colors.outline
                    }
                }
            }
        }
    }
}

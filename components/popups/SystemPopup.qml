import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../settings"

PanelWindow {
    id: root

    property string mode: "cpu"
    property bool isOpen: false

    property real cpuOverall: 0.0
    property var cpuCores: []
    property var _coresPrev: ({})

    property real memUsed: 0.0
    property real memTotal: 0.0
    property real memCached: 0.0
    property real memFree: 0.0

    function open(mode) {
        root.mode = m
        isOpen = true
        grabTimer.restart()
    }

    function close() {
        isOpen = false
        focusGrab.active = false
        grabTimer.stop()
    }

    function toggle(m) {
        if (isOpen && mode === m) close()
        else open(m)
    }

    anchors {
        top: true
        right: true
    }

    margins.right: 8

    implicitWidth: 300
    implicitHeight: wrapper.implicitHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onCleared: root.close()
    }

    Timer {
        id: grabTimer
        interval: 50
        onTriggered: focusGrab.active = true
    }

    Process {
        id: cpuProc
        command: ["cat", "/proc/stat"]
        running: false

        stdout: SplitParser {
            onRead: function(line) {
                const m = line.match(/^(cpu\d*)\s+(.+)/)
                if (!m) return

                const id    = m[1]
                const parts = m[2].trim().split(/\s+/).map(Number)
                const user = parts[0], nice = parts[1], sys = parts[2],
                idle = parts[3], iow  = parts[4], irq = parts[5],
                sirq = parts[6]

                const totalIdle = idle + iow
                const totalBusy = user + nice + sys + irq + sirq
                const total     = totalIdle + totalBusy

                const prev = root._coresPrev[id] || { idle: totalIdle, total: total }
                const dIdle  = totalIdle - prev.idle
                const dTotal = total     - prev.total
                const usage  = dTotal > 0 ? (1.0 - dIdle / dTotal) * 100.0 : 0.0

                root._coresPrev[id] = { idle: totalIdle, total: total }

                if (id === "cpu") {
                    root.cpuOverall = usage
                } else {
                    const idx = parseInt(id.replace("cpu", ""))
                    const arr = root.cpuCores.slice()
                    arr[idx]  = usage
                    root.cpuCores = arr
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: cpuProc.running = true
    }

    Process {
        id: memProc
        command: ["cat", "/proc/meminfo"]
        running: false

        stdout: SplitParser {
            property var _t: 0
            property var _f: 0
            property var _b: 0
            property var _c: 0

            onRead: function(line) {
                const val = parseInt(line.split(/\s+/)[1])
                if      (line.startsWith("MemTotal:"))     _t = val
                else if (line.startsWith("MemFree:"))      _f = val
                else if (line.startsWith("Buffers:"))      _b = val
                else if (line.startsWith("Cached:"))       _c = val
                else if (line.startsWith("MemAvailable:")) {
                    root.memTotal  = _t / 1024 / 1024
                    root.memFree   = val / 1024 / 1024
                    root.memCached = (_b + _c) / 1024 / 1024
                    root.memUsed   = (_t - val) / 1024 / 1024
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: memProc.running = true
    }

    Rectangle {
        id: wrapper
        width: parent.width
        implicitHeight: isOpen ? contentCol.implicitHeight + 16 : 0
        clip: true
        color: Colors.background
        radius: 14
        border.color: Colors.primary
        border.width: 1

        Behavior on implicitHeight {
            NumberAnimation {
                duration: 400
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
            }
        }

        ColumnLayout {
            id: contentCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 8
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 2

            // ── Header ──
            Item {
                Layout.fillWidth: true
                height: 36

                Rectangle {
                    width: 3; height: 16; radius: 2
                    color: Colors.primary
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    verticalAlignment: Text.AlignVCenter
                    text: root.mode === "cpu" ? "CPU Usage" : "Memory Usage"
                    color: Colors.primary
                    font.bold: true
                    font.pixelSize: 13
                    font.family: Fonts.font
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 4; Layout.rightMargin: 4
                height: 1
                color: Colors.primary
                opacity: 0.2
            }

            // ── CPU view ──
            ColumnLayout {
                visible: root.mode === "cpu"
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                spacing: 2

                // Big overall number
                Item {
                    Layout.fillWidth: true
                    height: 36

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        verticalAlignment: Text.AlignVCenter
                        text: "Overall: " + Math.round(root.cpuOverall) + "%"
                        color: Colors.primary
                        opacity: 0.7
                        font.pixelSize: 11
                        font.bold: true
                        font.family: Fonts.font
                    }

                    // Overall bar
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 120; height: 6; radius: 3
                        color: Colors.primary; opacity: 0.15

                        Rectangle {
                            width: parent.width * (root.cpuOverall / 100)
                            height: parent.height; radius: parent.radius
                            color: Colors.primary; opacity: 1.0 / 0.15

                            Behavior on width { NumberAnimation { duration: 800 } }
                        }
                    }
                }

                // Per-core rows
                Repeater {
                    model: root.cpuCores

                    delegate: Item {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        height: 32

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: Colors.primary
                            opacity: coreHover.containsMouse ? 0.15 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        Rectangle {
                            visible: coreHover.containsMouse
                            width: 3; height: 14; radius: 2
                            color: Colors.primary
                            anchors.left: parent.left; anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Core " + index
                            color: Colors.primary
                            font.pixelSize: 12; font.bold: true; font.family: Fonts.font
                        }

                        // Bar track
                        Rectangle {
                            anchors.right: parent.right; anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 120; height: 5; radius: 3
                            color: Colors.primary; opacity: 0.15

                            Rectangle {
                                width: parent.width * (modelData / 100)
                                height: parent.height; radius: parent.radius
                                color: Colors.primary; opacity: 1.0 / 0.15

                                Behavior on width { NumberAnimation { duration: 800 } }
                            }
                        }

                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 140
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(modelData) + "%"
                            color: Colors.primary; opacity: 0.7
                            font.pixelSize: 11; font.bold: true; font.family: Fonts.font
                        }

                        MouseArea {
                            id: coreHover
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }

            // ── Memory view ──
            ColumnLayout {
                visible: root.mode === "mem"
                Layout.fillWidth: true
                Layout.leftMargin: 4; Layout.rightMargin: 4
                spacing: 2

                // Breakdown bar
                Item {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8; Layout.rightMargin: 8
                    height: 36

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.right: parent.right
                        height: 8; radius: 4
                        color: Colors.primary; opacity: 0.15

                        // Used segment
                        Rectangle {
                            width: root.memTotal > 0
                            ? parent.width * (root.memUsed - root.memCached) / root.memTotal
                            : 0
                            height: parent.height
                            anchors.left: parent.left
                            radius: parent.radius
                            color: Colors.primary; opacity: 1.0 / 0.15

                            Behavior on width { NumberAnimation { duration: 800 } }
                        }

                        // Cached segment
                        Rectangle {
                            x: root.memTotal > 0
                            ? parent.width * (root.memUsed - root.memCached) / root.memTotal
                            : 0
                            width: root.memTotal > 0
                            ? parent.width * root.memCached / root.memTotal
                            : 0
                            height: parent.height
                            color: Colors.primary; opacity: (1.0 / 0.15) * 0.4

                            Behavior on width { NumberAnimation { duration: 800 } }
                            Behavior on x    { NumberAnimation { duration: 800 } }
                        }
                    }
                }

                // Used / Cached / Free rows
                Repeater {
                    model: [
                        { label: "Used",   value: (root.memUsed - root.memCached), color: 1.0 },
                        { label: "Cached", value: root.memCached,                  color: 0.5 },
                        { label: "Free",   value: root.memFree,                    color: 0.25 },
                    ]

                    delegate: Item {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 32

                        Rectangle {
                            anchors.fill: parent; radius: 8
                            color: Colors.primary
                            opacity: rowHover.containsMouse ? 0.15 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        Rectangle {
                            visible: rowHover.containsMouse
                            width: 3; height: 14; radius: 2
                            color: Colors.primary
                            anchors.left: parent.left; anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            color: Colors.primary
                            font.pixelSize: 12; font.bold: true; font.family: Fonts.font
                        }

                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.value.toFixed(2) + " GB"
                            color: Colors.primary; opacity: 0.7
                            font.pixelSize: 11; font.bold: true; font.family: Fonts.font
                        }

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent; hoverEnabled: true
                        }
                    }
                }

                // Total row
                Item {
                    Layout.fillWidth: true
                    height: 36

                    Rectangle {
                        anchors.fill: parent; radius: 8
                        color: Colors.primary; opacity: 0.08
                    }

                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Total"
                        color: Colors.primary
                        font.pixelSize: 12; font.bold: true; font.family: Fonts.font
                    }

                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.memTotal.toFixed(2) + " GB"
                        color: Colors.primary
                        font.pixelSize: 11; font.bold: true; font.family: Fonts.font
                    }
                }
            }

            Item { height: 4; Layout.fillWidth: true }
        }
    }

    mask: Region {
        item: isOpen ? root.contentItem : null
    }
}

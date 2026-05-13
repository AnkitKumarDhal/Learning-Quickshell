import QtQuick
import Quickshell
import Quickshell.Io
import "../../../settings"

Rectangle {
    id: memPill

    implicitWidth: memText.implicitWidth + 32
    implicitHeight: 30
    radius: 15
    color: Colors.background

    property real memUsed: 0.0
    property real memTotal: 0.0
    
    Process {
        id: memProc
        command: ["cat", "/proc/meminfo"]
        running: false

        stdout: SplitParser {
            property var _total: 0
            property var _free: 0
            property var _buffers: 0
            property var _cached: 0
            property var _reclaimable: 0

            onRead: function(line) {
                if      (line.startsWith("MemTotal:"))          _total       = parseInt(line.split(/\s+/)[1])
                else if (line.startsWith("MemFree:"))           _free        = parseInt(line.split(/\s+/)[1])
                else if (line.startsWith("Buffers:"))           _buffers     = parseInt(line.split(/\s+/)[1])
                else if (line.startsWith("Cached:"))            _cached      = parseInt(line.split(/\s+/)[1])
                else if (line.startsWith("SReclaimable:"))      _reclaimable = parseInt(line.split(/\s+/)[1])
                else if (line.startsWith("MemAvailable:")) {
                    const available = parseInt(line.split(/\s+/)[1])
                    memPill.memTotal = _total / 1024 / 1024
                    memPill.memUsed  = (_total - available) / 1024 / 1024
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

    Text {
        id: memText
        anchors.centerIn: parent
        text: "MEM " + memPill.memUsed.toFixed(1) + " GB"
        color: Colors.primary
        font.pointSize: 11
        font.bold: true
        font.family: Fonts.font
    }
}

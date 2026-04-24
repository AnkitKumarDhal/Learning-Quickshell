import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: root

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight
    property var parentWindow

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    // Added ?.bound checks to prevent NaN layout crashes
    property int sinkVol: sink?.audio ? Math.round(sink.audio.volume * 100) : 0
    property int sourceVol: source?.audio ? Math.round(source.audio.volume * 100) : 0    
    property string deviceName: sink?.description || "Unknown Device"

    Pill {
        id: pill
        anchors.fill: parent
        onClicked: dropdown.isOpen = !dropdown.isOpen

        Text {
            text: "VOL"
            color: Colors.warn
            font.pixelSize: 11
            font.bold: true
        }

        Text {
            text: root.sinkVol + "%"
            color: Colors.foreground
            font.pixelSize: 13
        }
    }

    DropdownPanel {
        id: dropdown
        parentWindow: root.parentWindow
        targetPill: pill
        popupEdge: Edges.Bottom
        popupGap: 7

        Text {
            text: "Audio"
            color: Colors.foreground
            opacity: 0.5
            font.pixelSize: 11
            font.capitalization: Font.AllUppercase
        }

        Row {
            spacing: 10

            Text {
                text: "Master"
                color: Colors.foreground
                opacity: 0.7
                font.pixelSize: 12
                width: 45
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                id: masterTrack
                width: 120
                height: 4
                radius: 2
                color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.2)
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: masterTrack.width * (root.sinkVol / 100)
                    height: 4
                    radius: 2
                    color: Colors.accent

                    Rectangle {
                        width: 14; height: 14; radius: 7
                        color: Colors.accent
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: -7
                    }
                }

                MouseArea {
                    width: parent.width
                    height: 24
                    anchors.centerIn: parent

                    onPositionChanged: (mouse) => {
                        if (pressed && root.sink && root.sink.bound && root.sink.audio) {
                            let p = Math.max(0, Math.min(1, mouse.x / width));
                            root.sink.audio.volume = p;
                        }
                    }

                    onPressed: (mouse) => {
                        if (root.sink && root.sink.bound && root.sink.audio) {
                            let p = Math.max(0, Math.min(1, mouse.x / width));
                            root.sink.audio.volume = p;
                        }
                    }
                }
            }

            Text {
                text: root.sinkVol + "%"
                color: Colors.accent
                font.pixelSize: 12
                font.bold: true
                width: 35
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            spacing: 10

            Text {
                text: "Mic"
                color: Colors.foreground
                opacity: 0.7
                font.pixelSize: 12
                width: 45
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                id: micTrack
                width: 120
                height: 4
                radius: 2
                color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.2)
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: micTrack.width * (root.sourceVol / 100)
                    height: 4
                    radius: 2
                    color: Colors.accent2

                    Rectangle {
                        width: 14; height: 14; radius: 7
                        color: Colors.accent2
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: -7
                    }
                }

                MouseArea {
                    width: parent.width
                    height: 24
                    anchors.centerIn: parent

                    onPositionChanged: (mouse) => {
                        if (pressed && root.source && root.source.bound && root.source.audio) {
                            let p = Math.max(0, Math.min(1, mouse.x / width));
                            root.source.audio.volume = p;
                        }
                    }

                    onPressed: (mouse) => {
                        if (root.source && root.source.bound && root.source.audio) {
                            let p = Math.max(0, Math.min(1, mouse.x / width));
                            root.source.audio.volume = p;
                        }
                    }
                }
            }

            Text {
                text: root.sourceVol + "%"
                color: Colors.accent2
                font.pixelSize: 12
                font.bold: true
                width: 35
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Item { width: 1; height: 4 }
        
        Rectangle {
            width: parent.width
            height: 1
            color: Colors.pillBorder
        }

        Column {
            spacing: 2

            Text {
                text: "Output Device"
                color: Colors.foreground
                opacity: 0.45
                font.pixelSize: 11
            }

            Text {
                text: root.deviceName
                color: Colors.accent3
                font.pixelSize: 13
                font.bold: true
                width: 200
                elide: Text.ElideRight
            }
        }
    }
}

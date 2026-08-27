import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.src.theme

Item {
    id: root

    signal directoryAccepted(string directory)
    signal rescanRequested(string directory)
    signal escapeRequested()

    property string directory: "~/wallpapers"

    implicitHeight: 32

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            text:           "󰉋"
            color:          Colors.on_SurfaceVariant
            font.pixelSize: 14
            font.family:    Fonts.fontM
        }

        TextField {
            id: dirField

            Layout.fillWidth: true
            height:           32

            text:             root.directory

            font.family:      Fonts.font
            font.pixelSize:   12

            color:            Colors.on_Surface
            placeholderTextColor: Colors.outline
            placeholderText:  "Wallpaper directory…"

            onTextChanged: {
                if (!dirField.activeFocus && root.directory !== text) {
                    root.directory = text
                }
            }

            Keys.onReturnPressed: {
                root.directory = text
                root.directoryAccepted(text)
            }

            Keys.onEscapePressed: {
                root.escapeRequested()
            }

            background: Rectangle {
                radius:       8
                color:        Colors.surfaceContainerHigh
                border.width: 1

                border.color: dirField.activeFocus
                                  ? Colors.primary
                                  : Colors.outline

                Behavior on border.color {
                    ColorAnimation {
                        duration: Theme.hoverFadeDuration
                    }
                }
            }
        }

        // Rescan button
        Rectangle {
            width:  32
            height: 32
            radius: 8

            color: rescanHov.containsMouse
                        ? Qt.rgba(
                              Colors.primary.r,
                              Colors.primary.g,
                              Colors.primary.b,
                              0.15)
                        : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: Theme.hoverFadeDuration
                }
            }

            Text {
                anchors.centerIn: parent

                text:             "󰑐"

                font.family:      Fonts.fontM
                font.pixelSize:   16

                color:            rescanHov.containsMouse
                                  ? Colors.primary
                                  : Colors.on_SurfaceVariant
            }

            MouseArea {
                id:           rescanHov

                anchors.fill: parent

                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor

                onClicked: {
                    root.directory = dirField.text
                    root.rescanRequested(dirField.text)
                }
            }
        }
    }

    function updateDirectory(value) {
        if (dirField.text !== value) {
            dirField.text = value
        }
    }
}

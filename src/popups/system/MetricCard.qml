import QtQuick
import QtQuick.Layouts
import qs.src.theme

Item {
    id: root

    property string label: ""
    property string value: ""
    property string detail: ""
    property real progress: 0.0
    property color accent: Colors.primary

    implicitHeight: 78

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Colors.surfaceContainerHighest

        border.color: Colors.outlineVariant
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text:           root.label

                    font.family:    Fonts.fontM
                    font.pointSize: 11
                    font.bold:      true

                    color:          Colors.on_SurfaceVariant

                    Layout.fillWidth: true
                }

                Text {
                    text:           root.value

                    font.family:    Fonts.font
                    font.pixelSize: 16
                    font.bold:      true

                    color:          Colors.on_Surface
                }
            }

            Text {
                text:           root.detail

                font.family:    Fonts.font
                font.pixelSize: 10
                font.bold:      true

                color:          Colors.on_SurfaceVariant

                elide:          Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 5
                radius: 2.5
                color: Colors.surfaceContainer

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(root.progress, 1.0))
                    height: parent.height
                    radius: parent.radius
                    color: root.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: 450
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 250
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import qs.src.theme

Item {
    id: root

    signal applyRequested()

    property string filename:    "No wallpaper selected"
    property string metadata:    ""
    property int    index:       0
    property int    count:       0
    property bool   applying:    false
    property bool   applied:     false

    implicitHeight: 42

    RowLayout {
        anchors.fill: parent
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true

                text:             root.filename

                color:            Colors.on_SurfaceVariant
                font.family:      Fonts.font
                font.pixelSize:   11
                elide:            Text.ElideMiddle
            }

            Text {
                visible:          root.metadata !== ""

                Layout.fillWidth: true

                text:             root.metadata

                color:            Colors.outline
                font.family:      Fonts.font
                font.pixelSize:   9
                elide:            Text.ElideRight
            }
        }

        Text {
            visible:          root.count > 0

            text:             (root.index + 1) + " / " + root.count

            color:            Colors.outline
            font.family:      Fonts.font
            font.pixelSize:   11
        }

        Rectangle {
            width:  130
            height: 34
            radius: 17

            color: root.applying
                        ? Colors.surfaceContainerHighest
                        : applyHov.containsMouse
                            ? Colors.primaryContainer
                            : Colors.primary

            Behavior on color {
                ColorAnimation {
                    duration: Theme.hoverFadeDuration
                }
            }

            Text {
                anchors.centerIn: parent

                text: root.applying
                          ? "Applying…"
                          : root.applied
                              ? "↻ Re-apply"
                              : "󰀝 Apply Wallpaper"

                color: root.applying
                          ? Colors.on_SurfaceVariant
                          : root.applied
                              ? Colors.on_Primary
                              : Colors.on_Primary

                font.family:    Fonts.font
                font.pixelSize: 11
                font.bold:      true
            }

            MouseArea {
                id:           applyHov

                anchors.fill: parent

                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor

                enabled: !root.applying &&
                         root.count > 0

                onClicked: root.applyRequested()
            }
        }
    }
}

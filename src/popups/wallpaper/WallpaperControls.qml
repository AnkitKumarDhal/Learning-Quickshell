import QtQuick
import QtQuick.Layouts
import qs.src.theme

Item {
    id: root

    signal applyRequested()

    property string filename:    "No wallpaper selected"
    property int    index:       0
    property int    count:       0
    property bool   applying:    false
    property bool   applied:     false

    implicitHeight: 34

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            Layout.fillWidth: true

            text:             root.filename

            color:            Colors.on_SurfaceVariant
            font.family:      Fonts.font
            font.pixelSize:   11
            elide:            Text.ElideMiddle
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

            color: root.applying || root.applied
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
                              ? "󰄵 Applied"
                              : "󰀝 Apply Wallpaper"

                color: root.applying || root.applied
                          ? Colors.on_SurfaceVariant
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
                         !root.applied &&
                         root.count > 0

                onClicked: root.applyRequested()
            }
        }
    }
}

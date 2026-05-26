import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.src.theme

Item {
    id: root

    height: 36

    // ── Outputs ───────────────────────────────────────────────────────────
    readonly property alias text: field.text

    signal escapePressed()
    signal returnPressed()
    signal upPressed()
    signal downPressed()

    function clear()            { field.text = "" }
    function forceActiveFocus() { field.forceActiveFocus() }

    // ── Layout ────────────────────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            text: "😊"
            font.pixelSize: 16
            Layout.alignment: Qt.AlignVCenter
        }

        TextField {
            id: field

            Layout.fillWidth: true

            height: 32

            placeholderText: "Search emoji..."

            font.family: Fonts.font
            font.pixelSize: 12

            color: Colors.on_Surface
            placeholderTextColor: Colors.outline

            Keys.onEscapePressed: (event) => { root.escapePressed(); event.accepted = true }
            Keys.onReturnPressed: (event) => { root.returnPressed(); event.accepted = true }
            Keys.onEnterPressed:  (event) => { root.returnPressed(); event.accepted = true }
            Keys.onUpPressed:     (event) => { root.upPressed();     event.accepted = true }
            Keys.onDownPressed:   (event) => { root.downPressed();   event.accepted = true }

            background: Rectangle {
                radius: 8
                color: Colors.surfaceContainerHigh
                border.width: 1
                border.color: field.activeFocus ? Colors.primary : Colors.outline
                Behavior on border.color {
                    ColorAnimation { duration: Theme.hoverFadeDuration }
                }
            }
        }
    }
}

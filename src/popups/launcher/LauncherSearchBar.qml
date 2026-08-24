import QtQuick
import QtQuick.Layouts
import qs.src.theme

Item {
    id: root

    height: 56

    property int  resultCount: 0
    property bool showCount:   false

    readonly property alias text: searchInput.text

    signal escapePressed()
    signal returnPressed()
    signal upPressed()
    signal downPressed()
    signal tabPressed()

    function clear()            { searchInput.text = "" }
    function forceActiveFocus() { searchInput.forceActiveFocus() }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Text {
            text:             ""
            color:            Colors.primary
            font.pixelSize:   20
            font.family:      Fonts.font
            leftPadding:      18
            Layout.alignment: Qt.AlignVCenter
        }

        TextInput {
            id: searchInput
            Layout.fillWidth:  true
            Layout.leftMargin: 10
            Layout.alignment:  Qt.AlignVCenter

            color:          Colors.on_Surface
            selectionColor: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3)
            font.pixelSize: 16
            font.family:    Fonts.fontM
            clip:           true

            Text {
                anchors.fill:      parent
                verticalAlignment: Text.AlignVCenter
                text:              "Search applications…"
                color:             Colors.on_SurfaceVariant
                font:              parent.font
                visible:           parent.text === "" && !parent.activeFocus
                opacity:           0.5
            }

            Keys.onEscapePressed: (event) => {
                root.escapePressed()
                event.accepted = true
            }

            Keys.onReturnPressed: (event) => {
                root.returnPressed()
                event.accepted = true
            }

            Keys.onEnterPressed: (event) => {
                root.returnPressed()
                event.accepted = true
            }

            Keys.onUpPressed: (event) => {
                root.upPressed()
                event.accepted = true
            }

            Keys.onDownPressed: (event) => {
                root.downPressed()
                event.accepted = true
            }

            Keys.onTabPressed: (event) => {
                root.tabPressed()
                event.accepted = true
            }
        }

        Text {
            visible:          root.showCount
            text:             root.resultCount + " result" + (root.resultCount === 1 ? "" : "s")
            color:            Colors.on_SurfaceVariant
            font.pixelSize:   11
            font.family:      Fonts.font
            rightPadding:     14
            Layout.alignment: Qt.AlignVCenter
            opacity:          0.7
        }
    }
}

import QtQuick
import QtQuick.Layouts
import qs.src.theme

Item {
    id: root

    height: 56

    property int  resultCount: 0
    property bool showCount:   false
    property string mode:      "apps"
    property string modeLabel: ""

    readonly property alias text: searchInput.text

    signal escapePressed()
    signal returnPressed(bool focusExisting)
    signal upPressed()
    signal downPressed()
    signal tabPressed()
    signal homePressed()
    signal endPressed()
    signal rightPressed()
    signal leftPressed()
    signal pinPressed()

    function clear()            { searchInput.text = "" }
    function forceActiveFocus() { searchInput.forceActiveFocus() }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Text {
            text: root.mode === "command" ? ">" :
                root.mode === "calculator" ? "󰃬" :
                root.mode === "unit" ? "󰘂" :
                root.mode === "currency" ? "󰇹" :
                root.mode === "web" ||
                root.mode === "google" ||
                root.mode === "startpage" ? "󰖟" :
                "󰍉"

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
            font.family:     Fonts.fontM
            clip:            true

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter

                text: root.mode === "command"
                        ? "Run a command…"
                        : root.mode === "calculator"
                            ? "Calculate…"
                            : root.mode === "unit"
                                ? "Convert units…"
                                : root.mode === "currency"
                                    ? "Convert currency…"
                                    : root.mode === "web" || root.mode === "google" || root.mode === "startpage"
                                        ? "Search the web…"
                                        : "Search applications…"

                color:   Colors.on_SurfaceVariant
                font:    parent.font
                visible: parent.text === "" && !parent.activeFocus
                opacity: 0.5
            }

            Keys.onEscapePressed: (event) => {
                root.escapePressed()
                event.accepted = true
            }

            Keys.onReturnPressed: (event) => {
                root.returnPressed((event.modifiers & Qt.ShiftModifier) !== 0)
                event.accepted = true
            }

            Keys.onEnterPressed: (event) => {
                root.returnPressed((event.modifiers & Qt.ShiftModifier) !== 0)
                event.accepted = true
            }

            Keys.onPressed: (event) => {
                if ((event.modifiers & Qt.ControlModifier) &&
                    event.key === Qt.Key_P) {
                    root.pinPressed()
                    event.accepted = true
                    return
                }

                switch (event.key) {
                    case Qt.Key_Up:
                        root.upPressed()
                        event.accepted = true
                        break

                    case Qt.Key_Down:
                        root.downPressed()
                        event.accepted = true
                        break

                    case Qt.Key_Tab:
                        root.tabPressed()
                        event.accepted = true
                        break

                    case Qt.Key_Home:
                        root.homePressed()
                        event.accepted = true
                        break

                    case Qt.Key_End:
                        root.endPressed()
                        event.accepted = true
                        break

                    case Qt.Key_Right:
                        if (searchInput.cursorPosition >= searchInput.text.length) {
                            root.rightPressed()
                            event.accepted = true
                        }
                        break

                    case Qt.Key_Left:
                        if (searchInput.cursorPosition === 0) {
                            root.leftPressed()
                            event.accepted = true
                        }
                        break
                }
            }
        }

        Text {
            visible: root.showCount
            text: root.resultCount + " result" + (root.resultCount === 1 ? "" : "s")
            color:            Colors.on_SurfaceVariant
            font.pixelSize:   11
            font.family:      Fonts.font
            rightPadding:     14
            Layout.alignment: Qt.AlignVCenter
            opacity:          0.7
        }

        Text {
            visible: !root.showCount && root.modeLabel !== ""
            text: root.modeLabel
            color:            Colors.primary
            font.pixelSize:   11
            font.family:      Fonts.font
            rightPadding:     14
            Layout.alignment: Qt.AlignVCenter
            opacity:          0.8
        }
    }
}

import QtQuick
import QtQuick.Controls
import qs.src.theme

Item {
    id: root

    // ── Inputs ────────────────────────────────────────────────────────────
    property var emojis: []

    // ── Outputs ───────────────────────────────────────────────────────────
    signal emojiSelected(string emoji)
    signal typedChar(string ch)

    function forceActiveFocus() { grid.forceActiveFocus() }
    function resetIndex()       { grid.currentIndex = 0  }

    // ── Grid ──────────────────────────────────────────────────────────────
    GridView {
        id: grid

        anchors.fill: parent

        cellWidth:  44
        cellHeight: 44

        clip: true
        focus: true

        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        model: root.emojis

        Keys.onReturnPressed: (event) => {
            const e = root.emojis[currentIndex]
            if (e) root.emojiSelected(e)
            event.accepted = true
        }
        Keys.onEnterPressed: (event) => {
            const e = root.emojis[currentIndex]
            if (e) root.emojiSelected(e)
            event.accepted = true
        }
        Keys.onPressed: (event) => {
            if (event.text.length > 0 && event.key !== Qt.Key_Space && event.key !== Qt.Key_Return) {
                root.typedChar(event.text)
                event.accepted = true
            }
        }

        delegate: Rectangle {
            required property var modelData
            required property int index

            width:  grid.cellWidth
            height: grid.cellHeight

            radius: 8

            color: {
                if (index === grid.currentIndex) return Colors.primaryContainer
                if (hov.containsMouse)           return Colors.surfaceContainerHigh
                return "transparent"
            }

            Behavior on color {
                ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
            }

            Text {
                anchors.centerIn: parent
                text: modelData
                font.pixelSize: 22
            }

            ToolTip.visible: hov.containsMouse
            ToolTip.text: modelData
            ToolTip.delay: 400

            MouseArea {
                id: hov
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: grid.currentIndex = index
                onClicked: root.emojiSelected(modelData)
            }
        }
    }

    // ── Empty state ───────────────────────────────────────────────────────
    Text {
        anchors.centerIn: parent
        visible: !root.emojis || root.emojis.length === 0

        text: "No emoji found"

        font.family: Fonts.font
        font.pixelSize: 12

        color: Colors.outline
    }
}

import QtQuick
import QtQuick.Controls
import qs.src.theme

Item {
    id: root

    height: 34

    // ── Inputs ────────────────────────────────────────────────────────────
    property var categories:  []
    property int activeIndex: 0
    property bool searchActive: false

    // ── Outputs ───────────────────────────────────────────────────────────
    signal categorySelected(int index)

    // ── Tab strip ─────────────────────────────────────────────────────────
    ListView {
        anchors.fill: parent

        orientation: ListView.Horizontal
        spacing: 4

        clip: true
        boundsBehavior: Flickable.StopAtBounds

        model: root.categories

        delegate: Rectangle {
            required property var modelData
            required property int index

            width: tabLabel.implicitWidth + 16
            height: 30

            radius: 8

            color: {
                if (!root.searchActive && root.activeIndex === index)
                    return Colors.primaryContainer
                if (hov.containsMouse)
                    return Colors.surfaceContainerHigh
                return "transparent"
            }

            Behavior on color {
                ColorAnimation { duration: Theme.hoverFadeDuration }
            }

            Text {
                id: tabLabel
                anchors.centerIn: parent
                text: modelData.icon
                font.pixelSize: 16
            }

            ToolTip.visible: hov.containsMouse
            ToolTip.text: modelData.label
            ToolTip.delay: 600

            MouseArea {
                id: hov
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.categorySelected(index)
            }
        }
    }
}

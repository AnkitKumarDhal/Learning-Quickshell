import QtQuick
import Quickshell

PopupWindow {
    id: root

    property bool isOpen: false
    property alias content: container.data

    property var parentWindow
    property var targetPill

    visible: isOpen
    color: "transparent"

    width: container.implicitWidth + 28
    height: container.implicitHeight + 28

    anchor.window: parentWindow
    anchor.rect: targetPill ? targetPill.mapToItem(null, 0, 0, targetPill.width, targetPill.height) : Qt.rect(0, 0, 0, 0)

    anchor.edges: Edges.Bottom
    anchor.margins: Margins { top: 8 }

    Rectangle {
        id: panelBg
        anchors.fill: parent

        color: Colors.panelBackground
        border.color: Colors.pillBorder
        border.width: 1
        radius: 10

        opacity: root.isOpen ? 1.0 : 0.0
        scale: root.isOpen ? 1.0 : 0.95
        transformOrigin: Item.Top
    }
}

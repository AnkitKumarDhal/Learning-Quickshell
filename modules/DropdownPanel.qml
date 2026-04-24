import QtQuick
import Quickshell

PopupWindow {
    id: root

    property bool isOpen: false
    default property alias content: container.data

    property var parentWindow
    property var targetPill

    property int popupEdge: Edge.Bottom
    property int popupGap: 8

    visible: isOpen
    color: "transparent"

    width: container.implicitWidth + 28
    height: container.implicitHeight + 28

    anchor.window: parentWindow
    anchor.rect: {
        if (isOpen && targetPill) {
            return targetPill.mapToItem(null, 0, 0, targetPill.width, targetPill.height);
        }
        return Qt.rect(0, 0, 0, 0)
    }
    anchor.edges: root.popupEdge
    anchor.margins.top: (root.popupEdge & Edges.Bottom) ? root.popupGap : 0
    anchor.margins.bottom: (root.popupEdge & Edges.Top) ? root.popupGap : 0
    anchor.margins.left: (root.popupEdge & Edges.Right) ? root.popupGap : 0
    anchor.margins.right: (root.popupEdge & Edges.Left) ? root.popupGap : 0

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

        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on scale {
            SpringAnimation {
                spring: 4.0
                damping: 0.25
            }
        }

        Column {
            id: container
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8
        }
    }
}

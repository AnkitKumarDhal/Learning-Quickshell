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

    implicitWidth: container.implicitWidth + 28
    implicitHeight: container.implicitHeight + 28

    anchor.window: parentWindow
    anchor.rect: {
        if (isOpen && targetPill) {
            // Get the exact coordinates of the pill on the screen
            let r = targetPill.mapToItem(null, 0, 0, targetPill.width, targetPill.height);
            
            // Mathematically push the Wayland anchor box outwards based on the edge
            if (root.popupEdge & Edges.Bottom) { r.height += root.popupGap; }
            if (root.popupEdge & Edges.Top)    { r.y -= root.popupGap; r.height += root.popupGap; }
            if (root.popupEdge & Edges.Right)  { r.width += root.popupGap; }
            if (root.popupEdge & Edges.Left)   { r.x -= root.popupGap; r.width += root.popupGap; }
            
            return r;
        }
        return Qt.rect(0, 0, 0, 0);
    }
    anchor.edges: root.popupEdge

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

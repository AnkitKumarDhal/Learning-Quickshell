import QtQuick
import QtQuick.Controls
import "../theme"

// Scrollable content container for popup pages.
// Wrap your popup's inner content in this instead of a plain Column.
//
// Usage:
//   PopupPage {
//       anchors.fill: parent
//       // children go here
//   }

Item {
    id: root

    default property alias content: contentCol.data

    property int padH: 8
    property int padV: 8

    clip: true

    Flickable {
        id: flick
        anchors.fill:   parent
        contentWidth:   width
        contentHeight:  contentCol.implicitHeight + root.padV * 2
        boundsBehavior: Flickable.StopAtBounds
        clip:           true

        ScrollBar.vertical: ScrollBar {
            policy: contentCol.implicitHeight + root.padV * 2 > flick.height
                        ? ScrollBar.AlwaysOn
                        : ScrollBar.AlwaysOff
            contentItem: Rectangle {
                implicitWidth:  3
                implicitHeight: 40
                radius:         1.5
                color:          Qt.rgba(1, 1, 1, 0.25)
            }
            background: Item {}
        }

        Column {
            id: contentCol
            anchors {
                top:         parent.top
                topMargin:   root.padV
                left:        parent.left
                leftMargin:  root.padH
                right:       parent.right
                rightMargin: root.padH + 6
            }
            spacing: 8
        }
    }
}

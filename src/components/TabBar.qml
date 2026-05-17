import QtQuick
import qs.src.theme

// Reusable tab switcher — horizontal or vertical.
// Horizontal: icon + label pill row with bottom divider. Used by multi-tab popups.
// Vertical:   icon-only solid pill column. Reserved for future use.

Item {
    id: root

    property var    model:       []
    property string currentPage: ""
    property string orientation: "horizontal"

    signal pageChanged(string key)

    property string defaultPage: model.length > 0 ? model[0].key : ""
    function reset() { pageChanged(defaultPage) }

    implicitWidth:  orientation === "vertical"   ? 40 : 0
    implicitHeight: orientation === "horizontal" ? 40 : 0

    // ── Scroll to Cycle Tabs ──────────────────────────────────────────────────
    property bool _scrollBusy: false

    Timer {
        id:          scrollCooldown
        interval:    300
        onTriggered: root._scrollBusy = false
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            if (root._scrollBusy) return
            root._scrollBusy = true; scrollCooldown.restart()
            const keys = root.model.map(m => m.key)
            const dir  = event.angleDelta.y < 0 ? 1 : -1
            const idx  = (keys.indexOf(root.currentPage) + dir + keys.length) % keys.length
            root.pageChanged(keys[idx])
        }
    }

    // ── Horizontal ────────────────────────────────────────────────────────────
    Row {
        id:           hRow
        anchors.fill: parent
        visible:      root.orientation === "horizontal"

        Repeater {
            model: root.orientation === "horizontal" ? root.model : []

            delegate: Item {
                id: hTab
                readonly property bool isActive: root.currentPage === modelData.key

                width:  hRow.width / root.model.length
                height: hRow.height

                Rectangle {
                    anchors.centerIn: parent
                    width:            hIcon.implicitWidth + (hLabel.visible ? hLabel.implicitWidth + 8 : 0) + 24
                    height:           parent.height - 8
                    radius:           height / 2
                    color:            hTab.isActive ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18) 
                                                    : (hHov.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent")
                    
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing:          6

                    Text {
                        id:                     hIcon
                        text:                   modelData.icon
                        font.pixelSize:         14
                        font.family:            Fonts.font
                        anchors.verticalCenter: parent.verticalCenter
                        color:                  hTab.isActive ? Colors.primary : (hHov.containsMouse ? Qt.rgba(1,1,1,0.75) : Qt.rgba(1,1,1,0.4))
                        
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Text {
                        id:                     hLabel
                        visible:                modelData.label !== undefined
                        text:                   modelData.label ?? ""
                        font.pixelSize:         12
                        font.bold:              hTab.isActive
                        font.family:            Fonts.font
                        anchors.verticalCenter: parent.verticalCenter
                        color:                  hTab.isActive ? Colors.primary : (hHov.containsMouse ? Qt.rgba(1,1,1,0.75) : Qt.rgba(1,1,1,0.4))
                        
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }

                MouseArea {
                    id:           hHov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    root.pageChanged(modelData.key)
                }
            }
        }
    }

    // Bottom divider — horizontal only
    Rectangle {
        visible:        root.orientation === "horizontal"
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         1
        color:          Colors.outlineVariant
        opacity:        0.5
    }

    // ── Vertical ──────────────────────────────────────────────────────────────
    Column {
        id:               vCol
        anchors.centerIn: parent
        visible:          root.orientation === "vertical"

        readonly property int tabH: 60
        spacing: root.model.length > 1 ? (root.height - root.model.length * tabH) / (root.model.length - 1) : 0

        Repeater {
            model: root.orientation === "vertical" ? root.model : []

            delegate: Rectangle {
                id: vTab
                readonly property bool isActive: root.currentPage === modelData.key

                width:  40
                height: vCol.tabH
                radius: Theme.pillRadius
                color:  vTab.isActive ? Colors.primary : (vHov.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent")
                
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text:             modelData.icon
                    font.pixelSize:   16
                    font.family:      Fonts.font
                    color:            vTab.isActive ? Colors.on_Primary : Colors.primary
                    
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id:           vHov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    root.pageChanged(modelData.key)
                }
            }
        }
    }
}

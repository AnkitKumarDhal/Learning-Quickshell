import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.src.theme

PanelWindow {
    id: root

    property var  menuHandle: null
    property real menuX:      0
    property real menuY:      0
    property bool hasCurrent: false
    property int  animLength: 400
    property var  animCurve:  [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]

    function open(handle, x, y) {
        menuHandle = handle
        let w      = 240
        let safeX  = x - (w / 2)
        safeX      = Math.max(8, Math.min(safeX, Screen.width - w - 8))
        menuX      = safeX
        menuY      = y - 32
        hasCurrent = true
        grabTimer.restart()
    }

    function close() {
        hasCurrent       = false
        focusGrab.active = false
        grabTimer.stop()
    }

    color: "transparent"
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: hasCurrent
                                     ? WlrKeyboardFocus.Exclusive
                                     : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        id:        focusGrab
        windows:   [root]
        onCleared: root.close()
    }

    Timer {
        id:          grabTimer
        interval:    50
        onTriggered: focusGrab.active = true
    }

    anchors { top: true; bottom: true; left: true; right: true }

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        enabled:      root.hasCurrent
        onClicked:    root.close()
    }

    Item {
        id: wrapper

        readonly property real topPad:        8
        readonly property real bottomPad:     8
        readonly property real contentHeight: topPad + menuColumn.implicitHeight + bottomPad

        x:     root.menuX
        y:     root.menuY
        width: 240

        visible:        height > 0
        clip:           true
        implicitHeight: root.hasCurrent ? Math.max(contentHeight, 52) : 0

        Rectangle {
            id:               menuBg
            anchors.fill:     parent
            color:            Colors.background
            clip:             true
            bottomLeftRadius: 14
            bottomRightRadius: 14

            QsMenuOpener {
                id:   opener
                menu: root.menuHandle
            }

            Rectangle {
                id: highlight

                property real targetY: 0
                property bool active:  false

                x:       8
                y:       menuColumn.y + targetY
                width:   parent.width - 16
                height:  36
                radius:  8
                color:   Colors.primary
                opacity: active ? 0.15 : 0

                Behavior on y       { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            Column {
                id: menuColumn

                anchors {
                    top:         parent.top
                    left:        parent.left
                    right:       parent.right
                    topMargin:   8
                    leftMargin:  8
                    rightMargin: 8
                }
                spacing: 2

                onChildrenChanged: highlight.active = false

                Repeater {
                    model: opener.children

                    delegate: Item {
                        id: menuItem

                        required property var modelData
                        required property int index

                        property bool isSeparator: modelData.isSeparator
                        property bool hasChildren: modelData.hasChildren

                        width:  menuColumn.width
                        height: isSeparator ? 12 : 36

                        // Separator line
                        Rectangle {
                            visible:          isSeparator
                            anchors.centerIn: parent
                            width:            parent.width - 16
                            height:           1
                            color:            Colors.primary
                            opacity:          0.5
                        }

                        // Active indicator bar
                        Rectangle {
                            visible: !isSeparator
                                     && highlight.active
                                     && highlight.targetY === menuItem.y
                            width:  3
                            height: 16
                            radius: 2
                            color:  Colors.primary
                            anchors {
                                left:           parent.left
                                leftMargin:     4
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        RowLayout {
                            visible: !isSeparator
                            anchors {
                                fill:        parent
                                leftMargin:  12
                                rightMargin: 12
                            }
                            spacing: 12

                            Item {
                                Layout.preferredWidth:  20
                                Layout.preferredHeight: 20

                                Image {
                                    anchors.centerIn: parent
                                    width:       16
                                    height:      16
                                    source:      modelData.icon || ""
                                    fillMode:    Image.PreserveAspectFit
                                    visible:     modelData.icon !== undefined
                                                 && modelData.icon !== ""
                                    layer.enabled: true
                                    layer.effect: ColorOverlay {
                                        color: Colors.primary
                                    }
                                }
                            }

                            Text {
                                text:              modelData.text || ""
                                color:             Colors.primary
                                Layout.fillWidth:  true
                                elide:             Text.ElideRight
                                font.pixelSize:    13
                                font.bold:         true
                                font.family:       Fonts.font
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                visible:           menuItem.hasChildren
                                text:              "›"
                                color:             Colors.primary
                                font.pixelSize:    16
                                font.bold:         true
                                opacity:           0.7
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // QsMenuAnchor for native submenu display
                        QsMenuAnchor {
                            id:      anchor
                            menu:    menuItem.hasChildren ? menuItem.modelData : null
                            // visible: false

                            // Anchor to right edge of this item
                            anchor.window:     root
                            anchor.rect.x:     menuItem.x + wrapper.x + menuBg.x + menuColumn.x + menuItem.width
                            anchor.rect.y:     menuItem.y + wrapper.y + menuBg.y + menuColumn.y
                            anchor.rect.width: 0
                            anchor.rect.height: menuItem.height
                            anchor.edges:      Edges.Right | Edges.Top
                        }

                        MouseArea {
                            id:           itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  isSeparator
                                              ? Qt.ArrowCursor
                                              : Qt.PointingHandCursor

                            onEntered: {
                                if (!menuItem.isSeparator) {
                                    highlight.targetY = menuItem.y
                                    highlight.active  = true
                                }
                            }

                            onClicked: {
                                if (menuItem.isSeparator) return
                                if (menuItem.hasChildren) {
                                    anchor.open()
                                } else {
                                    menuItem.modelData.triggered()
                                    root.close()
                                }
                            }
                        }
                    }
                }
            }
        }

        Behavior on implicitHeight {
            NumberAnimation {
                duration:           root.animLength
                easing.type:        Easing.BezierSpline
                easing.bezierCurve: root.animCurve
            }
        }
    }

    mask: Region {
        item: hasCurrent ? root.contentItem : null
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.src.components
import qs.src.theme

PillBase {
    id: root

    property var window

    hoverExpand: false  // tray expands differently via its own toggle
    hoverEnabled: false
    mouseEnabled: false
    visible: SystemTray.items.values.length > 0

    Row {
        id: trayRow
        spacing: 10

        Repeater {
            model: SystemTray.items.values

            delegate: Item {
                id: trayDelegate
                required property var modelData

                width:  20
                height: 20

                Image {
                    anchors.fill: parent
                    source: modelData.icon || ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton)
                            modelData.activate()
                        else if (mouse.button === Qt.MiddleButton)
                            modelData.secondaryActivate()
                        else if (mouse.button === Qt.RightButton) {
                            var pos = mapToItem(null, mouse.x, mouse.y)
                            modelData.display(root.window, pos.x, pos.y)
                        }
                    }

                    onWheel: (wheel) => {
                        modelData.scroll(wheel.angleDelta.y > 0 ? 1 : -1, false)
                    }
                }
            }
        }
    }
}


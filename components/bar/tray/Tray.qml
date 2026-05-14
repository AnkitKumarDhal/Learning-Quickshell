import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../../../settings"

Rectangle {
    id: trayPill

    visible: SystemTray.items.values.length > 0
    implicitWidth: trayLayout.implicitWidth + 32
    implicitHeight: 30
    radius: 15
    color: Colors.background

    RowLayout {
        id: trayLayout
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: SystemTray.items.values

            delegate: Item {
                id: trayDelegate
                required property var modelData

                implicitWidth: 20
                implicitHeight: 20

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
                        if (mouse.button === Qt.LeftButton) {
                            modelData.activate()
                        } else if (mouse.button === Qt.MiddleButton) {
                            modelData.secondaryActivate()
                        } else if (mouse.button === Qt.RightButton) {
                            var pos = mapToGlobal(width/2, height)
                            contextMenu.open(modelData.menu, pos.x, pos.y)
                        }
                    }

                    onWheel: (wheel) => {
                        modelData.scroll(wheel.angleDelta.y > 0 ? 1 : -1, false)
                    }
                }
            }
        }
    }

    TrayContextMenu {
        id: contextMenu
    }
}

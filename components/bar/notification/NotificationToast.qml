import QtQuick
import Quickshell
import QtQuick.Layouts
import Quickshell.Wayland
import "../../../settings"
// import "../../../services"

PanelWindow {
    id: toastWindow

    property var screen
    anchors {
        top: true
        right: true
    }

    margins {
        top: 48
        right: 8
    }

    implicitWidth: 350
    implicitHeight: toastLayout.implicitHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    ColumnLayout {
        id: toastLayout
        width: parent.width
        spacing: 10

        Repeater {
            model: notifService.server.trackedNotifications

            delegate: Rectangle {
                id: toastDelegate
                required property var modelData

                property bool showAsToast: true

                visible: showAsToast && !notifService.panelVisible

                Layout.fillWidth: true
                Layout.preferredHeight: visible ? (col.implicitHeight + 20) : 0

                color: Colors.surfaceContainerHighest
                radius: 12
                border.color: Colors.primary
                border.width: 1

                Timer {
                    interval: 3500
                    running: true
                    onTriggered: toastDelegate.showAsToast = false
                }

                ColumnLayout {
                    id: col
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 4
                    visible: toastDelegate.visible

                    Text {
                        text: modelData.summary
                        color: Colors.primary
                        font.family: Fonts.font
                        font.bold: true
                        font.pointSize: 11
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: modelData.body
                        color: Colors.on_surface
                        font.family: Fonts.font
                        font.pointSize: 10
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}

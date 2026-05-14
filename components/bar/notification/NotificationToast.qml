import QtQuick
import Quickshell
import QtQuick.Layouts
import Quickshell.Wayland
import "../../../settings"
import "../../../services"

PanelWindow {
    id: toastWindow

    property var screen
    anchors {
        top: true
        right: true
    }

    margins {
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
        spacing: 6

        Repeater {
            model: NotificationService.server.trackedNotifications.values

            delegate: Item {
                id: toastDelegate
                required property var modelData

                property bool showAsToast: true

                Layout.fillWidth: true
                // Animate height in/out instead of popping
                Layout.preferredHeight: visible ? toastInner.implicitHeight : 0
                visible: showAsToast && !NotificationService.panelVisible
                clip: true

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
                    }
                }

                Timer {
                    interval: 3500
                    running: true
                    onTriggered: toastDelegate.showAsToast = false
                }

                Rectangle {
                    id: toastInner
                    width: parent.width
                    implicitHeight: toastCol.implicitHeight + 16
                    color: Colors.background
                    radius: 14
                    border.color: Colors.primary
                    border.width: 1

                    Rectangle {
                        id: toastHighlight
                        anchors.fill: parent
                        radius: parent.radius
                        color: Colors.primary
                        opacity: toastMouse.containsMouse ? 0.08 : 0

                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    // Accent bar
                    Rectangle {
                        width: 3
                        height: 16
                        radius: 2
                        color: Colors.primary
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    ColumnLayout {
                        id: toastCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.topMargin: 8
                        anchors.leftMargin: 20
                        anchors.rightMargin: 12
                        anchors.bottomMargin: 8
                        spacing: 3

                        Text {
                            text: modelData.summary
                            color: Colors.primary
                            font.family: Fonts.font
                            font.bold: true
                            font.pixelSize: 13
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.body
                            color: Colors.primary
                            opacity: 0.7
                            font.family: Fonts.font
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            visible: modelData.body !== ""
                        }
                    }

                    MouseArea {
                        id: toastMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: toastDelegate.showAsToast = false
                    }
                }
            }
        }
    }
}

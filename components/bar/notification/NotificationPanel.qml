import QtQuick
import Quickshell
import QtQuick.Layouts
import Quickshell.Wayland
import "../../../services"
import "../../../settings"

PanelWindow {
    id: notifPanel

    property var screen
    visible: NotificationService.panelVisible

    anchors {
        top: true
        right: true
    }

    margins {
        // top: 18
        right: 8
    }

    implicitWidth: 350
    implicitHeight: 500
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Rectangle {
        anchors.fill: parent
        color: Colors.surfaceContainer
        radius: 12
        border.color: Colors.outline
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                text: "Notification Panel"
                color: Colors.on_Surface
                font.family: Fonts.font
                font.bold: true
                font.pointSize: 14
                Layout.fillWidth: true
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: NotificationService.server.trackedNotifications.values
                spacing: 10
                clip: true

                delegate: Rectangle {
                    required property var modelData

                    width: ListView.view.width
                    implicitHeight: contentCol.implicitHeight + 20
                    color: Colors.surface
                    radius: 8
                    border.color: Colors.outlineVariant
                    border.width: 1

                    ColumnLayout {
                        id: contentCol
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 4

                        Text {
                            text: modelData.summary
                            color: Colors.primary
                            font.bold: true
                            font.family: Fonts.font
                            font.pointSize: 11
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.body
                            color: Colors.on_Surface
                            font.family: Fonts.font
                            font.pointSize: 10
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                            maximumLineCount: 5
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: modelData.dismiss()
                    }
                }
            }
        }
    }
}

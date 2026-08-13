import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.src.components
import qs.src.services
import qs.src.theme

PanelWindow {
    id: root

    required property var screen

    screen: root.screen

    readonly property bool focusedScreen: {
        const monitor = Hyprland.monitorFor(root.screen)
        return monitor ? monitor.focused : false
    }

    property string responseText: ""

    visible: slidePanel.windowVisible && root.focusedScreen

    implicitHeight: popupRect.height + 32

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: Theme.barHeight + 8
    }

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: slidePanel.windowVisible && root.focusedScreen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    PopupSlide {
        id: slidePanel

        anchors.fill: parent

        edge: "top"

        open: PolkitService.active && root.focusedScreen

        Rectangle {
            id: popupRect

            width: 520
            height: popupContent.implicitHeight + 48

            anchors.horizontalCenter: parent.horizontalCenter

            color: Colors.surfaceContainer
            radius: Theme.popupRadius

            border.width: 1
            border.color: Colors.outlineVariant


            ColumnLayout {
                id: popupContent

                anchors {
                    fill: parent
                    margins: 24
                    topMargin: 12
                }

                spacing: 14

                Text {
                    Layout.fillWidth: true

                    text: "Authentication Required"

                    color: Colors.on_Surface

                    font.family: Fonts.font
                    font.pixelSize: 16
                    font.bold: true

                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    Layout.fillWidth: true

                    Layout.preferredHeight: 1

                    color: Colors.outlineVariant
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true

                            text: PolkitService.message

                            horizontalAlignment: Text.AlignLeft

                            color: Colors.on_Surface
                            font.pixelSize: 14
                            font.bold: false
                            font.family: Fonts.font
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true

                            visible: PolkitService.supplementaryMessage.length > 0
                            text: PolkitService.supplementaryMessage

                            color: PolkitService.supplementaryIsError ? Colors.error : Colors.on_SurfaceVariant

                            font.family: Fonts.font
                            font.pixelSize: 12

                            wrapMode: Text.WordWrap
                        }
                    }
                }

                TextField {
                    id: responseField

                    Layout.fillWidth: true
                    visible: PolkitService.responseRequired

                    height: 36

                    leftPadding: 12
                    rightPadding: 12
                    topPadding: 8
                    bottomPadding: 8

                    echoMode: PolkitService.responseVisible ? TextInput.Normal : TextInput.Password

                    background: Rectangle {
                        color: Colors.surfaceContainerHighest
                        radius: 10

                        border.width: 1
                        border.color: Colors.outlineVariant
                    }

                    text: root.responseText
                    placeholderText: "Password"

                    onTextChanged: root.responseText = text

                    color: Colors.on_Surface
                    selectionColor: Colors.primary
                    selectedTextColor: Colors.on_Primary
                    placeholderTextColor: Colors.on_SurfaceVariant

                    Keys.onReturnPressed: (event) => {
                        root.submit()
                        event.accepted = true
                    }

                    Keys.onEscapePressed: (event) => {
                        PolkitService.cancel()
                        event.accepted = true
                    }
                }

                Text {
                    Layout.fillWidth: true

                    visible: PolkitService.failed
                    text: "Authentication Failed. Try Again."

                    color: Colors.error
                    font.family: Fonts.font
                    font.pixelSize: 12

                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "Cancel"

                        enabled: PolkitService.active
                        onClicked: PolkitService.cancel()

                        background: Rectangle {
                            color: Colors.surfaceContainerHighest
                            radius: 10

                            border.width: 1
                            border.color: Colors.outlineVariant
                        }

                        contentItem: Text {
                            text: parent.text

                            color: Colors.on_Surface

                            font.family: Fonts.font
                            font.pixelSize: 12
                            font.bold: true

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            leftPadding: 6
                            rightPadding: 6
                            topPadding: 2
                            bottomPadding: 2
                        }
                    }

                    Button {
                        text: "Authenticate"

                        enabled: PolkitService.active && PolkitService.responseRequired && responseField.text.length > 0
                        onClicked: root.submit()

                        background: Rectangle {
                            color: Colors.primary
                            radius: 10
                        }

                        contentItem: Text {
                            text: parent.text

                            color: Colors.on_Primary

                            font.family: Fonts.font
                            font.pixelSize: 12
                            font.bold: true

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            leftPadding: 6
                            rightPadding: 6
                            topPadding: 2
                            bottomPadding: 2
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: PolkitService

        function onResponseRequiredChanged() {
            if (PolkitService.responseRequired) {
                responseField.clear()
                root.responseText = ""
                responseField.forceActiveFocus()
            }
        }

        function onFailedChanged() {
            if (PolkitService.failed) {
                responseField.clear()
                root.responseText = ""
                responseField.forceActiveFocus()
            }
        }
    }

    Connections {
        target: slidePanel

        function onWindowVisibleChanged() {
            if (!slidePanel.windowVisible) {
                responseField.clear()
                root.responseText = ""

                PolkitService.clearPresentation()
            }
        }
    }

    function submit() {
        if (!PolkitService.responseRequired)
            return

        PolkitService.submit(responseField.text)
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.src.components
import qs.src.services
import qs.src.theme

PopupSlide {
    id: root

    open: PolkitService.active

    required property var screen

    property string responseText: ""

    PanelWindow {
        id: window

        screen: root.screen

        implicitHeight: 320

        anchors {
            top: true
            left: true
            right: true
        }

        color: "transparent"

        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            id: popupRect

            width: 520
            height: popupContent.implicitHeight + 48

            anchors.horizontalCenter: parent.horizontalCenter

            color: Colors.surfaceContainer
            radius: Theme.popupRadius

            ColumnLayout {
                id: popupContent
                anchors {
                    fill: parent
                    margins: 24
                }

                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Image {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

                        source: PolkitService.iconName ? Quickshell.iconPath(PolkitService.iconName, true) : ""

                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true

                            text: PolkitService.message
                            color: Colors.on_Surface
                            font.pixelSize: 17
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: PolkitService.supplementaryMessage.length > 0
                            text: PolkitService.supplementaryMessage
                            color: PolkitService.supplementaryIsError ? Colors.error : Colors.on_SurfaceVariant
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: PolkitService.responseRequired
                    text: PolkitService.inputPrompt.length > 0 ? PolkitService.inputPrompt : "Password"
                    color: Colors.on_Surface
                }

                TextField {
                    id: responseField
                    Layout.fillWidth: true
                    visible: PolkitService.responseRequired
                    echoMode: PolkitService.responseVisible ? TextInput.Normal : TextInput.Password

                    background: Rectangle {
                        color: Colors.surfaceContainerHighest
                        radius: 10
                        border.width: 1
                        border.color: Colors.outlineVariant
                    }
                    text: root.responseText
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
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        text: "Authenticate"
                        enabled: PolkitService.responseRequired && responseField.text.length > 0

                        background: Rectangle {
                            color: Colors.primary
                            radius: 10
                        }

                        contentItem: Text {
                            text: parent.text
                            color: Colors.on_Primary
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: root.submit()
                    }
                }
            }
        }
    }

    function submit() {
        if (!PolkitService.responseRequired)
            return

        PolkitService.submit(responseField.text)
        responseField.clear()
    }

    Connections {
        target: PolkitService.flow

        function onAuthenticationSucceeded() {
            root.responseText = ""
        }

        function onAuthenticationFailed() {
            responseField.clear()
            responseField.forceActiveFocus()
        }

        function onAuthenticationRequestCancelled() {
            responseField.clear()
        }

        function onIsResponseRequiredChanged() {
            if (PolkitService.responseRequired) {
                responseField.clear()
                root.responseText = ""
                responseField.forceActiveFocus()
            }
        }
    }

    Component.onCompleted: {
        if (PolkitService.active)
            responseField.forceActiveFocus()
    }
}

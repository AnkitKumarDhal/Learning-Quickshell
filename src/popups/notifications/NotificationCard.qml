import QtQuick
import QtQuick.Layouts
import qs.src.theme
import qs.src.services

Rectangle {
    id: root

    required property var notification

    property int bodyMaximumLineCount: 3

    implicitHeight: cardColumn.implicitHeight + 24
    height: implicitHeight

    radius: Theme.popupRadius
    color: Colors.surfaceContainerHigh
    border.color: Colors.outlineVariant
    border.width: Theme.popupBorder

    ColumnLayout {
        id: cardColumn

        anchors {
            fill: parent
            topMargin: 14
            leftMargin: 16
            rightMargin: 16
            bottomMargin: 16
        }

        spacing: 0

        RowLayout {
            id: notificationContent

            Layout.fillWidth: true
            implicitHeight: Math.max(36, contentColumn.implicitHeight)
            spacing: 10

            Rectangle {
                id: appIconBackground

                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignTop

                radius: 8
                color: Colors.primaryContainer

                Image {
                    id: appIcon

                    anchors.centerIn: parent

                    width: 22
                    height: 22

                    source: root.notification && root.notification.appIcon
                        ? "image://icon/" + root.notification.appIcon
                        : ""

                    visible: status === Image.Ready

                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                Text {
                    anchors.centerIn: parent

                    visible: appIcon.status !== Image.Ready

                    text: "󰂚"

                    font.pixelSize: 16
                    font.family: Fonts.font

                    color: Colors.on_PrimaryContainer
                }
            }

            ColumnLayout {
                id: contentColumn

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop

                spacing: 5

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.notification
                            ? root.notification.appName
                            : ""

                        color: Colors.on_SurfaceVariant

                        font.pixelSize: 10
                        font.family: Fonts.font

                        Layout.fillWidth: true

                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    Text {
                        text: root.notification
                            ? NotificationService.formatTimestamp(root.notification)
                            : ""

                        color: Colors.outline

                        font.pixelSize: 10
                        font.family: Fonts.font

                        textFormat: Text.PlainText
                    }
                }

                Text {
                    text: root.notification
                        ? root.notification.summary
                        : ""

                    color: Colors.on_Surface

                    font.pixelSize: 12
                    font.bold: true
                    font.family: Fonts.font

                    Layout.fillWidth: true

                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                Text {
                    visible: !!root.notification && root.notification.body !== ""
                    text: root.notification
                        ? root.notification.body
                        : ""

                    color: Colors.on_SurfaceVariant

                    font.pixelSize: 11
                    font.family: Fonts.font

                    Layout.fillWidth: true

                    maximumLineCount: root.bodyMaximumLineCount
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap

                    textFormat: Text.PlainText
                }
            }

            Rectangle {
                id: dismissButton

                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignTop

                radius: 10

                color: dismissArea.containsMouse
                    ? Qt.rgba(1, 1, 1, 0.12)
                    : "transparent"

                z: 2

                Text {
                    anchors.centerIn: parent

                    text: "󰅖"

                    font.pixelSize: 11
                    font.family: Fonts.font

                    color: Colors.on_SurfaceVariant
                }

                MouseArea {
                    id: dismissArea

                    anchors.fill: parent

                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: NotificationService.dismiss(root.notification)
                }
            }
        }

        Flow {
            id: actionFlow

            visible: !!root.notification &&
                     root.notification.actions &&
                     root.notification.actions.length > 0

            Layout.fillWidth: true
            Layout.topMargin: 6

            spacing: 6

            Repeater {
                model: root.notification
                    ? root.notification.actions
                    : []

                delegate: Rectangle {
                    id: actionButton

                    required property var modelData

                    width: Math.min(
                        actionText.implicitWidth + 24,
                        root.width - 24
                    )

                    height: 30

                    radius: 14

                    color: actionMouse.containsMouse
                        ? Colors.primaryContainer
                        : Colors.surfaceContainer

                    border.color: Colors.outlineVariant
                    border.width: 1

                    Text {
                        id: actionText

                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }

                        leftPadding: 12
                        rightPadding: 12

                        text: actionButton.modelData
                            ? actionButton.modelData.text
                            : ""

                        color: actionMouse.containsMouse
                            ? Colors.on_PrimaryContainer
                            : Colors.on_SurfaceVariant

                        font.pixelSize: 10
                        font.family: Fonts.font

                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        maximumLineCount: 1
                    }

                    MouseArea {
                        id: actionMouse

                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (actionButton.modelData)
                                actionButton.modelData.invoke()
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                }
            }
        }
    }
}

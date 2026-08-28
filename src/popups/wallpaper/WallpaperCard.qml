import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import qs.src.theme

Item {
    id: root

    signal clicked()

    property string sourcePath: ""
    property string thumbnailPath: ""
    property bool   thumbReady: false
    property bool   selected:   false
    property bool   active:     false
    property bool   applying:   false

    property int thumbnailWidth: 420
    property int thumbnailHeight: 280

    property real visualScale:   1.0
    property real visualOpacity: 1.0
    property real visualOffsetY: 0
    property real visualZ:       0

    width:  500
    height: 280

    Rectangle {
        id: thumbCard

        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter:   parent.verticalCenter
        }

        width:  parent.width
        height: parent.height

        radius: 16

        color: Colors.surfaceContainerHigh
        clip:  false

        scale:   root.visualScale
        opacity: root.visualOpacity

        y: root.visualOffsetY

        Image {
            id: wallpaperImage
            anchors.fill: parent
            source: root.thumbReady
                        ? ("file://" + root.thumbnailPath)
                        : ("file://" + root.sourcePath)

            sourceSize: Qt.size(root.thumbnailWidth, root.thumbnailHeight)
            fillMode:     Image.PreserveAspectCrop
            asynchronous: true
            cache:        true

            layer.enabled: true

            layer.effect: OpacityMask {
                maskSource: imageMask
            }
        }

        Rectangle {
            id: imageMask

            anchors.fill: parent

            radius:       thumbCard.radius
            color:        "white"
            visible:      false
        }

        Rectangle {
            anchors.fill: parent

            color:   Colors.background
            opacity: root.selected
                          ? 0.0
                          : 0.35
        }

        Rectangle {
            visible: root.active

            anchors {
                top:     parent.top
                left:    parent.left
                margins: 10
            }

            width:  80
            height: 26
            radius: 13

            color: Qt.rgba(
                Colors.primary.r,
                Colors.primary.g,
                Colors.primary.b,
                0.92)

            RowLayout {
                anchors.centerIn: parent
                spacing: 5

                Text {
                    text:           "󰄵"
                    color:          Colors.on_Primary
                    font.pixelSize: 11
                    font.family:    Fonts.font
                }

                Text {
                    text:           "Current"
                    color:          Colors.on_Primary
                    font.pixelSize: 10
                    font.bold:      true
                    font.family:    Fonts.font
                }
            }
        }

        Rectangle {
            id: vignette

            visible: root.selected

            anchors {
                left:   parent.left
                right:  parent.right
                bottom: parent.bottom
            }

            height: 62

            radius: thumbCard.radius
            color:  "transparent"

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color:    "transparent"
                }

                GradientStop {
                    position: 1.0
                    color: Qt.rgba(
                        Colors.background.r,
                        Colors.background.g,
                        Colors.background.b,
                        0.82)
                }
            }
        }

        Text {
            visible: root.selected

            anchors {
                left:         parent.left
                right:        parent.right
                bottom:       parent.bottom
                leftMargin:   14
                rightMargin:  14
                bottomMargin: 12
            }

            text:         root.sourcePath.split("/").pop()
            color:        Colors.on_Surface
            font.pixelSize: 11
            font.bold:      true
            font.family:    Fonts.font
            elide:         Text.ElideMiddle
        }

        // Applying spinner overlay
        Item {
            anchors.fill: parent

            visible: root.applying && root.selected

            Rectangle {
                anchors.fill: parent

                color: Qt.rgba(
                    Colors.background.r,
                    Colors.background.g,
                    Colors.background.b,
                    0.55)
            }

            Text {
                anchors.centerIn: parent

                text:             "󰑐"

                color:            Colors.primary
                font.pixelSize:   28
                font.family:      Fonts.fontM

                NumberAnimation on rotation {
                    from:     0
                    to:       360
                    duration: 1000
                    loops:    Animation.Infinite
                    running:  root.applying && root.selected
                }
            }
        }

        Rectangle {
            anchors.fill: parent

            radius:       thumbCard.radius
            color:        "transparent"

            border.width: root.selected ? 2 : 0
            border.color: Colors.primary
        }

        MouseArea {
            anchors.fill: parent

            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor

            onClicked: root.clicked()
        }
    }
}

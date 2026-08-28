import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.src.theme
import qs.src.services

Item {
    id: root

    property var pinnedApps: []
    property var recentApps: []

    signal launched(var app)

    readonly property int slotW:    48
    readonly property int slotGap:  4
    readonly property int maxSlots: 8

    readonly property int totalAvailable:
        Math.min(
            root.maxSlots,
            Math.max(
                1,
                Math.floor(
                    (width - 32) /
                    (root.slotW + root.slotGap)
                )
            )
        )

    readonly property int pinnedSlots:
        Math.min(
            root.pinnedApps.length,
            Math.min(
                4,
                root.totalAvailable
            )
        )

    readonly property int recentSlots:
        Math.min(
            root.recentApps.length,
            Math.max(
                0,
                root.totalAvailable -
                root.pinnedSlots
            )
        )

    readonly property int totalSlots:
        root.pinnedSlots +
        root.recentSlots

    height: 54

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 16
            rightMargin: 16
        }

        spacing: root.slotGap

        Repeater {
            model: root.pinnedSlots

            delegate: Item {
                required property int index

                Layout.preferredWidth:
                    root.slotW

                Layout.preferredHeight:
                    root.slotW

                Layout.alignment:
                    Qt.AlignVCenter

                Rectangle {
                    anchors.fill: parent

                    radius: 9

                    color:
                        pinMouse.containsMouse
                            ? Qt.rgba(
                                Colors.primary.r,
                                Colors.primary.g,
                                Colors.primary.b,
                                0.10
                            )
                            : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration:
                                Theme.hoverFadeDuration
                        }
                    }

                    Image {
                        id: pinIcon

                        anchors.centerIn: parent

                        width:  32
                        height: 32

                        source:
                            Quickshell.iconPath(
                                root.pinnedApps[
                                    index
                                ].icon || "",
                                true
                            )

                        fillMode:
                            Image.PreserveAspectFit

                        smooth:       true
                        mipmap:       true
                        asynchronous: true

                        visible:
                            status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent

                        visible:
                            pinIcon.status !== Image.Ready

                        text:
                            (
                                root.pinnedApps[
                                    index
                                ].name || "?"
                            )
                                .charAt(0)
                                .toUpperCase()

                        color:
                            Colors.on_SurfaceVariant

                        font.pixelSize: 15
                        font.bold:       true
                        font.family:     Fonts.fontM
                    }

                    MouseArea {
                        id: pinMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        cursorShape:
                            Qt.PointingHandCursor

                        acceptedButtons:
                            Qt.LeftButton |
                            Qt.RightButton

                        onClicked: (mouse) => {
                            const app =
                                root.pinnedApps[index]

                            if (mouse.button === Qt.RightButton) {
                                LauncherService.togglePin(
                                    app
                                )
                            } else {
                                root.launched(app)
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            visible:
                root.pinnedSlots > 0 &&
                root.recentSlots > 0

            Layout.preferredWidth: 1
            Layout.preferredHeight: 28
            Layout.alignment: Qt.AlignVCenter

            color:
                Colors.outlineVariant

            opacity:
                0.7

            Layout.leftMargin: 4
            Layout.rightMargin: 4
        }

        Repeater {
            model: root.recentSlots

            delegate: Item {
                required property int index

                Layout.preferredWidth:
                    root.slotW

                Layout.preferredHeight:
                    root.slotW

                Layout.alignment:
                    Qt.AlignVCenter

                Rectangle {
                    anchors.fill: parent

                    radius: 9

                    color:
                        recentMouse.containsMouse
                            ? Qt.rgba(
                                Colors.primary.r,
                                Colors.primary.g,
                                Colors.primary.b,
                                0.08
                            )
                            : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration:
                                Theme.hoverFadeDuration
                        }
                    }

                    Image {
                        id: recentIcon

                        anchors.centerIn: parent

                        width:  32
                        height: 32

                        source:
                            Quickshell.iconPath(
                                root.recentApps[
                                    index
                                ].icon || "",
                                true
                            )

                        fillMode:
                            Image.PreserveAspectFit

                        smooth:       true
                        mipmap:       true
                        asynchronous: true

                        visible:
                            status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent

                        visible:
                            recentIcon.status !== Image.Ready

                        text:
                            (
                                root.recentApps[
                                    index
                                ].name || "?"
                            )
                                .charAt(0)
                                .toUpperCase()

                        color:
                            Colors.on_SurfaceVariant

                        font.pixelSize: 15
                        font.bold:       true
                        font.family:     Fonts.fontM
                    }

                    MouseArea {
                        id: recentMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        cursorShape:
                            Qt.PointingHandCursor

                        acceptedButtons:
                            Qt.LeftButton |
                            Qt.RightButton

                        onClicked: (mouse) => {
                            const app =
                                root.recentApps[index]

                            if (mouse.button === Qt.RightButton) {
                                LauncherService.togglePin(
                                    app
                                )
                            } else {
                                root.launched(app)
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }
}

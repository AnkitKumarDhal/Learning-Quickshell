import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.src.theme
import qs.src.services
import qs.src.popups.notifications

PanelWindow {
    id: root

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        right: true
    }

    implicitWidth: 380

    screen: NotificationService.toastScreen
    WlrLayershell.layer: WlrLayer.Overlay
    visible: true

    readonly property int cardSpacing: 8
    readonly property int visibleStackHeight: toastList.contentHeight
    readonly property int stackHeight: Math.min(root.stackHeight, root.height - 24)

    mask: Region {
        item: NotificationService.activeToastCount > 0 ? toastStack : null
    }

    Item {
        id: toastStack

        width: 360
        height: Math.min( root.stackHeight, root.height - 24 )

        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: 12
            bottomMargin: 12
        }

        ListView {
            id: toastList

            anchors.fill: parent
            orientation: ListView.Vertical
            verticalLayoutDirection: ListView.BottomToTop
            spacing: root.cardSpacing
            interactive: false
            model: NotificationService.activeToastsModel

            delegate: NotificationToastItem {
                width: toastList.width
                required property var toastNotification
                notification: toastNotification
            }

            add: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "x"
                        from: toastList.width + 36
                        to: 0
                        duration: 350
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 280
                        easing.type: Easing.OutCubic
                    }
                }
            }

            addDisplaced: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 320
                    easing.type: Easing.OutCubic
                }
            }

            remove: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "x"
                        to: toastList.width + 24
                        duration: 300
                        easing.type: Easing.InCubic
                    }

                    NumberAnimation {
                        property: "opacity"
                        to: 0
                        duration: 220
                        easing.type: Easing.InCubic
                    }
                }
            }

            removeDisplaced: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}

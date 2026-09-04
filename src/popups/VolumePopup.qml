import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.popups.audio

PanelWindow {
    id: root

    required property var screen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top:  true
        left: true
        right: true
    }

    implicitHeight: root.screen ? root.screen.height : 800
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    visible: slidePanel.windowVisible

    property string expandedCard: ""

    function toggleCard(card) {
        root.expandedCard = root.expandedCard === card ? "" : card
    }

    onVisibleChanged: {
        if (!visible) root.expandedCard = ""
    }

    mask: Region {
        x: card.x
        y: Theme.barHeight + 8
        width: card.width
        height: card.height
    }

    PopupSlide {
        id: slidePanel

        anchors.fill: parent
        edge: "top"
        open: Popups.volumeOpen && Popups.volumeScreen === root.screen
        onCloseRequested: Popups.volumeOpen = false

        Rectangle {
            id: card

            anchors {
                top: parent.top
                topMargin: Theme.barHeight + 8
            }

            x: Popups.volumeAnchorX - width / 2
            width: 440
            height: mainColumn.implicitHeight + 32
            radius: Theme.popupRadius
            color: Colors.surfaceContainer
            border.color: Colors.outlineVariant
            border.width: Theme.popupBorder
            clip: true

            Behavior on height {
                NumberAnimation {
                    duration: Theme.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                id: mainColumn

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: 16
                    leftMargin: 16
                    rightMargin: 16
                    bottomMargin: 16
                }

                spacing: 10

                // Output / Input cards
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    AudioStatusCard {
                        Layout.fillWidth: true
                        mode: "output"
                        expanded: root.expandedCard === "output"
                        onClicked: root.toggleCard("output")
                    }

                    AudioStatusCard {
                        Layout.fillWidth: true
                        mode: "input"
                        expanded: root.expandedCard === "input"
                        onClicked: root.toggleCard("input")
                    }
                }

                // Expanded controls
                AudioCardDetails {
                    Layout.fillWidth: true
                    mode: root.expandedCard
                    visible: root.expandedCard !== ""
                    Behavior on implicitHeight {
                        NumberAnimation {
                            duration: Theme.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.outlineVariant
                    opacity: 0.6
                }

                // Application mixer
                AudioApplicationMixer {
                    Layout.fillWidth: true
                    mode: root.expandedCard === "input" ? "input" : "output"
                }
            }
        }
    }
}

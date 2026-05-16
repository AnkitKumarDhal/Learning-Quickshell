import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.src.components
import qs.src.modules.Left
import qs.src.modules.Center
import qs.src.modules.Right
import qs.src.theme
import qs.src.state

PanelWindow {
    id: root

    property var screen

    color:         "transparent"
    exclusionMode: ExclusionMode.Auto

    anchors {
        top:   true
        left:  true
        right: true
    }

    // ── Height animates between full bar and thin strip ───────────────────────
    implicitHeight: ShellState.focusMode ? Theme.borderWidth : Theme.barHeight
    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic }
    }

    // ── Write notch widths to ShellState for PopupDismiss ────────────────────
    Binding { target: ShellState; property: "topBarLWidth"; value: leftRow.implicitWidth  + Theme.barMargin }
    Binding { target: ShellState; property: "topBarCWidth"; value: centerRow.implicitWidth }
    Binding { target: ShellState; property: "topBarRWidth"; value: rightRow.implicitWidth + Theme.barMargin }

    // ── Thin strip background — visible only in focus mode ────────────────────
    Rectangle {
        anchors.fill: parent
        color:        Colors.background
        opacity:      ShellState.focusMode ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic }
        }
    }

    // ── Full bar content — fades out in focus mode ────────────────────────────
    Item {
        anchors.fill: parent
        opacity: ShellState.focusMode ? 0 : 1
        Behavior on opacity {
            NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic }
        }

        // Left modules
        RowLayout {
            id: leftRow
            anchors.left:           parent.left
            anchors.leftMargin:     Theme.barMargin
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.barSpacing

            ArchLogo    {}
            Workspaces  {}
            WindowName  {}
        }

        // Center modules
        RowLayout {
            id: centerRow
            anchors.centerIn:       parent
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.barSpacing

            ClockDate       {}
            Media           {}
            IdleInhibitor   {}
        }

        // Right modules
        RowLayout {
            id: rightRow
            anchors.right:          parent.right
            anchors.rightMargin:    Theme.barMargin
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.barSpacing

            SystemMonitor       {}
            Volume              {}
            Battery             {}
            Tray                {}
            NotificationButton  {}
        }
    }
}

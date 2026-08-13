import QtQuick
import Quickshell
import QtQuick.Layouts
import qs.src.theme

Item {
    id: root

    // ── Inputs ────────────────────────────────────────────────────────────
    property var  appData:    ({})
    property bool isSelected: false

    // ── Outputs ───────────────────────────────────────────────────────────
    signal activated()
    signal hovered()

    height: 54

    // ── Selection background ──────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        topRightRadius: 15
        bottomRightRadius: 15
        color: root.isSelected
                   ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)
                   : hov.containsMouse
                       ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.08)
                       : "transparent"
        Behavior on color { ColorAnimation { duration: 80 } }
    }

    // ── Left accent bar ───────────────────────────────────────────────────
    Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width:   3
        radius:  1.5
        color:   Colors.primary
        opacity: root.isSelected ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    // ── Row content ───────────────────────────────────────────────────────
    RowLayout {
        anchors { fill: parent; leftMargin: 16; rightMargin: 14 }
        spacing: 12

        // App icon — real icon with letter fallback
        Rectangle {
            width:  36
            height: 36
            radius: 9
            color:  iconImg.status === Image.Ready
                        ? "transparent"
                        : (root.isSelected ? Colors.primaryContainer : Colors.surfaceContainerHigh)
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: 120 } }

            Image {
                id:              iconImg
                anchors.fill:    parent
                anchors.margins: 3
                source:          root.appData.icon ? Quickshell.iconPath(root.appData.icon, true) : ""
                fillMode:        Image.PreserveAspectFit
                smooth:          true
                mipmap:          true
                visible:         status === Image.Ready
                asynchronous:    true
            }

            Text {
                anchors.centerIn: parent
                visible:          iconImg.status !== Image.Ready
                text:             (root.appData.name || "?").charAt(0).toUpperCase()
                color:            root.isSelected ? Colors.on_PrimaryContainer : Colors.on_SurfaceVariant
                font.pixelSize:   15
                font.bold:        true
                font.family:      Fonts.fontM
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }

        // Name + comment
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text:             root.appData.name || ""
                color:            root.isSelected ? Colors.on_Surface : Colors.on_SurfaceVariant
                font.pixelSize:   13
                font.weight:      root.isSelected ? Font.Medium : Font.Normal
                font.family:      Fonts.fontM
                elide:            Text.ElideRight
                Layout.fillWidth: true
                Behavior on color { ColorAnimation { duration: 100 } }
            }

            Text {
                visible:          root.appData.comment !== "" && root.appData.comment !== undefined
                text:             root.appData.comment || ""
                color:            Colors.on_SurfaceVariant
                font.pixelSize:   11
                font.family:      Fonts.font
                elide:            Text.ElideRight
                Layout.fillWidth: true
                opacity:          0.65
            }
        }

        // Enter hint on selected row
        Text {
            visible:        root.isSelected
            text:           "↵"
            color:          Colors.primary
            font.pixelSize: 14
            font.family:    Fonts.font
            opacity:        0.7
        }
    }

    // ── Mouse ─────────────────────────────────────────────────────────────
    MouseArea {
        id:           hov
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.activated()
        onEntered:    root.hovered()
    }
}

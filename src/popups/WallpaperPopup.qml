import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.src.components
import qs.src.theme
import qs.src.state

PanelWindow {
    id: root

    //property var screen

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors { bottom: true; left: true; right: true }

    implicitWidth:  screen ? screen.width : 1880
    implicitHeight: 520

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Popups.wallpaperOpen
                                     ? WlrKeyboardFocus.Exclusive
                                     : WlrKeyboardFocus.None

    visible: slide.windowVisible

    // ── On open ───────────────────────────────────────────────────────────────
    Connections {
        target: Popups
        function onWallpaperOpenChanged() {
            if (Popups.wallpaperOpen) {
                dirField.text = root.wallpaperDir
                root.scanWallpapers()
            }
        }
    }

    // ── State ─────────────────────────────────────────────────────────────────
    property string wallpaperDir: "~/wallpapers"
    property var    wallpapers:   []
    property string currentWall:  ""
    property bool   applying:     false
    property string _pendingWall: ""

    function scanWallpapers() {
        scanProc._lines  = []
        scanProc.running = true
    }

    function applyWallpaper(imgPath) {
        if (applying) return
        applying     = true
        currentWall  = imgPath
        _pendingWall = imgPath
        wallProc.running = true
    }

    // ── Scan process ──────────────────────────────────────────────────────────
    Process {
        id: scanProc
        command: ["sh", "-c",
            "find " + root.wallpaperDir + " -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' " +
            "-o -iname '*.png' -o -iname '*.webp' \\) " +
            "2>/dev/null | sort"]
        running: false

        property var _lines: []

        stdout: SplitParser {
            onRead: (line) => {
                const p = line.trim()
                if (p) scanProc._lines.push(p)
            }
        }

        onExited: {
            root.wallpapers = scanProc._lines.slice()
            scanProc._lines = []
        }
    }

    // ── Apply process (sources and calls the fish wall function) ──────────────
    Process {
        id: wallProc
        command: ["fish", "-c",
            "source ~/.config/fish/functions/wall.fish; wall '" + root._pendingWall + "'"]
        running: false
        onExited: root.applying = false
    }

    // ── Slide ─────────────────────────────────────────────────────────────────
    PopupSlide {
        id:           slide
        anchors.fill: parent
        edge:         "bottom"
        open:         Popups.wallpaperOpen
        onCloseRequested: Popups.wallpaperOpen = false

        Rectangle {
            id: wallRec
            anchors {
                bottom:           parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin:     18
            }

            width:        Math.min(parent.width - 36, 960)
            height:       460

            radius:       Theme.popupRadius
            color:        Colors.surfaceContainer
            border.color: Colors.outlineVariant
            border.width: Theme.popupBorder
            clip:         true

            ColumnLayout {
                anchors {
                    fill:         parent
                    margins:      16
                    bottomMargin: 12
                }
                spacing: 12

                // ── Header ────────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text:           "󰋲"
                        color:          Colors.primary
                        font.pixelSize: 18
                        font.family:    Fonts.fontM
                    }

                    Text {
                        text:             "Wallpapers"
                        color:            Colors.on_Surface
                        font.pixelSize:   14
                        font.bold:        true
                        font.family:      Fonts.font
                        Layout.fillWidth: true
                    }

                    Text {
                        visible:        root.applying
                        text:           "Applying…"
                        color:          Colors.primary
                        font.pixelSize: 11
                        font.family:    Fonts.font

                        SequentialAnimation on opacity {
                            running: root.applying
                            loops:   Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0.7; duration: 600; easing.type: Easing.InOutSine }
                        }
                    }
                }

                // ── Directory row ─────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text:           "󰉋"
                        color:          Colors.on_SurfaceVariant
                        font.pixelSize: 14
                        font.family:    Fonts.fontM
                    }

                    TextField {
                        id:               dirField
                        Layout.fillWidth: true
                        height:           32
                        text:             root.wallpaperDir
                        font.family:      Fonts.font
                        font.pixelSize:   12
                        color:            Colors.on_Surface
                        placeholderTextColor: Colors.outline
                        placeholderText:  "Wallpaper directory…"

                        Keys.onReturnPressed: {
                            root.wallpaperDir = text
                            root.scanWallpapers()
                        }

                        Keys.onEscapePressed: Popups.wallpaperOpen = false

                        background: Rectangle {
                            radius:       8
                            color:        Colors.surfaceContainerHigh
                            border.width: 1
                            border.color: dirField.activeFocus ? Colors.primary : Colors.outline
                            Behavior on border.color {
                                ColorAnimation { duration: Theme.hoverFadeDuration }
                            }
                        }
                    }

                    // Rescan button
                    Rectangle {
                        width:  32
                        height: 32
                        radius: 8
                        color:  rescanHov.containsMouse
                                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                                    : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: Theme.hoverFadeDuration }
                        }

                        Text {
                            anchors.centerIn: parent
                            text:             "󰑐"
                            font.family:      Fonts.fontM
                            font.pixelSize:   16
                            color:            rescanHov.containsMouse
                                                  ? Colors.primary
                                                  : Colors.on_SurfaceVariant
                        }

                        MouseArea {
                            id:           rescanHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                root.wallpaperDir = dirField.text
                                root.scanWallpapers()
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height:           1
                    color:            Colors.outlineVariant
                    opacity:          0.5
                }

                // ── Wallpaper grid ────────────────────────────────────────────
                GridView {
                    id:               wallGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    cellWidth:  150
                    cellHeight: 108

                    clip:           true
                    boundsBehavior: Flickable.StopAtBounds
                    focus:          true

                    ScrollBar.vertical: ScrollBar {
                        policy: wallGrid.contentHeight > wallGrid.height
                                    ? ScrollBar.AlwaysOn
                                    : ScrollBar.AlwaysOff
                        contentItem: Rectangle {
                            implicitWidth:  3
                            implicitHeight: 40
                            radius:         1.5
                            color:          Qt.rgba(1, 1, 1, 0.25)
                        }
                        background: Item {}
                    }

                    model: root.wallpapers

                    Keys.onEscapePressed: Popups.wallpaperOpen = false

                    delegate: Item {
                        id:       thumbDelegate
                        required property var modelData
                        required property int index

                        readonly property bool isActive: root.currentWall === modelData

                        width:  wallGrid.cellWidth
                        height: wallGrid.cellHeight

                        Rectangle {
                            id: thumbCard
                            anchors {
                                fill:    parent
                                margins: 4
                            }
                            radius: 10
                            color:  Colors.surfaceContainerHigh
                            clip:   true

                            // Thumbnail
                            Image {
                                anchors.fill: parent
                                source:       "file://" + thumbDelegate.modelData
                                fillMode:     Image.PreserveAspectCrop
                                smooth:       true
                                asynchronous: true
                                mipmap:       true
                            }

                            // Dim overlay — less dim when active or hovered
                            Rectangle {
                                anchors.fill: parent
                                color:        Colors.background
                                opacity:      thumbHov.containsMouse    ? 0.08
                                              : thumbDelegate.isActive  ? 0.0
                                              :                           0.38

                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            // Active border ring
                            Rectangle {
                                anchors.fill:  parent
                                radius:        thumbCard.radius
                                color:         "transparent"
                                border.width:  thumbDelegate.isActive ? 2 : 0
                                border.color:  Colors.primary
                            }

                            // Active checkmark badge
                            Rectangle {
                                visible: thumbDelegate.isActive
                                anchors {
                                    top:     parent.top
                                    right:   parent.right
                                    margins: 6
                                }
                                width:  20
                                height: 20
                                radius: 10
                                color:  Colors.primary

                                Text {
                                    anchors.centerIn: parent
                                    text:             "󰄵"
                                    color:            Colors.on_Primary
                                    font.pixelSize:   10
                                    font.family:      Fonts.font
                                }
                            }

                            // Applying spinner overlay
                            Item {
                                anchors.fill: parent
                                visible:      root.applying && thumbDelegate.isActive

                                Rectangle {
                                    anchors.fill: parent
                                    color:        Qt.rgba(
                                                      Colors.background.r,
                                                      Colors.background.g,
                                                      Colors.background.b, 0.55)
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text:             "󰑐"
                                    color:            Colors.primary
                                    font.pixelSize:   22
                                    font.family:      Fonts.fontM

                                    NumberAnimation on rotation {
                                        from:    0
                                        to:      360
                                        duration: 1000
                                        loops:   Animation.Infinite
                                        running: root.applying && thumbDelegate.isActive
                                    }
                                }
                            }

                            MouseArea {
                                id:           thumbHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onClicked:    root.applyWallpaper(thumbDelegate.modelData)
                            }
                        }
                    }
                }

                // Empty state
                Text {
                    visible:          root.wallpapers.length === 0
                    Layout.alignment: Qt.AlignHCenter
                    text:             "No images found in " + root.wallpaperDir
                    font.family:      Fonts.font
                    font.pixelSize:   12
                    color:            Colors.outline
                    topPadding:       16
                    bottomPadding:    16
                }
            }
        }
    }
}

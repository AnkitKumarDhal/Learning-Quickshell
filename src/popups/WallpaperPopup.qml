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

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors { bottom: true; left: true; right: true }

    implicitWidth:  screen ? screen.width : 1880
    implicitHeight: 520

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Popups.wallpaperOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: slide.windowVisible

    Connections {
        target: Popups
        function onWallpaperOpenChanged() {
            if (Popups.wallpaperOpen) {
                dirField.text = root.wallpaperDir
                root.scanWallpapers()
            }
        }
    }

    Component.onCompleted: {
        if (Popups.wallpaperOpen) {
            dirField.text = root.wallpaperDir
            root.scanWallpapers()
        }
    }

    // state
    property string wallpaperDir: "~/wallpapers"
    property var    wallpapers:   []
    property string currentWall:  ""
    property bool   applying:     false
    property string _pendingWall: ""

    readonly property string thumbnailDir: Quickshell.cachePath("wallpaper-thumbnails")
    readonly property int thumbnailWidth: 300
    readonly property int thumbnailHeight: 200
    property var _thumbnailQueue: []

    function _hashKey(value) {
        let hashA = 2166136261
        let hashB = 5381
        for (let i = 0; i < value.length; i++) {
            const c = value.charCodeAt(i)

            hashA ^= c
            hashA = Math.imul(hashA, 16777619)
            hashB = Math.imul(hashB, 33) ^ c
        }
        return (hashA >>> 0).toString(16).padStart(8, "0") + (hashB >>> 0).toString(16).padStart(8, "0")
    }

    function _thumbnailPath(path, mtime, size) {
        const key = _hashKey(path + "\t" + mtime + "\t" + size)
        return root.thumbnailDir + "/" + key + ".webp"
    }

    function scanWallpapers() {
        scanProc._lines  = []
        scanProc.running = true
    }

    function _beginThumbnailSync(lines) {
        const items = []

        for (const line of lines) {
            const firstSep = line.indexOf("\t")
            if (firstSep < 0) continue

            const secondSep = line.indexOf("\t", firstSep + 1)
            if (secondSep < 0) continue

            const mtime = line.substring(0, firstSep)
            const size = line.substring(firstSep + 1, secondSep)
            const path = line.substring(secondSep + 1)

            if (!path) continue

            items.push({
                sourcePath: path,
                thumbnailPath: root._thumbnailPath(path, mtime, size),
                thumbReady: false
            })
        }

        root.wallpapers = items
        cacheMkdir.running = true
    }

    function _finishThumbnailSync(cacheLines) {
        const cached = new Set()

        for (const line of cacheLines) {
            const name = line.trim()
            if (name) cached.add(name)
        }

        const expected = new Set()
        const missing = []

        const updated = root.wallpapers.map(item => {
            const name = item.thumbnailPath.substring(item.thumbnailPath.lastIndexOf("/") + 1)
            expected.add(name)

            const ready = cached.has(name)
            if (!ready) missing.push(item)

            return {
                sourcePath: item.sourcePath,
                thumbnailPath: item.thumbnailPath,
                thumbReady: ready
            }
        })

        root.wallpapers = updated
        root._thumbnailQueue = missing

        const orphanPaths = []

        for (const name of cached) {
            if (!expected.has(name)) orphanPaths.push(root.thumbnailDir + "/" + name)
        }

        if (orphanPaths.length > 0) {
            cleanupProc.command = ["rm", "-f", ...orphanPaths]
            cleanupProc.running = true
        } else {
            root._startNextThumbnail()
        }
    }

    function applyWallpaper(imgPath) {
        if (applying) return
        applying     = true
        currentWall  = imgPath
        _pendingWall = imgPath
        wallProc.running = true
    }

    Process {
        id: scanProc
        command: ["sh", "-c",
            "find " + root.wallpaperDir + " -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' " +
            "-o -iname '*.png' -o -iname '*.webp' \\) " +
            "-printf '%T@\\t%s\\t%p\\n' 2>/dev/null | sort -k3"]
        running: false

        property var _lines: []

        stdout: SplitParser {
            onRead: (line) => {
                const p = line.trim()
                if (p) scanProc._lines.push(p)
            }
        }

        onExited: {
            const lines = scanProc._lines.slice()
            scanProc._lines = []
            root._beginThumbnailSync(lines)
        }
    }

    Process {
        id: cacheMkdir

        command: ["mkdir", "-p", root.thumbnailDir]
        running: false

        onExited: {
            cacheList.command = [
                "find",
                root.thumbnailDir,
                "-maxdepth", "1",
                "-type", "f",
                "-name", "*.webp",
                "-printf", "%f\n"
            ]
            cacheList.running = true
        }
    }

    Process {
        id: cacheList

        running: false
        property var _lines: []

        stdout: SplitParser {
            onRead: (line) => {
                const p = line.trim()
                if (p) cacheList._lines.push(p)
            }
        }

        onExited: {
            const lines = cacheList._lines.slice()
            cacheList._lines = []
            root._finishThumbnailSync(lines)
        }
    }

    Process {
        id: cleanupProc
        running: false
        onExited: root._startNextThumbnail()
    }

    Process {
        id: thumbProc
        running: false
        property var _item: null
        onExited: (exitCode, exitStatus) => {
            root._thumbnailFinished(exitCode === 0)
        }
    }

    function _startNextThumbnail() {
        if (thumbProc.running || root._thumbnailQueue.length === 0) return

        const next = root._thumbnailQueue.shift()
        thumbProc._item = next
        thumbProc.command = [
            "magick",
            next.sourcePath,
            "-auto-orient",
            "-thumbnail",
            root.thumbnailWidth + "x" + root.thumbnailHeight + "^",
            "-gravity", "center",
            "-extent",
            root.thumbnailWidth + "x" + root.thumbnailHeight,
            "-strip",
            "-quality", "82",
            next.thumbnailPath
        ]

        thumbProc.running = true
    }

    function _thumbnailFinished(success) {
        const finished = thumbProc._item
        thumbProc._item = null

        if (success && finished) {
            root.wallpapers = root.wallpapers.map(item => {
                if (item.sourcePath !== finished.sourcePath ||
                    item.thumbnailPath !== finished.thumbnailPath) {
                    return item
                }

                return {
                    sourcePath: item.sourcePath,
                    thumbnailPath: item.thumbnailPath,
                    thumbReady: true
                }
            })
        }

        if (root._thumbnailQueue.length > 0) {
            root._startNextThumbnail()
        }
    }

    Process {
        id: wallProc
        command: ["fish", "-c",
            "source ~/.config/fish/functions/wall.fish; wall '" + root._pendingWall + "'"]
        running: false
        onExited: root.applying = false
    }

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

                        readonly property bool isActive: root.currentWall === modelData.sourcePath

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
                                source:       thumbDelegate.modelData.thumbReady
                                                    ? ("file://" + thumbDelegate.modelData.thumbnailPath)
                                                    : ("file://" + thumbDelegate.modelData.sourcePath)
                                sourceSize:   Qt.size(
                                    root.thumbnailWidth,
                                    root.thumbnailHeight
                                )
                                fillMode:     Image.PreserveAspectCrop
                                asynchronous: true
                                cache:        true
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
                                onClicked:    root.applyWallpaper(thumbDelegate.modelData.sourcePath)
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

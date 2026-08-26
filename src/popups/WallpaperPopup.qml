import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Qt5Compat.GraphicalEffects
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
                Qt.callLater(() => wallCarousel.forceActiveFocus())
            }
        }
    }

    Component.onCompleted: {
        if (Popups.wallpaperOpen) {
            dirField.text = root.wallpaperDir
            root.scanWallpapers()
            Qt.callLater(() => wallCarousel.forceActiveFocus())
        }
    }

    // state
    property string wallpaperDir: "~/wallpapers"
    property var    wallpapers:   []
    property string currentWall:  ""
    property int    selectedIndex: 0
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
        root._thumbnailQueue = []
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

        const currentIndex = items.findIndex(item => item.sourcePath === root.currentWall)
        if (currentIndex >= 0) {
            root.selectedIndex = currentIndex
        } else if (root.selectedIndex >= items.length) {
            root.selectedIndex = Math.max(0, items.length - 1)
        } else {
            root.selectedIndex = Math.max(0, root.selectedIndex)
        }

        cacheMkdir.running = true
    }

    function _finishThumbnailSync(cacheLines) {
        const cached = new Set()

        for (const line of cacheLines) {
            const name = line.trim()
            if (name) cached.add(name)
        }

        const expected = new Set()

        const updated = root.wallpapers.map(item => {
            const name = item.thumbnailPath.substring(item.thumbnailPath.lastIndexOf("/") + 1)
            expected.add(name)

            return {
                sourcePath: item.sourcePath,
                thumbnailPath: item.thumbnailPath,
                thumbReady: cached.has(name)
            }
        })

        root.wallpapers = updated
        root._rebuildThumbnailQueue()

        const orphanPaths = []

        for (const name of cached) {
            if (!expected.has(name)) orphanPaths.push(root.thumbnailDir + "/" + name)
        }

        if (orphanPaths.length > 0) {
            cleanupProc.command = ["rm", "-f", ...orphanPaths]
            cleanupProc.running = true
        }
    }

    function selectWallpaper(index) {
        if (root.wallpapers.length === 0) return

        const nextIndex = Math.max(0, Math.min(index, root.wallpapers.length - 1))
        root.selectedIndex = nextIndex
        wallCarousel.positionViewAtIndex(nextIndex, ListView.SnapPosition)
        root._rebuildThumbnailQueue()
    }

    function selectRelative(delta) {
        if (root.wallpapers.length === 0) return
        root.selectWallpaper(root.selectedIndex + delta)
    }

    function applySelectedWallpaper() {
        if (root.applying) return
        if (root.selectedIndex < 0 || root.selectedIndex >= root.wallpapers.length) return

        const selected = root.wallpapers[root.selectedIndex]
        if (!selected) return

        if (selected.sourcePath === root.currentWall) return

        root.applying     = true
        root._pendingWall = selected.sourcePath
        wallProc.running = true
    }

    function _rebuildThumbnailQueue() {
        if (root.wallpapers.length === 0) {
            root._thumbnailQueue = []
            return
        }

        const queued = new Set()
        const ordered = []

        const addIndex = (index) => {
            if (index < 0 || index >= root.wallpapers.length) return

            const item = root.wallpapers[index]
            if (!item || item.thumbReady) return
            if (thumbProc._item && thumbProc._item.sourcePath === item.sourcePath) return
            if (queued.has(item.sourcePath)) return

            queued.add(item.sourcePath)
            ordered.push(item)
        }

        const priorityOffsets = [0, -1, 1, -2, 2, -3, 3]

        for (const offset of priorityOffsets) {
            addIndex(root.selectedIndex + offset)
        }

        for (let i = 0; i < root.wallpapers.length; i++) {
            addIndex(i)
        }

        root._thumbnailQueue = ordered
        root._startNextThumbnail()
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

        root._rebuildThumbnailQueue()
    }

    Process {
        id: wallProc

        command: ["fish", "-c",
            "source ~/.config/fish/functions/wall.fish; wall $argv[1]",
            "--",
            root._pendingWall]

        running: false

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.currentWall = root._pendingWall
            }

            root.applying = false
        }
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
                spacing: 10

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
                            wallCarousel.forceActiveFocus()
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
                                wallCarousel.forceActiveFocus()
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

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip:              true

                    ListView {
                        id:                        wallCarousel
                        anchors.fill:              parent
                        orientation:               ListView.Horizontal
                        spacing:                   18
                        clip:                      true
                        boundsBehavior:            Flickable.StopAtBounds
                        snapMode:                  ListView.SnapToItem
                        preferredHighlightBegin:   Math.max(0, (width - 500) / 2)
                        preferredHighlightEnd:     Math.max(0, (width - 500) / 2) + 500
                        highlightRangeMode:        ListView.StrictlyEnforceRange
                        highlightFollowsCurrentItem: true
                        interactive:               root.wallpapers.length > 1
                        focus:                     true
                        keyNavigationWraps:        true
                        model:                     root.wallpapers

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                Popups.wallpaperOpen = false
                                event.accepted = true
                            } else if (event.key === Qt.Key_Left) {
                                root.selectRelative(-1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Right) {
                                root.selectRelative(1)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return ||
                                       event.key === Qt.Key_Enter ||
                                       event.key === Qt.Key_Space) {
                                root.applySelectedWallpaper()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Home) {
                                root.selectWallpaper(0)
                                event.accepted = true
                            } else if (event.key === Qt.Key_End) {
                                root.selectWallpaper(root.wallpapers.length - 1)
                                event.accepted = true
                            }
                        }

                        onCurrentIndexChanged: {
                            if (root.selectedIndex !== currentIndex) {
                                root.selectedIndex = currentIndex
                                root._rebuildThumbnailQueue()
                            }
                        }

                        delegate: Item {
                            id:       thumbDelegate
                            required property var modelData
                            required property int index

                            readonly property bool isSelected: root.selectedIndex === index
                            readonly property bool isActive: root.currentWall === modelData.sourcePath

                            width:  500
                            height: Math.min(parent ? parent.height - 8 : 260, 280)

                            Rectangle {
                                id: thumbCard
                                anchors.centerIn: parent
                                width:             500
                                height:            parent.height
                                radius:            16
                                color:             Colors.surfaceContainerHigh
                                clip:              false

                                scale:   thumbDelegate.isSelected ? 1.0 : 0.76
                                opacity: thumbDelegate.isSelected ? 1.0 : 0.58

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 240
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                layer.enabled: true

                                Image {
                                    id: wallpaperImage

                                    anchors.fill: parent

                                    source: thumbDelegate.modelData.thumbReady
                                                ? ("file://" + thumbDelegate.modelData.thumbnailPath)
                                                : ("file://" + thumbDelegate.modelData.sourcePath)

                                    sourceSize: Qt.size(
                                        root.thumbnailWidth,
                                        root.thumbnailHeight
                                    )

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
                                    color:        Colors.background
                                    opacity:      thumbDelegate.isSelected
                                                      ? 0.0
                                                      : 0.35

                                    Behavior on opacity {
                                        NumberAnimation { duration: 180 }
                                    }
                                }

                                Rectangle {
                                    visible: thumbDelegate.isActive

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

                                    visible: thumbDelegate.isSelected

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

                                Rectangle {
                                    anchors.fill:  parent
                                    radius:        thumbCard.radius
                                    color:         "transparent"
                                    border.width:  thumbDelegate.isSelected ? 2 : 0
                                    border.color:  Colors.primary
                                }

                                Text {
                                    visible: thumbDelegate.isSelected

                                    anchors {
                                        left:         parent.left
                                        right:        parent.right
                                        bottom:       parent.bottom
                                        leftMargin:   14
                                        rightMargin:  14
                                        bottomMargin: 12
                                    }

                                    text:         thumbDelegate.modelData.sourcePath.split("/").pop()
                                    color:        Colors.on_Surface
                                    font.pixelSize: 11
                                    font.bold:    true
                                    font.family:   Fonts.font
                                    elide:         Text.ElideMiddle
                                }

                                // Applying spinner overlay
                                Item {
                                    anchors.fill: parent
                                    visible:      root.applying && thumbDelegate.isSelected

                                    Rectangle {
                                        anchors.fill: parent
                                        color:        Qt.rgba(
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
                                            running:  root.applying && thumbDelegate.isSelected
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape:  Qt.PointingHandCursor

                                    onClicked: {
                                        root.selectWallpaper(thumbDelegate.index)
                                        wallCarousel.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }

                    // Previous button
                    Rectangle {
                        visible:             root.wallpapers.length > 1
                        anchors.left:         parent.left
                        anchors.leftMargin:  6
                        anchors.verticalCenter: parent.verticalCenter
                        width:               38
                        height:              38
                        radius:              19
                        color:               previousHov.containsMouse
                                                ? Qt.rgba(
                                                      Colors.primary.r,
                                                      Colors.primary.g,
                                                      Colors.primary.b,
                                                      0.18)
                                                : Qt.rgba(
                                                      Colors.surfaceContainerHighest.r,
                                                      Colors.surfaceContainerHighest.g,
                                                      Colors.surfaceContainerHighest.b,
                                                      0.88)

                        Behavior on color {
                            ColorAnimation { duration: Theme.hoverFadeDuration }
                        }

                        Text {
                            anchors.centerIn: parent
                            text:             "󰁍"
                            color:            previousHov.containsMouse
                                                ? Colors.primary
                                                : Colors.on_SurfaceVariant
                            font.pixelSize:   16
                            font.family:      Fonts.fontM
                        }

                        MouseArea {
                            id:           previousHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor

                            onClicked: {
                                root.selectRelative(-1)
                                wallCarousel.forceActiveFocus()
                            }
                        }
                    }

                    // Next button
                    Rectangle {
                        visible:             root.wallpapers.length > 1
                        anchors.right:        parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width:               38
                        height:              38
                        radius:              19
                        color:               nextHov.containsMouse
                                                ? Qt.rgba(
                                                      Colors.primary.r,
                                                      Colors.primary.g,
                                                      Colors.primary.b,
                                                      0.18)
                                                : Qt.rgba(
                                                      Colors.surfaceContainerHighest.r,
                                                      Colors.surfaceContainerHighest.g,
                                                      Colors.surfaceContainerHighest.b,
                                                      0.88)

                        Behavior on color {
                            ColorAnimation { duration: Theme.hoverFadeDuration }
                        }

                        Text {
                            anchors.centerIn: parent
                            text:             "󰁔"
                            color:            nextHov.containsMouse
                                                ? Colors.primary
                                                : Colors.on_SurfaceVariant
                            font.pixelSize:   16
                            font.family:      Fonts.fontM
                        }

                        MouseArea {
                            id:           nextHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor

                            onClicked: {
                                root.selectRelative(1)
                                wallCarousel.forceActiveFocus()
                            }
                        }
                    }

                    Text {
                        visible:          root.wallpapers.length === 0
                        anchors.centerIn: parent
                        text:             "No images found in " + root.wallpaperDir
                        font.family:      Fonts.font
                        font.pixelSize:   12
                        color:            Colors.outline
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        text: root.wallpapers.length > 0 && root.selectedIndex < root.wallpapers.length
                                  ? root.wallpapers[root.selectedIndex].sourcePath.split("/").pop()
                                  : "No wallpaper selected"
                        color:            Colors.on_SurfaceVariant
                        font.family:      Fonts.font
                        font.pixelSize:   11
                        elide:             Text.ElideMiddle
                    }

                    Text {
                        visible:          root.wallpapers.length > 0
                        text:             (root.selectedIndex + 1) + " / " + root.wallpapers.length
                        color:            Colors.outline
                        font.family:      Fonts.font
                        font.pixelSize:   11
                    }

                    Rectangle {
                        width:  130
                        height: 34
                        radius: 17

                        color: root.applying ||
                               root.wallpapers.length === 0 ||
                               (root.selectedIndex < root.wallpapers.length &&
                                root.wallpapers[root.selectedIndex].sourcePath === root.currentWall)
                                ? Colors.surfaceContainerHighest
                                : applyHov.containsMouse
                                    ? Colors.primaryContainer
                                    : Colors.primary

                        Behavior on color {
                            ColorAnimation { duration: Theme.hoverFadeDuration }
                        }

                        Text {
                            anchors.centerIn: parent

                            text: root.applying
                                      ? "Applying…"
                                      : (root.selectedIndex < root.wallpapers.length &&
                                         root.wallpapers[root.selectedIndex].sourcePath === root.currentWall)
                                            ? "󰄵 Applied"
                                            : "󰀝 Apply Wallpaper"

                            color: root.applying ||
                                   (root.selectedIndex < root.wallpapers.length &&
                                    root.wallpapers[root.selectedIndex].sourcePath === root.currentWall)
                                      ? Colors.on_SurfaceVariant
                                      : Colors.on_Primary

                            font.family:    Fonts.font
                            font.pixelSize: 11
                            font.bold:      true
                        }

                        MouseArea {
                            id:           applyHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor

                            enabled: !root.applying &&
                                     root.wallpapers.length > 0 &&
                                     root.selectedIndex < root.wallpapers.length &&
                                     root.wallpapers[root.selectedIndex].sourcePath !== root.currentWall

                            onClicked: {
                                root.applySelectedWallpaper()
                                wallCarousel.forceActiveFocus()
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string wallpaperDir: "~/wallpapers"

    property ListModel wallpapers: ListModel {}

    property string currentWall:  ""
    property int    selectedIndex: 0
    property bool   applying:     false

    property string _pendingWall: ""

    readonly property string thumbnailDir: Quickshell.cachePath("wallpaper-thumbnails-v2")
    readonly property int thumbnailWidth: 420
    readonly property int thumbnailHeight: 280

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

        return (hashA >>> 0).toString(16).padStart(8, "0")
             + (hashB >>> 0).toString(16).padStart(8, "0")
    }

    function _thumbnailPath(path, mtime, size) {
        const key = _hashKey(path + "\t" + mtime + "\t" + size)
        return root.thumbnailDir + "/" + key + ".webp"
    }

    function _shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'"
    }

    function _findDirectory() {
        const directory = root.wallpaperDir.trim()

        if (directory === "~") {
            return "$HOME"
        }

        if (directory.startsWith("~/")) {
            return "$HOME" + _shellQuote(directory.substring(1))
        }

        return _shellQuote(directory)
    }

    function _syncCurrentWallSelection() {
        if (!root.currentWall || root.wallpapers.count === 0) {
            return false
        }

        for (let i = 0; i < root.wallpapers.count; i++) {
            const item = root.wallpapers.get(i)

            if (item.sourcePath === root.currentWall) {
                root.selectedIndex = i
                return true
            }
        }

        return false
    }

    function queryCurrentWallpaper() {
        currentWallProc._lines = []
        currentWallProc.running = true
    }

    function _processCurrentWallpaperQuery(lines) {
        const output = lines.join("\n").trim()

        if (!output) return

        try {
            const data = JSON.parse(output)

            for (const namespace in data) {
                const outputs = data[namespace]

                if (!Array.isArray(outputs)) continue

                for (const outputInfo of outputs) {
                    if (!outputInfo || !outputInfo.displaying) continue

                    if (outputInfo.displaying.image) {
                        root.currentWall = outputInfo.displaying.image
                        root._syncCurrentWallSelection()
                        return
                    }
                }
            }
        } catch (error) {
            console.warn(
                "WallpaperModel: failed to parse awww query:",
                error
            )
        }
    }

    function scanWallpapers() {
        root._thumbnailQueue = []

        scanProc._lines  = []
        scanProc.running = true
    }

    function _beginThumbnailSync(lines) {
        root.wallpapers.clear()

        for (const line of lines) {
            const firstSep = line.indexOf("\t")
            if (firstSep < 0) continue

            const secondSep = line.indexOf("\t", firstSep + 1)
            if (secondSep < 0) continue

            const mtime = line.substring(0, firstSep)
            const size = line.substring(firstSep + 1, secondSep)
            const path = line.substring(secondSep + 1)

            if (!path) continue

            root.wallpapers.append({
                sourcePath: path,
                thumbnailPath: root._thumbnailPath(path, mtime, size),
                thumbReady: false
            })
        }

        const hasCurrentWallpaper = root._syncCurrentWallSelection()

        if (!hasCurrentWallpaper) {
            if (root.selectedIndex >= root.wallpapers.count) {
                root.selectedIndex = Math.max(
                    0,
                    root.wallpapers.count - 1
                )
            } else {
                root.selectedIndex = Math.max(
                    0,
                    root.selectedIndex
                )
            }
        }

        cacheMkdir.running = true
    }

    function _finishThumbnailSync(cacheLines) {
        const cached = new Set()

        for (const line of cacheLines) {
            const name = line.trim()

            if (name) {
                cached.add(name)
            }
        }

        const expected = new Set()

        for (let i = 0; i < root.wallpapers.count; i++) {
            const item = root.wallpapers.get(i)

            const name = item.thumbnailPath.substring(
                item.thumbnailPath.lastIndexOf("/") + 1
            )

            expected.add(name)

            if (cached.has(name)) {
                root.wallpapers.setProperty(
                    i,
                    "thumbReady",
                    true
                )
            }
        }

        root._rebuildThumbnailQueue()

        const orphanPaths = []

        for (const name of cached) {
            if (!expected.has(name)) {
                orphanPaths.push(
                    root.thumbnailDir + "/" + name
                )
            }
        }

        if (orphanPaths.length > 0) {
            cleanupProc.command = [
                "rm",
                "-f",
                ...orphanPaths
            ]

            cleanupProc.running = true
        }
    }

    function selectWallpaper(index) {
        if (root.wallpapers.count === 0) return

        root.selectedIndex = Math.max(
            0,
            Math.min(
                index,
                root.wallpapers.count - 1
            )
        )

        root._rebuildThumbnailQueue()
    }

    function selectRelative(delta) {
        if (root.wallpapers.count === 0) return

        root.selectWallpaper(
            root.selectedIndex + delta
        )
    }

    function applySelectedWallpaper() {
        if (root.applying) return

        if (root.selectedIndex < 0 ||
            root.selectedIndex >= root.wallpapers.count) {
            return
        }

        const selected = root.wallpapers.get(
            root.selectedIndex
        )

        if (!selected) return

        if (selected.sourcePath === root.currentWall) {
            return
        }

        root.applying     = true
        root._pendingWall = selected.sourcePath

        wallProc.running = true
    }

    function _rebuildThumbnailQueue() {
        if (root.wallpapers.count === 0) {
            root._thumbnailQueue = []
            return
        }

        const queued = new Set()
        const ordered = []

        const addIndex = (index) => {
            if (index < 0 ||
                index >= root.wallpapers.count) {
                return
            }

            const item = root.wallpapers.get(index)

            if (!item || item.thumbReady) return

            if (thumbProc._item &&
                thumbProc._item.sourcePath === item.sourcePath) {
                return
            }

            if (queued.has(item.sourcePath)) return

            queued.add(item.sourcePath)
            ordered.push(item)
        }

        const priorityOffsets = [
            0,
            -1,
            1,
            -2,
            2,
            -3,
            3
        ]

        for (const offset of priorityOffsets) {
            addIndex(root.selectedIndex + offset)
        }

        for (let i = 0; i < root.wallpapers.count; i++) {
            addIndex(i)
        }

        root._thumbnailQueue = ordered

        root._startNextThumbnail()
    }

    function _startNextThumbnail() {
        if (thumbProc.running ||
            root._thumbnailQueue.length === 0) {
            return
        }

        const next = root._thumbnailQueue.shift()

        thumbProc._item = next

        thumbProc.command = [
            "magick",
            next.sourcePath,
            "-auto-orient",
            "-thumbnail",
            root.thumbnailWidth +
            "x" +
            root.thumbnailHeight +
            "^",
            "-gravity", "center",
            "-extent",
            root.thumbnailWidth +
            "x" +
            root.thumbnailHeight,
            "-strip",
            "-quality",
            "82",
            next.thumbnailPath
        ]

        thumbProc.running = true
    }

    function _thumbnailFinished(success) {
        const finished = thumbProc._item

        thumbProc._item = null

        if (success && finished) {
            for (let i = 0; i < root.wallpapers.count; i++) {
                const item = root.wallpapers.get(i)

                if (item.sourcePath === finished.sourcePath &&
                    item.thumbnailPath === finished.thumbnailPath) {

                    root.wallpapers.setProperty(
                        i,
                        "thumbReady",
                        true
                    )

                    break
                }
            }
        }

        root._rebuildThumbnailQueue()
    }

    property Process scanProc: Process {
        command: [
            "sh",
            "-c",
            "find " + root._findDirectory() + " -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' " +
            "-o -iname '*.png' -o -iname '*.webp' \\) " +
            "-printf '%T@\\t%s\\t%p\\n' 2>/dev/null | sort -k3"
        ]

        running: false

        property var _lines: []

        stdout: SplitParser {
            onRead: (line) => {
                const p = line.trim()

                if (p) {
                    scanProc._lines.push(p)
                }
            }
        }

        onExited: {
            const lines = scanProc._lines.slice()

            scanProc._lines = []

            root._beginThumbnailSync(lines)
        }
    }

    property Process currentWallProc: Process {
        command: [
            "awww",
            "query",
            "-j"
        ]

        running: false

        property var _lines: []

        stdout: SplitParser {
            onRead: (line) => {
                const p = line.trim()

                if (p) {
                    currentWallProc._lines.push(p)
                }
            }
        }

        onExited: {
            const lines = currentWallProc._lines.slice()

            currentWallProc._lines = []

            root._processCurrentWallpaperQuery(lines)
        }
    }

    property Process cacheMkdir: Process {
        command: [
            "mkdir",
            "-p",
            root.thumbnailDir
        ]

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

    property Process cacheList: Process {
        running: false

        property var _lines: []

        stdout: SplitParser {
            onRead: (line) => {
                const p = line.trim()

                if (p) {
                    cacheList._lines.push(p)
                }
            }
        }

        onExited: {
            const lines = cacheList._lines.slice()

            cacheList._lines = []

            root._finishThumbnailSync(lines)
        }
    }

    property Process cleanupProc: Process {
        running: false

        onExited: root._startNextThumbnail()
    }

    property Process thumbProc: Process {
        running: false

        property var _item: null

        onExited: (exitCode, exitStatus) => {
            root._thumbnailFinished(
                exitCode === 0
            )
        }
    }

    property Process wallProc: Process {
        command: [
            "fish",
            "-c",
            "source ~/.config/fish/functions/wall.fish; wall $argv[1]",
            "--",
            root._pendingWall
        ]

        running: false

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.currentWall = root._pendingWall
            }

            root.applying = false
        }
    }
}

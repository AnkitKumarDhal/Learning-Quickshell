pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var history: []
    property var filteredHistory: []
    property string searchQuery: ""
    property string filterCategory: "all"

    property bool loading: false
    property string errorMessage: ""

    property var _metadata: ({
        pinned: {},
        usedAt: {}
    })

    property var _previewSearchMatches: []

    function itemSignature(item) {
        if (item.kind === "image")
            return "image:" + item.id

        return "text:" + item.preview
    }

    function isPinned(item) {
        return !!root._metadata.pinned[itemSignature(item)]
    }

    function relativeTime(timestamp) {
        if (!timestamp)
            return "Earlier"

        const elapsed = Math.max(0, Date.now() - timestamp)
        const seconds = Math.floor(elapsed / 1000)
        const minutes = Math.floor(seconds / 60)
        const hours = Math.floor(minutes / 60)
        const days = Math.floor(hours / 24)

        if (seconds < 10) return "Just now"
        if (seconds < 60) return seconds + "s ago"
        if (minutes < 60) return minutes + "m ago"
        if (hours < 24) return hours + "h ago"
        if (days < 7) return days + "d ago"

        return new Date(timestamp).toLocaleDateString()
    }

    function recencyLabel(item, index) {
        const usedAt = root._metadata.usedAt[itemSignature(item)] || 0

        if (usedAt > 0)
            return root.relativeTime(usedAt)

        if (index === 0) return "Latest"
        if (index < 5) return "Recent"

        return "Earlier"
    }

    function parseItem(line) {
        const tabIdx = line.indexOf('\t')
        if (tabIdx < 0)
            return null

        const id = line.substring(0, tabIdx).trim()
        const preview = line.substring(tabIdx + 1)

        if (id === "")
            return null

        const imageMatch = preview.match(
            /^\[\[\s*binary data\s+(\d+(?:\.\d+)?\s+\w+)\s+(\w+)\s+(\d+)x(\d+)\s*\]\]$/i
        )

        if (imageMatch) {
            const format = imageMatch[2].toLowerCase()
            const extension = format === "jpeg" ? "jpg" : format
            const mimeType = format === "jpg" || format === "jpeg"
                              ? "image/jpeg"
                              : "image/" + format

            return {
                id: id,
                preview: preview,
                kind: "image",
                mimeType: mimeType,
                format: format,
                extension: extension,
                sizeText: imageMatch[1],
                width: Number(imageMatch[3]),
                height: Number(imageMatch[4]),
                imagePath: Quickshell.cachePath("clipboard/images/" + id + "." + extension)
            }
        }

        const isLink = /^(https?:\/\/|www\.)/i.test(preview.trim())
        const isCode = /(^|\n)\s*(#include\b|import\s+|from\s+\S+\s+import\s+|const\s+|let\s+|var\s+|function\s+|class\s+|def\s+|sudo\s+|git\s+|npm\s+|pnpm\s+|yarn\s+|pacman\s+|curl\s+|wget\s+)/i.test(preview)
        const isShebang = preview.trim().startsWith("#!")

        return {
            id: id,
            preview: preview,
            kind: isLink ? "link" : (isCode || isShebang) ? "code" : "text",mimeType: "text/plain",
            format: "",
            extension: "",
            sizeText: "",
            width: 0,
            height: 0,
            imagePath: ""
        }
    }

    function matchesCategory(item) {
        if (root.filterCategory === "all")
            return true

        if (root.filterCategory === "pinned")
            return root.isPinned(item)

        if (root.filterCategory === "images")
            return item.kind === "image"

        return item.kind === root.filterCategory
    }

    function refresh() {
        if (listProc.running) {
            listProc._refreshPending = true
            return
        }

        root.loading = true
        root.errorMessage = ""
        listProc._tempHist = []
        listProc._refreshPending = false
        listProc.running = true
    }

    function applyFilter() {
        const query = root.searchQuery.trim().toLowerCase()
        const result = []

        if (query === "") {
            for (let i = 0; i < root.history.length; i++) {
                const item = root.history[i]
                if (root.matchesCategory(item))
                    result.push(item)
            }

            root.filteredHistory = result
            return
        }

        const previewMatches = []

        for (let i = 0; i < root.history.length; i++) {
            const item = root.history[i]
            if (!root.matchesCategory(item))
                continue

            if (item.preview.toLowerCase().includes(query))
                previewMatches.push(item)
        }

        root._previewSearchMatches = previewMatches
        root.filteredHistory = previewMatches
        startFullSearch(query)
    }

    function onSearchQueryChanged() {
        filterDebounce.restart()
    }

    function setFilterCategory(category) {
        if (root.filterCategory === category) {
            root.applyFilter()
            return
        }

        root.filterCategory = category
        root.applyFilter()
    }

    function startFullSearch(query) {
        searchProc._query = query
        searchProc._matches = []

        searchProc.exec([
            "sh",
            "-c",
            "cliphist list | while IFS=$'\\t' read -r id preview; do case \"$preview\" in \"[[ binary data \"*) continue ;; esac; if printf '%s\\t\\n' \"$id\" | cliphist decode 2>/dev/null | LC_ALL=C grep -Fqi -- \"$1\"; then printf '%s\\n' \"$id\"; fi; done",
            "--",
            query
        ])
    }

    function finishSearch() {
        if (searchProc._query !== root.searchQuery.trim().toLowerCase())
            return

        const matches = {}

        for (let i = 0; i < searchProc._matches.length; i++)
            matches[searchProc._matches[i]] = true

        const result = []

        for (let i = 0; i < root.history.length; i++) {
            const item = root.history[i]

            if (!root.matchesCategory(item))
                continue

            const previewMatched = item.kind === "image" && root._previewSearchMatches.some(
                (previewItem) => previewItem.id === item.id
            )

            if (matches[item.id] || previewMatched)
                result.push(item)
        }

        root.filteredHistory = result
    }

    function copy(item) {
        if (!item || !item.id)
            return

        root._metadata.usedAt[itemSignature(item)] = Date.now()
        saveMetadata()

        copyProc.exec([
            "sh",
            "-c",
            "printf '%s\\t\\n' \"$1\" | cliphist decode | wl-copy",
            "--",
            item.id
        ])
    }

    function togglePin(item) {
        if (!item || !item.id)
            return

        const signature = itemSignature(item)

        if (root._metadata.pinned[signature])
            delete root._metadata.pinned[signature]
        else
            root._metadata.pinned[signature] = true

        saveMetadata()
        root.applyFilter()
    }

    function deleteItem(item) {
        if (!item || !item.id)
            return

        const signature = itemSignature(item)

        delete root._metadata.pinned[signature]
        delete root._metadata.usedAt[signature]

        saveMetadata()

        if (deleteProc.running) {
            deleteProc._queue.push(item.id)
            return
        }

        deleteProc._itemId = item.id
        deleteProc.running = true
    }

    function startNextDelete() {
        if (deleteProc._queue.length === 0) {
            refresh()
            return
        }

        deleteProc._itemId = deleteProc._queue.shift()
        deleteProc.running = true
    }

    function wipe() {
        if (wipeProc.running)
            return

        root.loading = true
        root.errorMessage = ""
        wipeProc.running = true
    }

    function saveMetadata() {
        metadataFile.setText(JSON.stringify(root._metadata))
    }

    FileView {
        id: metadataFile

        path: Quickshell.statePath("clipboard.json")
        preload: true
        watchChanges: false

        onLoaded: {
            try {
                const data = JSON.parse(metadataFile.text())

                root._metadata = {
                    pinned: data.pinned || {},
                    usedAt: data.usedAt || {}
                }
            } catch (e) {
                root._metadata = {
                    pinned: {},
                    usedAt: {}
                }
            }

            root.applyFilter()
        }

        onLoadFailed: {
            root._metadata = {
                pinned: {},
                usedAt: {}
            }

            root.applyFilter()
        }
    }

    Timer {
        id: filterDebounce

        interval: 150

        onTriggered: root.applyFilter()
    }

    Process {
        id: listProc

        command: ["cliphist", "list"]
        running: false

        property var _tempHist: []
        property bool _refreshPending: false

        stdout: SplitParser {
            onRead: (line) => {
                if (line.trim() !== "")
                    listProc._tempHist.push(line)
            }
        }

        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            root.loading = false

            if (exitCode !== 0) {
                root.errorMessage = "Unable to read clipboard history."
            } else {
                const parsed = []

                for (let i = 0; i < listProc._tempHist.length; i++) {
                    const item = root.parseItem(listProc._tempHist[i])

                    if (item)
                        parsed.push(item)
                }

                root.history = parsed
                root.errorMessage = ""
                root.applyFilter()
            }

            listProc._tempHist = []

            if (listProc._refreshPending) {
                listProc._refreshPending = false
                root.refresh()
            }
        }
    }

    Process {
        id: searchProc

        property string _query: ""
        property var _matches: []

        stdout: SplitParser {
            onRead: (line) => {
                if (line.trim() !== "")
                    searchProc._matches.push(line.trim())
            }
        }

        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0)
                root.finishSearch()
        }
    }

    Process {
        id: copyProc

        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.errorMessage = "Unable to copy clipboard item."
        }
    }

    Process {
        id: deleteProc

        property string _itemId: ""
        property var _queue: []

        command: [
            "sh",
            "-c",
            "printf '%s\\t\\n' \"$1\" | cliphist delete",
            "--",
            _itemId
        ]

        running: false

        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.errorMessage = "Unable to delete clipboard item."

            if (deleteProc._queue.length > 0)
                root.startNextDelete()
            else
                root.refresh()
        }
    }

    Process {
        id: wipeProc

        command: ["cliphist", "wipe"]
        running: false

        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.loading = false
                root.errorMessage = "Unable to clear clipboard history."
                return
            }

            root._metadata = {
                pinned: {},
                usedAt: {}
            }

            root.saveMetadata()
            root.refresh()
        }
    }
}

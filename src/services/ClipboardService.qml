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

    property var imageStates: ({})

    property var _metadata: ({
        pinned: {},
        usedAt: {}
    })

    property var _previewSearchMatches: []
    property bool searchCacheReady: false

    property bool _searchCachePending: false
    property bool _searchPending: false

    readonly property string stateFilePath: Quickshell.statePath("clipboard.json")
    readonly property string imageCachePath: Quickshell.cachePath("clipboard/images")
    readonly property string searchCachePath: Quickshell.cachePath("clipboard/search")

    function itemSignature(item) {
        return item.id
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

    function recencyLabel(item) {
        const usedAt = root._metadata.usedAt[itemSignature(item)] || 0

        if (usedAt > 0)
            return "Used " + root.relativeTime(usedAt)

        if (item.position === 0)
            return "Latest"

        if (item.position < 5)
            return "Recent"

        return "Earlier"
    }

    function categoryLabel(category) {
        switch (category) {
        case "text":
            return "Text"

        case "images":
            return "Images"

        case "link":
            return "Links"

        case "code":
            return "Code"

        case "pinned":
            return "Pinned"

        default:
            return "All"
        }
    }

    function resultCountLabel() {
        const count = root.filteredHistory.length

        if (root.searchQuery.trim() !== "")
            return count + " result" + (count === 1 ? "" : "s")

        if (root.filterCategory !== "all")
            return count + " " + root.categoryLabel(root.filterCategory).toLowerCase()

        return count + " item" + (count === 1 ? "" : "s")
    }

    function parseItem(line, position) {
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
                imagePath: root.imageCachePath + "/" + id + "." + extension,
                position: position
            }
        }

        const isLink = /^(https?:\/\/|www\.)/i.test(preview.trim())

        const isCode = /(^|\n)\s*(#include\b|import\s+|from\s+\S+\s+import\s+|const\s+|let\s+|var\s+|function\s+|class\s+|def\s+|sudo\s+|git\s+|npm\s+|pnpm\s+|yarn\s+|pacman\s+|curl\s+|wget\s+)/i.test(preview)

        const isShebang = preview.trim().startsWith("#!")

        return {
            id: id,
            preview: preview,
            kind: isLink ? "link" : (isCode || isShebang) ? "code" : "text",
            mimeType: "text/plain",
            format: "",
            extension: "",
            sizeText: "",
            width: 0,
            height: 0,
            imagePath: "",
            position: position
        }
    }

    function matchesCategory(item) {
        switch (root.filterCategory) {
        case "all":
            return true

        case "text":
            return item.kind === "text"

        case "images":
            return item.kind === "image"

        case "link":
            return item.kind === "link"

        case "code":
            return item.kind === "code"

        case "pinned":
            return root.isPinned(item)

        default:
            return true
        }
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
            searchProc._query = ""
            searchProc.exec(["true"])

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

        root.startFullSearch(query)
    }

    onSearchQueryChanged: filterDebounce.restart()

    function setFilterCategory(category) {
        if (root.filterCategory === category) {
            root.applyFilter()
            return
        }

        root.filterCategory = category
        root.applyFilter()
    }

    function startFullSearch(query) {
        if (query === "")
            return

        if (!root.searchCacheReady) {
            root._searchPending = true
            root.ensureSearchCache()
            return
        }

        root._searchPending = false

        searchProc._query = query
        searchProc._matches = []

        searchProc.exec([
            "sh",
            "-c",
            "find \"$1\" -type f -name '*.txt' -exec grep -ilaF -- \"$2\" {} + 2>/dev/null",
            "--",
            root.searchCachePath,
            query
        ])
    }

    function ensureSearchCache() {
        if (cacheProc.running) {
            root._searchCachePending = true
            return
        }

        cacheProc.running = true
    }

    function finishSearchCache() {
        root.searchCacheReady = true

        if (root._searchCachePending) {
            root._searchCachePending = false
            root.ensureSearchCache()
            return
        }

        if (root._searchPending) {
            root._searchPending = false
            root.startFullSearch(root.searchQuery.trim().toLowerCase())
            return
        }

        if (root.searchQuery.trim() !== "")
            root.startFullSearch(root.searchQuery.trim().toLowerCase())
    }

    function finishSearch() {
        const query = root.searchQuery.trim().toLowerCase()

        if (searchProc._query !== query)
            return

        const matches = {}

        for (let i = 0; i < searchProc._matches.length; i++) {
            const path = searchProc._matches[i]
            const filename = path.substring(path.lastIndexOf("/") + 1)

            if (!filename.endsWith(".txt"))
                continue

            const id = filename.substring(0, filename.length - 4)

            matches[id] = true
        }

        const result = []

        for (let i = 0; i < root.history.length; i++) {
            const item = root.history[i]

            if (!root.matchesCategory(item))
                continue

            const previewMatched = root._previewSearchMatches.some(
                (previewItem) => previewItem.id === item.id
            )

            if (matches[item.id] || previewMatched)
                result.push(item)
        }

        result.sort((a, b) => {
            const aText = a.preview.toLowerCase()
            const bText = b.preview.toLowerCase()

            function score(text, fullMatch) {
                if (text === query)
                    return 0

                if (text.startsWith(query))
                    return 1

                const wordMatch = new RegExp(
                    "(^|\\s)" + query.replace(
                        /[.*+?^${}()|[\]\\]/g,
                        "\\$&"
                    ) + "(\\s|$)",
                    "i"
                ).test(text)

                if (wordMatch)
                    return 2

                if (text.includes(query))
                    return 3

                return fullMatch ? 4 : 5
            }

            const aScore = score(aText, !!matches[a.id])
            const bScore = score(bText, !!matches[b.id])

            if (aScore !== bScore)
                return aScore - bScore

            return a.position - b.position
        })

        root.filteredHistory = result
    }

    function setImageState(id, state) {
        const states = Object.assign({}, root.imageStates)

        states[id] = state

        root.imageStates = states
    }

    function ensureImage(item) {
        if (!item || item.kind !== "image")
            return

        const state = root.imageStates[item.id] || 0

        if (state === 1 || state === 2)
            return

        root.setImageState(item.id, 1)

        imageProc._queue.push({
            id: item.id,
            path: item.imagePath
        })

        root.startNextImage()
    }

    function startNextImage() {
        if (imageProc.running)
            return

        if (imageProc._queue.length === 0)
            return

        const next = imageProc._queue.shift()

        imageProc._currentId = next.id
        imageProc._currentPath = next.path
        imageProc.running = true
    }

    function copy(item) {
        if (!item || !item.id)
            return

        root.errorMessage = ""

        const signature = root.itemSignature(item)

        const usedAt = Object.assign({}, root._metadata.usedAt)

        usedAt[signature] = Date.now()

        root._metadata = {
            pinned: root._metadata.pinned,
            usedAt: usedAt
        }

        root.saveMetadata()

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

        const signature = root.itemSignature(item)
        const pinned = Object.assign({}, root._metadata.pinned)

        if (pinned[signature])
            delete pinned[signature]
        else
            pinned[signature] = true

        root._metadata = {
            pinned: pinned,
            usedAt: root._metadata.usedAt
        }

        root.saveMetadata()
        root.applyFilter()
    }

    function deleteItem(item) {
        if (!item || !item.id)
            return

        const signature = root.itemSignature(item)

        const pinned = Object.assign({}, root._metadata.pinned)
        const usedAt = Object.assign({}, root._metadata.usedAt)

        delete pinned[signature]
        delete usedAt[signature]

        root._metadata = {
            pinned: pinned,
            usedAt: usedAt
        }

        root.saveMetadata()

        if (deleteProc.running) {
            deleteProc._queue.push(item.id)
            return
        }

        deleteProc._queue = []
        deleteProc._itemId = item.id
        deleteProc.running = true
    }

    function startNextDelete() {
        if (deleteProc._queue.length === 0) {
            root.refresh()
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

        path: root.stateFilePath
        preload: true
        watchChanges: false
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(metadataFile.text())

                root._metadata = {
                    pinned: data.pinned || {},
                    usedAt: data.usedAt || {}
                }
            } catch (error) {
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

        onSaveFailed: {
            root.errorMessage = "Unable to save clipboard metadata."
        }
    }

    Timer {
        id: filterDebounce

        interval: 150
        repeat: false

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
                    const item = root.parseItem(listProc._tempHist[i], i)

                    if (item)
                        parsed.push(item)
                }

                root.history = parsed
                root.errorMessage = ""

                root.applyFilter()
                root.ensureSearchCache()
            }

            listProc._tempHist = []

            if (listProc._refreshPending) {
                listProc._refreshPending = false
                root.refresh()
            }
        }
    }

    Process {
        id: cacheProc

        command: [
            "sh",
            "-c",
            "mkdir -p \"$1\" && cliphist list | while IFS=\"$(printf '\\t')\" read -r id preview; do case \"$preview\" in \"[[ binary data \"*) continue ;; esac; [ -s \"$1/$id.txt\" ] || printf '%s\\t\\n' \"$id\" | cliphist decode > \"$1/$id.txt\"; done; exit 0",
            "--",
            root.searchCachePath
        ]

        running: false

        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                if (!root.searchCacheReady)
                    root.errorMessage = "Unable to build clipboard search cache."

                return
            }

            root.finishSearchCache()
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
            if (exitCode === 0 && searchProc._query !== "")
                root.finishSearch()
        }
    }

    Process {
        id: imageProc

        property var _queue: []
        property string _currentId: ""
        property string _currentPath: ""

        command: [
            "sh",
            "-c",
            "mkdir -p \"$1\" && if [ -s \"$3\" ]; then exit 0; fi; printf '%s\\t\\n' \"$2\" | cliphist decode > \"$3\"",
            "--",
            root.imageCachePath,
            _currentId,
            _currentPath
        ]

        running: false

        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (_currentId !== "") {
                root.setImageState(_currentId, exitCode === 0 ? 2 : 3)

                if (exitCode !== 0)
                    root.errorMessage = "Unable to load an image from clipboard history."
            }

            _currentId = ""
            _currentPath = ""

            root.startNextImage()
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
            "printf '%s\\n' \"$1\" | cliphist delete",
            "--",
            _itemId
        ]

        running: false

        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.errorMessage = "Unable to delete clipboard item."
            } else {
                cleanupProc.exec([
                    "rm",
                    "-f",
                    root.searchCachePath + "/" + deleteProc._itemId + ".txt"
                ])
            }

            root.startNextDelete()
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
            cleanupProc.exec([
                "rm",
                "-rf",
                root.searchCachePath
            ])
            root.refresh()
        }
    }
}

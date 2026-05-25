pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var history: []
    property var filteredHistory: []
    property string searchQuery: ""

    onSearchQueryChanged: applyFilter()

    function refresh() {
        listProc.running = true
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        running: false

        property var _tempHist: []

        stdout: SplitParser {
            onRead: (line) => {
                if (line.trim() !== "") listProc._tempHist.push(line)
            }
        }
        onExited: {
            root.history = listProc._tempHist.slice()
            listProc._tempHist = []
            root.applyFilter()
        }
    }

    function applyFilter() {
        if (root.searchQuery === "") {
            root.filteredHistory = root.history
        } else {
            const q = root.searchQuery.toLowerCase()
            root.filteredHistory = root.history.filter(item => {
                const content = item.substring(item.indexOf('\t') + 1)
                return content.toLowerCase().includes(q)
            })
        }
    }

    function copy(item) {
        copyProc.itemData = item
        copyProc.running = true
    }

    Process {
        id: copyProc
        property string itemData: ""
        command: ["sh", "-c", "printf '%s\n' \"$1\" | cliphist decode | wl-copy", "--", itemData]
        running: false
        onExited: root.refresh()
    }

    function wipe() {
        wipeProc.running = true
    }

    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
        running: false
        onExited: root.refresh()
    }
}

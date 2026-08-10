pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var history: []
    property var filteredHistory: []
    property string searchQuery: ""

    // Debounced clipboard search to avoid filtering on every keystroke
    property string _pendingQuery: ""
    
    Timer {
        id: filterDebounce
        interval: 150
        onTriggered: root.applyFilter()
    }
    
    function applyFilter() {
        if (root.searchQuery === "") {
            root.filteredHistory = root.history
        } else {
            const q = root.searchQuery.toLowerCase()
            const result = []
            
            // Optimized linear scan with early character comparison
            for (let i = 0; i < root.history.length; i++) {
                const item = root.history[i]
                const tabIdx = item.indexOf('\t')
                if (tabIdx < 0) continue
                
                const content = item.substring(tabIdx + 1).toLowerCase()
                
                // Fast path: check first character match
                if (content.length > 0 && content[0] === q[0]) {
                    if (content.startsWith(q)) {
                        result.push(item)
                    } else if (content.includes(q)) {
                        result.push(item)
                    }
                } else if (content.includes(q)) {
                    result.push(item)
                }
            }
            
            root.filteredHistory = result
        }
    }
    
    function onSearchQueryChanged() {
        root._pendingQuery = root.searchQuery
        filterDebounce.restart()
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

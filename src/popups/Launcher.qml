import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import qs.src.theme
import qs.src.state
import qs.src.popups.launcher

PanelWindow {
    id: root
    property var screen

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true; left: true; right: true; bottom: true }

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Popups.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // ── Delayed visibility (lets close animation finish) ──────────────────
    property bool _shouldShow: false
    visible: _shouldShow

    Connections {
        target: Popups
        function onLauncherOpenChanged() {
            if (Popups.launcherOpen) {
                closeDelay.stop()
                root._shouldShow = true
            } else {
                closeDelay.start()
            }
        }
    }
    Timer {
        id:          closeDelay
        interval:    Theme.animDuration + 30
        onTriggered: root._shouldShow = false
    }

    onVisibleChanged: {
        if (visible) {
            searchBar.clear()
            root.selectedIndex = 0
            if (root.hasLoadedOnce) {
                root.filterApps()
            }
            appLoader.reload()
            // Delay focus to ensure WlrLayershell keyboard grab is fully active
            Qt.callLater(() => {
                Qt.callLater(() => {
                    searchBar.forceActiveFocus()
                })
            })
        }
    }

    // ── State ─────────────────────────────────────────────────────────────
    property int selectedIndex: 0
    property var allApps:       []
    property var filteredApps:  []
    property var hasLoadedOnce: false
    property bool loadFailed:   false

    // Debounced search to avoid filtering on every keystroke
    property string _pendingQuery: ""
    
    function filterApps() {
        const q = searchBar.text.toLowerCase().trim()
        root._pendingQuery = q
        
        if (q === "") {
            root.filteredApps = root.allApps.slice(0, 48)
        } else {
            // Optimized filtering with early exit and cached lowercase values
            const matches = []
            const startsWith = []
            
            for (let i = 0; i < root.allApps.length && matches.length < 48; i++) {
                const app = root.allApps[i]
                const name = (app.name || "").toLowerCase()
                
                // Check if name starts with query (highest priority)
                if (name.startsWith(q)) {
                    startsWith.push(app)
                    continue
                }
                
                // Check if name or comment contains query
                if (name.includes(q) || (app.comment || "").toLowerCase().includes(q)) {
                    matches.push(app)
                }
            }
            
            // Sort: startsWith first, then contains, alphabetically
            startsWith.sort((a, b) => (a.name || "").localeCompare(b.name || ""))
            matches.sort((a, b) => (a.name || "").localeCompare(b.name || ""))
            
            root.filteredApps = [...startsWith, ...matches].slice(0, 48)
        }
        root.selectedIndex = 0
    }
    
    // Debounce timer for search
    Timer {
        id: filterDebounce
        interval: 150
        onTriggered: root.filterApps()
    }
    
    // Modified text change handler to use debounce
    function onSearchTextChanged() {
        filterDebounce.restart()
    }

    function launch(idx) {
        const app = root.filteredApps[idx]
        if (!app || !app.exec) return
        launchProc.command = ["sh", "-c", app.exec.replace(/%[uUfFdDnNickvm]/g, "").trim()]
        launchProc.running = true
        Popups.launcherOpen = false
    }

    // ── App loader ────────────────────────────────────────────────────────
    LauncherAppLoader {
        id: appLoader
        onLoaded: (apps) => {
            root.hasLoadedOnce = true
            root.loadFailed = false
            root.allApps = apps
            root.filterApps()
        }
        onFailed: root.loadFailed = true
    }

    // ── Launch process (fire-and-forget) ──────────────────────────────────
    Process {
        id:      launchProc
        command: []
        running: false
    }

    // ── Dim overlay ───────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color:        Qt.rgba(0, 0, 0, 0.55)
        opacity:      Popups.launcherOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.InOutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked:    Popups.launcherOpen = false
        }
    }

    // ── Center card ───────────────────────────────────────────────────────
    Rectangle {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top:              parent.top
        anchors.topMargin:        Math.max(72, (parent.height - height) * 0.28)

        width:  620
        height: searchBar.height + 1 + resultsList.height
        radius: Theme.popupRadius + 6
        color:  Colors.surfaceContainer
        border.color: Colors.outlineVariant
        border.width: Theme.popupBorder
        clip:         true

        property real yOffset: Popups.launcherOpen ? 0 : -18
        Behavior on yOffset { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
        transform: Translate { y: card.yOffset }

        opacity: Popups.launcherOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }

        // ── Search bar ────────────────────────────────────────────────────
        LauncherSearchBar {
            id:          searchBar
            anchors { top: parent.top; left: parent.left; right: parent.right }
            resultCount: root.filteredApps.length
            showCount:   text !== ""

            onTextChanged:  root.onSearchTextChanged()
            onEscapePressed: Popups.launcherOpen = false
            onReturnPressed: root.launch(root.selectedIndex)
            onUpPressed: {
                if (root.selectedIndex > 0) {
                    root.selectedIndex--
                    resultsList.positionAt(root.selectedIndex)
                }
            }
            onDownPressed: {
                if (root.selectedIndex < root.filteredApps.length - 1) {
                    root.selectedIndex++
                    resultsList.positionAt(root.selectedIndex)
                }
            }
            onTabPressed: {
                root.selectedIndex = (root.selectedIndex + 1) % Math.max(root.filteredApps.length, 1)
                resultsList.positionAt(root.selectedIndex)
            }
        }

        // Divider
        Rectangle {
            id:      divider
            anchors { top: searchBar.bottom; left: parent.left; right: parent.right }
            height:  1
            color:   Colors.outlineVariant
            opacity: 0.5
        }

        // ── Results list ──────────────────────────────────────────────────
        LauncherResultsList {
            id:           resultsList
            anchors { top: divider.bottom; left: parent.left; right: parent.right }
            filteredApps:  root.filteredApps
            selectedIndex: root.selectedIndex
            searchText:    searchBar.text

            onLaunched:         (idx) => root.launch(idx)
            onSelectionChanged: (idx) => root.selectedIndex = idx

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: resultsList.width
                    height: resultsList.height
                    bottomLeftRadius: Theme.popupRadius + 6
                    bottomRightRadius: Theme.popupRadius + 6
                }
            }
        }
    }
}

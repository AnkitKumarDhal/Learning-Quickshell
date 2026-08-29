pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.src.theme
import qs.src.state

Singleton {
    id: root

    property string stateFilePath: Quickshell.statePath("launcher.json")

    property var pinnedIds:  []
    property var recentIds:  []
    property var pinnedApps: []
    property var recentApps: []

    property int revision: 0

    property string pendingFocusAddress: ""

    function appKey(app) {
        if (!app) return ""
        if (app.id) return app.id

        return (app.name || "") + "|" + (app.command || []).join("\u0001")
    }

    function refreshApps(apps) {
        const source = apps && apps.length !== undefined ? apps : []
        const byKey = {}
        const nextPinned = []
        const nextRecent = []
        const pinned = []
        const recent = []

        for (let i = 0; i < source.length; i++) {
            const app = source[i]
            const key = root.appKey(app)
            if (!key || app.noDisplay) continue
            byKey[key] = app
        }

        for (let i = 0; i < root.pinnedIds.length; i++) {
            const key = root.pinnedIds[i]

            if (byKey[key]) {
                nextPinned.push(key)
                pinned.push(byKey[key])
            }
        }

        for (let i = 0; i < root.recentIds.length; i++) {
            const key = root.recentIds[i]

            if (byKey[key] && nextRecent.indexOf(key) === -1) {
                nextRecent.push(key)

                if (nextPinned.indexOf(key) === -1) {
                    recent.push(byKey[key])
                }
            }
        }

        root.pinnedIds = nextPinned
        root.recentIds = nextRecent
        root.pinnedApps = pinned
        root.recentApps = recent
        root.revision++
    }

    function recordLaunch(app) {
        const key = root.appKey(app)
        if (!key) return
        const next = [key]

        for (let i = 0; i < root.recentIds.length && next.length < 24; i++) {
            if (root.recentIds[i] !== key) {
                next.push(root.recentIds[i])
            }
        }

        root.recentIds = next
        root.refreshApps(DesktopEntries.applications.values)
        root.save()
    }

    function isPinned(app) {
        const key = root.appKey(app)
        return (key !== "" && root.pinnedIds.indexOf(key) !== -1)
    }

    function togglePin(app) {
        const key = root.appKey(app)
        if (!key) return
        const next = root.pinnedIds.slice()
        const index = next.indexOf(key)

        if (index === -1) next.push(key)
        else next.splice(index, 1)

        root.pinnedIds = next
        root.refreshApps(DesktopEntries.applications.values)
        root.save()
    }

    function save() {
        launcherState.setText(JSON.stringify({ pinned: root.pinnedIds, recent: root.recentIds }))
    }

    function normalizeClass(value) {
        return String(value || "").trim().toLowerCase()
    }

    function findExistingWindow(app) {
        if (!app) return null

        const startupClass = root.normalizeClass(app.startupClass)
        const appId = root.normalizeClass(app.id)
        const name = root.normalizeClass(app.name)

        Hyprland.refreshToplevels()

        const toplevels = Hyprland.toplevels.values

        for (let i = 0; i < toplevels.length; i++) {
            const toplevel = toplevels[i]
            const data = toplevel.lastIpcObject || {}
            const classes = [
                data.initialClass,
                data.class,
                data.appid,
                data.initialClassName,
                data.xwaylandClass
            ].filter(value => value).map(value => root.normalizeClass(value))

            if (startupClass && classes.indexOf( startupClass) !== -1) return toplevel
            if (appId && classes.indexOf(appId) !== -1) return toplevel
            if (name && classes.indexOf( name) !== -1) return toplevel
        }

        return null
    }

    function focusExisting(app) {
        const toplevel = root.findExistingWindow(app)
        if (!toplevel || !toplevel.address) return false

        let address = String(toplevel.address)

        if (!address.startsWith("0x")) {
            address = "0x" + address
        }

        root.pendingFocusAddress = address
        Popups.launcherOpen = false
        pendingFocusTimer.start()

        return true
    }

    FileView {
        id: launcherState

        path: root.stateFilePath
        preload: true
        watchChanges: false
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(launcherState.text())
                root.pinnedIds = Array.isArray(data.pinned) ? data.pinned : []
                root.recentIds = Array.isArray(data.recent) ? data.recent : []
            } catch (error) {
                root.pinnedIds = []
                root.recentIds = []
            }

            root.refreshApps(DesktopEntries.applications.values)
        }

        onLoadFailed: {
            root.pinnedIds = []
            root.recentIds = []
            root.refreshApps(DesktopEntries.applications.values)
        }
    }

    Timer {
        id: pendingFocusTimer

        interval: Theme.animDuration + 60
        running: false
        repeat: false

        onTriggered: {
            if (!root.pendingFocusAddress) return
            const address = root.pendingFocusAddress
            root.pendingFocusAddress = ""

            if (Hyprland.usingLua) {
                Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + address + "\" })")
            } else {
                Hyprland.dispatch("focuswindow address:" + address)
            }
        }
    }
}

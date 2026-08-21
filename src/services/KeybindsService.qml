pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var binds: []
    property var sections: []
    property bool loading: false
    property string error: ""

    readonly property var categoryOrder: [
        "Launchers",
        "Window Management",
        "Workspaces",
        "Media",
        "Screenshots",
        "System"
    ]

    function refresh() {
        if (bindProc.running) return

        root.loading = true
        root.error = ""

        bindProc._output = []
        bindProc.running = true
    }

    function _parseOutput() {
        const text = bindProc._output.join("\n").trim()

        root.loading = false

        if (!text) {
            root.binds = []
            root.sections = []
            root.error = "Hyprland returned no keybind data."
            return
        }

        try {
            const parsed = JSON.parse(text)

            if (!Array.isArray(parsed)) {
                root.binds = []
                root.sections = []
                root.error = "Hyprland returned an unexpected bind format."
                return
            }

            const entries = []

            for (const bind of parsed) {
                if (_shouldHide(bind)) continue

                entries.push(_makeEntry(bind))
            }

            root.binds = entries
            root.sections = _buildSections(entries)
            root.error = ""
        } catch (error) {
            root.binds = []
            root.sections = []
            root.error = "Failed to parse Hyprland keybind data."

            console.error(
                "KeybindsService: JSON parsing failed:",
                error
            )
        }
    }

    function _shouldHide(bind) {
        const key = bind.key || ""
        const description = bind.description || ""

        // Mouse binds are not useful in a keyboard reference page.
        if (bind.mouse) return true
        if (key.startsWith("mouse:")) return true
        if (key === "mouse_down" || key === "mouse_up") return true

        // Lid-switch binds are hardware events, not keyboard shortcuts.
        if (key.startsWith("switch:")) return true
        // Hide binds without descriptions.
        if (!description.trim()) return true

        return false
    }

    function _makeEntry(bind) {
        const description = bind.description && bind.description.length > 0 ? bind.description : "No description"

        return {
            key: _formatKey(bind),
            keyParts: _makeKeyParts(bind),
            description: description,
            category: _categoryFor(bind),
            dispatcher: bind.dispatcher || "",
            argument: bind.arg || "",
            submap: bind.submap || "",
            modmask: Number(bind.modmask || 0),
            mouse: !!bind.mouse,
            release: !!bind.release,
            repeat: !!bind.repeat,
            locked: !!bind.locked
        }
    }

    function _makeKeyParts(bind) {
        const parts = []

        const modmask = Number(bind.modmask || 0)

        // Hyprland modifier masks.
        if (modmask & 64) parts.push("SUPER")
        if (modmask & 4) parts.push("CTRL")
        if (modmask & 8) parts.push("ALT")
        if (modmask & 1) parts.push("SHIFT")
        if (modmask & 2) parts.push("CAPS")
        if (modmask & 16) parts.push("MOD2")
        if (modmask & 32) parts.push("MOD3")
        if (modmask & 128) parts.push("MOD5")

        let key = bind.key || ""

        if (key === "" && (bind.description || "").includes("Copilot Key")) {
            key = "Copilot"
        }
        if (key) parts.push(_prettifyKey(key))

        return parts
    }

    function _formatKey(bind) {
        return _makeKeyParts(bind).join(" + ")
    }

    function _prettifyKey(key) {
        const replacements = {
            "left": "←",
            "right": "→",
            "up": "↑",
            "down": "↓",

            "backspace": "Backspace",
            "return": "Enter",
            "escape": "Esc",

            "space": "Space",
            "period": ".",
            "slash": "/",
            "SLASH": "/",

            "backslash": "\\",

            "bracketleft": "[",
            "bracketright": "]",

            "tab": "Tab",
            "PRINT": "Print",

            "XF86Search": "Search",
            "XF86AudioRaiseVolume": "Volume +",
            "XF86AudioLowerVolume": "Volume -",
            "XF86AudioMute": "Mute",
            "XF86AudioMicMute": "Mic Mute",

            "XF86MonBrightnessUp": "Brightness +",
            "XF86MonBrightnessDown": "Brightness -",

            "XF86AudioPlay": "Play",
            "XF86AudioPause": "Pause",
            "XF86AudioNext": "Next",
            "XF86AudioPrev": "Previous"
        }

        if (replacements[key] !== undefined) return replacements[key]

        return key
    }

    function _categoryFor(bind) {
        const description = (bind.description || "").toLowerCase()

        // Workspaces
        if (
            description.startsWith("switch to workspace") ||
            description.startsWith("move window to workspace") ||
            description.startsWith("go to special workspace") ||
            description.startsWith("move window to special workspace") ||
            description.startsWith("scroll down to move to next workspace") ||
            description.startsWith("scroll up to move to previous workspace")
        ) {
            return "Workspaces"
        }

        // Window management
        if (
            description === "close window" ||
            description === "toggle fullscreen" ||
            description === "toggle floating window" ||
            description === "toggle pseudo tiling" ||
            description === "toggle split" ||
            description.startsWith("focus ") ||
            description.startsWith("left click and drag") ||
            description.startsWith("right click and drag")
        ) {
            return "Window Management"
        }

        // Media
        if (
            description.includes("volume") ||
            description.includes("mute") ||
            description.includes("brightness") ||
            description.includes("play / pause") ||
            description.includes("skip to next") ||
            description.includes("skip to previous")
        ) {
            return "Media"
        }

        // Screenshots
        if (
            description.includes("screenshot") ||
            description.includes("ocr")
        ) {
            return "Screenshots"
        }

        // System
        if (
            description.includes("quickshell") ||
            description.includes("wlogout") ||
            description.includes("top bar") ||
            description.includes("focus mode") ||
            description.includes("wallpaper picker") ||
            description.includes("keybinds viewer")
        ) {
            return "System"
        }

        return "Launchers"
    }

    function _buildSections(entries) {
        const result = []

        for (const category of root.categoryOrder) {
            const categoryEntries = entries.filter(entry => entry.category === category)

            if (categoryEntries.length === 0) continue
            if (category === "Workspaces") categoryEntries.sort(_workspaceSort)

            result.push({
                title: category,
                binds: categoryEntries
            })
        }

        return result
    }

    function _workspaceSort(a, b) {
        const aDescription = a.description
        const bDescription = b.description

        const aSwitch = aDescription.startsWith("Switch to workspace")
        const bSwitch = bDescription.startsWith("Switch to workspace")
        const aMove = aDescription.startsWith("Move window to workspace")
        const bMove = bDescription.startsWith("Move window to workspace")

        if (aSwitch !== bSwitch) return aSwitch ? -1 : 1
        if (aMove !== bMove) return aMove ? -1 : 1

        const aNumber = _workspaceNumber(aDescription)
        const bNumber = _workspaceNumber(bDescription)

        if (aNumber !== bNumber) return aNumber - bNumber

        return aDescription.localeCompare(bDescription)
    }

    function _workspaceNumber(description) {
        const match = description.match(/workspace\s+(\d+)/)

        if (match) return Number(match[1])

        return 999
    }

    Process {
        id: bindProc

        command: ["hyprctl", "-j", "binds"]
        property var _output: []

        stdout: SplitParser {
            onRead: (line) => {
                bindProc._output.push(line)
            }
        }

        stderr: SplitParser {
            onRead: (line) => {
                console.warn( "KeybindsService hyprctl:", line)
            }
        }

        onExited: {
            root._parseOutput()
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.popups.emoji

PanelWindow {
    id: root

    property var screen

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors { bottom: true; left: true }

    implicitWidth:  390
    implicitHeight: 520

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    visible: slide.windowVisible

    // ── Data ──────────────────────────────────────────────────────────────
    EmojiData { id: emojiData }

    // ── State ─────────────────────────────────────────────────────────────
    property int    activeCat:  0
    property string searchText: ""

    readonly property var currentEmojis: {
        if (searchText.length === 0)
            return emojiData.categories[activeCat].emojis

        const q = searchText.toLowerCase()
        let results = []
        for (const cat of emojiData.categories) {
            for (const e of cat.emojis) {
                if (cat.label.toLowerCase().includes(q))
                    results.push(e)
            }
        }
        return results
    }

    // ── Copy ──────────────────────────────────────────────────────────────
    Process {
        id: copyProc
        property string emoji: ""
        command: ["wl-copy", "--", emoji]
        running: false
    }

    function copyEmoji(emoji) {
        copyProc.emoji   = emoji
        copyProc.running = true
        Popups.emojiOpen = false
    }

    // ── Reset on open ─────────────────────────────────────────────────────
    Connections {
        target: Popups
        function onEmojiOpenChanged() {
            if (Popups.emojiOpen) {
                searchBar.clear()
                root.searchText = ""
                root.activeCat  = 0
                emojiGrid.resetIndex()
                searchBar.forceActiveFocus()
            }
        }
    }

    PopupSlide {
        id: slide

        anchors.fill: parent

        edge: "bottom"
        open: Popups.emojiOpen

        onCloseRequested: Popups.emojiOpen = false

        Rectangle {
            anchors {
                bottom:       parent.bottom
                left:         parent.left
                bottomMargin: 10
                leftMargin:   10
            }

            width:  380
            height: 440

            radius: Theme.popupRadius
            color:  Colors.surfaceContainer

            border.color: Colors.outlineVariant
            border.width: Theme.popupBorder

            clip: true

            ColumnLayout {
                anchors { fill: parent; margins: 14 }
                spacing: 10

                EmojiSearchBar {
                    id: searchBar
                    Layout.fillWidth: true

                    onTextChanged:   { root.searchText = text; emojiGrid.resetIndex() }
                    onEscapePressed: Popups.emojiOpen = false
                    onReturnPressed: root.copyEmoji(root.currentEmojis[0] ?? "")
                    onDownPressed:   emojiGrid.forceActiveFocus()
                    onUpPressed:     emojiGrid.forceActiveFocus()
                }

                EmojiCategoryBar {
                    id: catBar
                    Layout.fillWidth: true

                    categories:   emojiData.categories
                    activeIndex:  root.activeCat
                    searchActive: root.searchText.length > 0

                    onCategorySelected: (idx) => {
                        searchBar.clear()
                        root.searchText = ""
                        root.activeCat  = idx
                        emojiGrid.resetIndex()
                        emojiGrid.forceActiveFocus()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.outlineVariant
                    opacity: 0.5
                }

                EmojiGrid {
                    id: emojiGrid
                    Layout.fillWidth:  true
                    Layout.fillHeight: true

                    emojis: root.currentEmojis

                    onEmojiSelected: (emoji) => root.copyEmoji(emoji)
                    onTypedChar:     (ch)    => searchBar.forceActiveFocus()
                }
            }
        }
    }
}

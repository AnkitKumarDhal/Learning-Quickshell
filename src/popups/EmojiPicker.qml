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

    //property var screen

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors { bottom: true; left: true }

    implicitWidth:  390
    implicitHeight: 520

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Popups.emojiOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    visible: slide.windowVisible

    // ── Data ──────────────────────────────────────────────────────────────
    EmojiData { id: emojiData }
    EmojiSearchData { id: emojiSearchData }

    // ── State ─────────────────────────────────────────────────────────────
    property int    activeCat:  0
    property string searchText: ""

    readonly property var currentEmojis: {
        const q = searchText.trim().toLowerCase()

        if (!q)
            return emojiData.categories[activeCat].emojis

        const results = []

        for (const cat of emojiData.categories) {
            for (const emoji of cat.emojis) {
                const terms = emojiSearchData.terms[emoji]

                if (terms && terms.includes(q))
                    results.push(emoji)
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
                emojiGrid.forceActiveFocus()
            }
        }
    }

    Component.onCompleted: {
        if (Popups.emojiOpen) {
            searchBar.clear()
            root.searchText = ""
            root.activeCat = 0
            emojiGrid.resetIndex()
            emojiGrid.forceActiveFocus()
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
                    onTypedChar:     (ch)    => {
                        searchBar.forceActiveFocus()
                        searchBar.insertText(ch)
                    }
                }
            }
        }
    }
}

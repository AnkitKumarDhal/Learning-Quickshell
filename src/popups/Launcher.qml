import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects
import qs.src.theme
import qs.src.state
import qs.src.services
import qs.src.popups.launcher

PanelWindow {
    id: root

    required property var screen

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true; left: true; right: true; bottom: true }

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Popups.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool _shouldShow: false
    visible: _shouldShow

    property int selectedIndex: 0
    property var allApps: DesktopEntries.applications.values
    property var filteredApps: []

    property string mode: "apps"
    property string modeLabel: ""
    property string specialTitle: ""
    property string specialText: ""
    property string specialDetail: ""
    property bool specialValid: false
    property bool actionsOpen: false

    Connections {
        target: Popups

        function onLauncherOpenChanged() {
            if (Popups.launcherOpen) {
                closeDelay.stop()
                root._shouldShow = true
                launcherFocusTimer.start()
            } else {
                closeDelay.start()
            }
        }
    }

    Connections {
        target: LauncherConvertService
        function onCurrencyResultChanged() {
            if (root.mode === "currency") {
                root.updateSearch()
            }
        }
        function onCurrencyLoadingChanged() {
            if (root.mode === "currency") {
                root.updateSearch()
            }
        }
        function onCurrencyErrorChanged() {
            if (root.mode === "currency") {
                root.updateSearch()
            }
        }
    }

    Timer {
        id: closeDelay
        interval: Theme.animDuration + 30
        onTriggered: root._shouldShow = false
    }

    Timer {
        id: launcherFocusTimer
        interval: 80
        running: false
        repeat: false

        onTriggered: {
            if (!Popups.launcherOpen) return
            searchBar.clear()
            root.selectedIndex = 0
            root.updateSearch()
            searchBar.forceActiveFocus()
        }
    }

    Component.onCompleted: {
        LauncherService.refreshApps(root.allApps)
        root.updateSearch()

        if (Popups.launcherOpen) {
            closeDelay.stop()
            root._shouldShow = true
            launcherFocusTimer.start()
        }
    }

    function updateSearch() {
        const result = LauncherSearchService.search(root.allApps, searchBar.text, LauncherService.recentIds, LauncherService.pinnedIds)
        root.mode = result.mode || "apps"
        root.filteredApps = result.results || []
        root.modeLabel = root.mode === "google"
                            ? "Google"
                            : root.mode === "startpage"
                                ? "Startpage"
                                : root.mode === "web"
                                    ? "Web search"
                                    : root.mode === "calculator"
                                        ? "Calculator"
                                        : root.mode === "unit"
                                            ? "Unit conversion"
                                            : root.mode === "currency"
                                                ? "Currency"
                                                : root.mode === "command"
                                                    ? "Command"
                                                    : ""

        root.specialTitle  = result.title  || ""
        root.specialText   = result.text   || ""
        root.specialDetail = result.detail || ""
        root.specialValid  = result.valid  || false
        root.selectedIndex = 0
    }

    function launch(idx, focusExisting) {
        const app = root.filteredApps[idx]
        if (!app) return
        if (focusExisting) {
            if (LauncherService.focusExisting(app)) {
                return
            }
        }

        LauncherService.recordLaunch(app)
        app.execute()
        Popups.launcherOpen = false
    }

    function runSpecial() {
        const query = searchBar.text.trim()
        if (root.mode === "command") {
            const command = query.substring(1).trim()
            if (!command) return
            Quickshell.execDetached([
                "sh",
                "-c",
                command
            ])
            Popups.launcherOpen = false
            return
        }

        if (root.mode === "calculator" || root.mode === "unit" || root.mode === "currency") {
            if (root.specialValid) {
                Quickshell.clipboardText = root.specialTitle
            }
            return
        }

        if (root.mode === "web" || root.mode === "google" || root.mode === "startpage") {
            if (root.specialValid && LauncherSearchService.openWebSearch(query)) {
                Popups.launcherOpen = false
            }
        }
    }

    function toggleActions() {
        if (root.mode !== "apps" || root.filteredApps.length === 0) {
            return
        }
        root.actionsOpen = !root.actionsOpen

        if (root.actionsOpen) {
            actionMenu.appData = root.filteredApps[root.selectedIndex]
            actionMenu.selectedAction = 0
            actionMenu.forceActiveFocus()
        } else {
            searchBar.forceActiveFocus()
        }
    }

    function pinSelected() {
        if (root.mode !== "apps" || !root.filteredApps[root.selectedIndex]) {
            return
        }
        LauncherService.togglePin(root.filteredApps[root.selectedIndex])
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        opacity: Popups.launcherOpen ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animDuration
                easing.type: Easing.InOutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Popups.launcherOpen = false
        }
    }

    Rectangle {
        id: card

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(72, (parent.height - height) * 0.28)

        width: 620
        height: searchBar.height + topSectionHeight + contentArea.height + footer.height
        radius: Theme.popupRadius + 6

        color: Colors.surfaceContainer

        border.color: Colors.outlineVariant
        border.width: Theme.popupBorder

        clip: true

        property real yOffset: Popups.launcherOpen ? 0 : -18

        Behavior on yOffset {
            NumberAnimation {
                duration: Theme.animDuration
                easing.type: Easing.OutCubic
            }
        }

        transform: Translate { y: card.yOffset }
        opacity: Popups.launcherOpen ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animDuration
                easing.type: Easing.OutCubic
            }
        }

        readonly property int topSectionHeight: quickAccess.visible ? quickAccess.height + quickDivider.height : divider.height

        LauncherSearchBar {
            id: searchBar

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            resultCount: root.filteredApps.length
            showCount: root.mode === "apps"
            mode: root.mode
            modeLabel: root.modeLabel
            onTextChanged: root.updateSearch()
            onEscapePressed: {
                if (root.actionsOpen) {
                    root.actionsOpen = false
                } else {
                    Popups.launcherOpen = false
                }
            }

            onReturnPressed:
                (focusExisting) => {
                    if (root.actionsOpen) {
                        actionMenu.executeAction(actionMenu.selectedAction)
                    } else if (root.mode === "apps") {
                        root.launch(root.selectedIndex, focusExisting)
                    } else {
                        root.runSpecial()
                    }
                }

            onUpPressed: {
                if (root.actionsOpen) {
                    actionMenu.selectedAction = (actionMenu.selectedAction - 1 + actionMenu.actionCount) % actionMenu.actionCount
                    return
                }
                if (root.mode !== "apps" || root.filteredApps.length === 0) {
                    return
                }
                if (root.selectedIndex > 0) {
                    root.selectedIndex--
                    resultsList.positionAt(root.selectedIndex)
                }
            }

            onDownPressed: {
                if (root.actionsOpen) {
                    actionMenu.selectedAction = (actionMenu.selectedAction + 1) % actionMenu.actionCount
                    return
                }
                if (root.mode !== "apps" || root.filteredApps.length === 0) {
                    return
                }
                if (root.selectedIndex < root.filteredApps.length - 1) {
                    root.selectedIndex++
                    resultsList.positionAt(root.selectedIndex)
                }
            }

            onTabPressed: {
                if (root.actionsOpen) {
                    return
                }
                if (root.mode !== "apps" || root.filteredApps.length === 0) {
                    return
                }

                root.selectedIndex = (root.selectedIndex + 1) % Math.max(root.filteredApps.length, 1)
                resultsList.positionAt(root.selectedIndex)
            }

            onHomePressed: {
                if (root.mode !== "apps" || root.filteredApps.length === 0) {
                    return
                }
                root.selectedIndex = 0
                resultsList.positionAt(root.selectedIndex)
            }

            onEndPressed: {
                if (root.mode !== "apps" || root.filteredApps.length === 0) {
                    return
                }
                root.selectedIndex = root.filteredApps.length - 1
                resultsList.positionAt(root.selectedIndex)
            }

            onRightPressed: root.toggleActions()
            onLeftPressed: {
                if (root.actionsOpen) {
                    root.actionsOpen = false
                    searchBar.forceActiveFocus()
                }
            }

            onPinPressed: root.pinSelected()
        }

        Rectangle {
            id: divider
            visible: !quickAccess.visible
            anchors {
                top: searchBar.bottom
                left: parent.left
                right: parent.right
            }
            height: 1
            color: Colors.outlineVariant
            opacity: 0.5
        }

        LauncherQuickAccess {
            id: quickAccess
            anchors {
                top: searchBar.bottom
                left: parent.left
                right: parent.right
            }
            visible: root.mode === "apps" && searchBar.text.trim() === "" && (LauncherService.pinnedApps.length + LauncherService.recentApps.length) > 0
            pinnedApps: LauncherService.pinnedApps
            recentApps: LauncherService.recentApps
            onLaunched: (app) => {
                LauncherService.recordLaunch(app)
                app.execute()
                Popups.launcherOpen = false
            }
        }

        Rectangle {
            id: quickDivider

            visible: quickAccess.visible
            anchors {
                top: quickAccess.bottom
                left: parent.left
                right: parent.right
            }
            height: 1
            color: Colors.outlineVariant
            opacity: 0.5
        }

        Item {
            id: contentArea

            anchors {
                top: quickAccess.visible ? quickDivider.bottom : divider.bottom
                left: parent.left
                right: parent.right
            }

            height: root.actionsOpen
                    ? Math.max(180, actionMenu.actionCount * 46 + 54)
                    : root.mode === "apps"
                        ? resultsList.height
                        : 112

            LauncherResultsList {
                id: resultsList

                visible: root.mode === "apps" && !root.actionsOpen
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                filteredApps: root.filteredApps
                selectedIndex: root.selectedIndex
                searchText: searchBar.text
                onLaunched: (idx) => root.launch(idx, false)
                onSelectionChanged: (idx) => root.selectedIndex = idx
                layer.enabled: true

                layer.effect:
                    OpacityMask {
                        maskSource: Rectangle {
                                width: resultsList.width
                                height: resultsList.height
                                bottomLeftRadius: Theme.popupRadius + 6
                                bottomRightRadius: Theme.popupRadius + 6
                            }
                    }
            }

            LauncherActionsMenu {
                id: actionMenu

                visible: root.actionsOpen
                anchors.fill: parent
                appData: root.filteredApps.length > 0 ? root.filteredApps[root.selectedIndex] : null
                onCloseRequested: {
                    root.actionsOpen = false
                    searchBar.forceActiveFocus()
                }

                onFinished: {
                    root.actionsOpen = false
                    searchBar.forceActiveFocus()
                    root.updateSearch()
                }
            }

            Rectangle {
                anchors.fill: parent

                visible: root.mode !== "apps" && !root.actionsOpen
                color: "transparent"
                ColumnLayout {
                    anchors {
                        fill: parent
                        leftMargin: 20
                        rightMargin: 20
                        topMargin: 14
                        bottomMargin: 14
                    }

                    spacing: 4
                    Text {
                        Layout.fillWidth: true
                        text: root.specialTitle
                        color: Colors.on_Surface
                        font.pixelSize: 18
                        font.family: Fonts.fontM
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.specialText
                        color: Colors.on_SurfaceVariant
                        font.pixelSize: 12
                        font.family: Fonts.font
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        visible: root.specialDetail !== ""
                        Layout.fillWidth: true
                        text: root.specialDetail
                        color: Colors.on_SurfaceVariant
                        font.pixelSize: 11
                        font.family: Fonts.font
                        opacity: 0.65
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

        Item {
            id: footer

            anchors {
                top: contentArea.bottom
                left: parent.left
                right: parent.right
            }

            height: 34

            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                height: 1
                color: Colors.outlineVariant
                opacity: 0.5
            }

            Text {
                anchors.centerIn: parent
                text: root.actionsOpen
                        ? "↑↓ Navigate    ↵ Select    ← Back    Esc Close"
                        : root.mode !== "apps"
                            ? "↵ Run    Esc Close"
                            : "↑↓ Navigate    ↵ Launch    ⇧↵ Focus    → Actions    Ctrl+P Pin    Esc Close"

                color: Colors.on_SurfaceVariant
                font.pixelSize: 10
                font.family: Fonts.font
                opacity: 0.7
            }
        }
    }
}

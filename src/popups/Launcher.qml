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
            if (!Popups.launcherOpen)
                return

            searchBar.clear()
            root.selectedIndex = 0
            root.filterApps()
            searchBar.forceActiveFocus()
        }
    }

    property int selectedIndex: 0
    property var allApps: DesktopEntries.applications.values
    property var filteredApps: []

    property string _pendingQuery: ""
    property string mode: "apps"
    property string modeLabel: ""
    property string specialTitle: ""
    property string specialText: ""
    property string specialDetail: ""
    property bool specialValid: false
    property bool actionsOpen: false

    Connections {
        target: LauncherService

        function onCurrencyResultChanged() {
            if (root.mode === "currency")
                root.filterApps()
        }

        function onCurrencyLoadingChanged() {
            if (root.mode === "currency")
                root.filterApps()
        }
    }

    Component.onCompleted: {
        LauncherService.refreshApps(root.allApps)
        root.filterApps()

        if (Popups.launcherOpen) {
            closeDelay.stop()
            root._shouldShow = true
            launcherFocusTimer.start()
        }
    }

    function normalize(value) {
        return String(value || "")
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, " ")
            .trim()
    }

    function fuzzyScore(text, query) {
        if (!text || !query)
            return -1

        let score = 0
        let cursor = 0
        let previous = -1

        for (let i = 0; i < query.length; i++) {
            const index = text.indexOf(query.charAt(i), cursor)

            if (index === -1)
                return -1

            if (index === cursor)
                score += 35
            else
                score += 10

            if (index === 0 || text.charAt(index - 1) === " ")
                score += 18

            if (previous >= 0 && index === previous + 1)
                score += 20

            previous = index
            cursor = index + 1
        }

        return score - Math.max(0, text.length - query.length) * 0.1
    }

    function scoreApp(app, q) {
        const name = root.normalize(app.name)
        const generic = root.normalize(app.genericName)
        const comment = root.normalize(app.comment)
        const keywords = root.normalize((app.keywords || []).join(" "))
        const categories = root.normalize((app.categories || []).join(" "))

        if (!name && !generic && !comment && !keywords && !categories)
            return -1

        if (name === q)
            return 10000

        if (name.startsWith(q))
            return 9000 - Math.max(0, name.length - q.length)

        const nameWords = name.split(" ")

        for (let i = 0; i < nameWords.length; i++) {
            if (nameWords[i].startsWith(q))
                return 8200 - Math.max(0, nameWords[i].length - q.length)
        }

        if (name.includes(q))
            return 7300 - name.indexOf(q)

        if (generic === q)
            return 6800

        if (generic.startsWith(q))
            return 6400 - Math.max(0, generic.length - q.length)

        if (generic.includes(q))
            return 6000 - generic.indexOf(q)

        if (keywords.includes(q))
            return 5200 - keywords.indexOf(q)

        if (comment.includes(q))
            return 4200 - comment.indexOf(q)

        if (categories.includes(q))
            return 3000 - categories.indexOf(q)

        const fuzzy = root.fuzzyScore(name, q)

        if (fuzzy >= 0)
            return 2000 + fuzzy

        const genericFuzzy = root.fuzzyScore(generic, q)

        if (genericFuzzy >= 0)
            return 1200 + genericFuzzy

        return -1
    }

    function detectMode(q) {
        if (q.startsWith(">"))
            return "command"

        if (q.startsWith("?"))
            return "web"

        if (/^!g(?:\s|$)/i.test(q))
            return "google"

        if (/^!s(?:\s|$)/i.test(q))
            return "startpage"

        if (/^[-+]?\d+(?:\.\d+)?\s+[a-z]{3}\s+(?:in|to|\/|→)\s+[a-z]{3}$/i.test(q))
            return "currency"

        if (/^[-+]?\d+(?:\.\d+)?\s*[a-z°]+\s+(?:in|to|\/)\s*[a-z°]+$/i.test(q))
            return "unit"

        if (/\d/.test(q) &&
            /^[0-9+\-*/%^().,\sA-Za-z]+$/.test(q) &&
            (/[+*/%^()]/.test(q) ||
             /(^|[\s])-[0-9]/.test(q) ||
             /\b(sqrt|abs|round|floor|ceil)\s*\(/i.test(q)))
            return "calculator"

        return "apps"
    }

    function calculatorResult(expression) {
        let expr = String(expression || "")
            .replace(/,/g, "")
            .trim()

        if (!expr)
            return ""

        expr = expr
            .replace(/\bsqrt\s*\(/gi, "Math.sqrt(")
            .replace(/\babs\s*\(/gi, "Math.abs(")
            .replace(/\bround\s*\(/gi, "Math.round(")
            .replace(/\bfloor\s*\(/gi, "Math.floor(")
            .replace(/\bceil\s*\(/gi, "Math.ceil(")
            .replace(/\^/g, "**")

        if (!/^[0-9+\-*/%^.()\sA-Za-z]+$/.test(expr))
            return ""

        if (/[A-Za-z_]/.test(expr) &&
            !/^([0-9+\-*/%.()\s]|Math\.(sqrt|abs|round|floor|ceil))+$/.test(expr))
            return ""

        try {
            const value = Function(
                "\"use strict\"; return (" + expr + ")"
            )()

            if (!Number.isFinite(value))
                return ""

            return String(
                Number(value.toFixed(12))
            )
        } catch (error) {
            return ""
        }
    }

    function convertUnit(value, from, to) {
        const units = {
            mm: ["length", 0.001],
            cm: ["length", 0.01],
            m:  ["length", 1],
            km: ["length", 1000],
            in: ["length", 0.0254],
            ft: ["length", 0.3048],
            yd: ["length", 0.9144],
            mi: ["length", 1609.344],

            mg: ["mass", 0.000001],
            g:  ["mass", 0.001],
            kg: ["mass", 1],
            oz: ["mass", 0.028349523125],
            lb: ["mass", 0.45359237],

            b:  ["data", 1],
            kb: ["data", 1024],
            mb: ["data", 1024 * 1024],
            gb: ["data", 1024 * 1024 * 1024],
            tb: ["data", 1024 * 1024 * 1024 * 1024],

            s:   ["time", 1],
            min: ["time", 60],
            h:   ["time", 3600],
            d:   ["time", 86400]
        }

        const f = String(from).toLowerCase()
        const t = String(to).toLowerCase()

        if (f === "c" || f === "°c") {
            if (t === "f" || t === "°f")
                return value * 9 / 5 + 32

            if (t === "k")
                return value + 273.15
        }

        if (f === "f" || f === "°f") {
            if (t === "c" || t === "°c")
                return (value - 32) * 5 / 9

            if (t === "k")
                return (value - 32) * 5 / 9 + 273.15
        }

        if (f === "k") {
            if (t === "c" || t === "°c")
                return value - 273.15

            if (t === "f" || t === "°f")
                return (value - 273.15) * 9 / 5 + 32
        }

        if (!units[f] ||
            !units[t] ||
            units[f][0] !== units[t][0]) {
            return null
        }

        return value * units[f][1] / units[t][1]
    }

    function parseCurrency(q) {
        const match = q.match(
            /^([-+]?\d+(?:\.\d+)?)\s*([a-z]{3})\s+(?:in|to|\/|→)\s*([a-z]{3})$/i
        )

        if (!match)
            return null

        return {
            amount: match[1],
            from:   match[2].toUpperCase(),
            to:     match[3].toUpperCase()
        }
    }

    function parseUnit(q) {
        const match = q.match(
            /^([-+]?\d+(?:\.\d+)?)\s*([a-z°]+)\s+(?:in|to|\/)\s*([a-z°]+)$/i
        )

        if (!match)
            return null

        return {
            value: Number(match[1]),
            from:  match[2].toLowerCase(),
            to:    match[3].toLowerCase()
        }
    }

    function webQuery(q) {
        if (q.startsWith("!g"))
            return q.substring(2).trim()

        if (q.startsWith("!s"))
            return q.substring(2).trim()

        if (q.startsWith("?"))
            return q.substring(1).trim()

        return ""
    }

    function openWebSearch(q) {
        const query = root.webQuery(q)

        if (!query)
            return false

        let base = LauncherService.defaultSearchUrl

        if (q.toLowerCase().startsWith("!g"))
            base = "https://www.google.com/search?q="

        if (q.toLowerCase().startsWith("!s"))
            base = "https://www.startpage.com/sp/search?query="

        return Qt.openUrlExternally(
            base + encodeURIComponent(query)
        )
    }

    function filterApps() {
        const q = searchBar.text.toLowerCase().trim()

        root._pendingQuery = q
        root.mode = root.detectMode(q)
        root.actionsOpen = false

        root.specialTitle = ""
        root.specialText = ""
        root.specialDetail = ""
        root.specialValid = false
        root.modeLabel = ""

        if (root.mode === "apps") {
            LauncherService.refreshApps(root.allApps)

            const apps = []
            const seen = {}

            for (let i = 0; i < root.allApps.length; i++) {
                const app = root.allApps[i]
                const key = LauncherService.appKey(app)

                if (!key || app.noDisplay || seen[key])
                    continue

                seen[key] = true

                if (q === "") {
                    apps.push({
                        app:   app,
                        score: 0
                    })

                    continue
                }

                const score = root.scoreApp(app, q)

                if (score >= 0) {
                    apps.push({
                        app:   app,
                        score: score
                    })
                }
            }

            apps.sort((a, b) => {
                if (a.score !== b.score)
                    return b.score - a.score

                return (a.app.name || "").localeCompare(
                    b.app.name || ""
                )
            })

            root.filteredApps =
                apps.map(item => item.app)
        } else if (root.mode === "calculator") {
            const result =
                root.calculatorResult(q)

            root.modeLabel = "Calculator"

            root.specialTitle =
                result !== ""
                    ? result
                    : "Invalid expression"

            root.specialText =
                result !== ""
                    ? "Press Enter to copy the result"
                    : "Try something like 42 * 18 or sqrt(144)"

            root.specialDetail = ""
            root.specialValid = result !== ""
            root.filteredApps = []
        } else if (root.mode === "unit") {
            const unit = root.parseUnit(q)

            const result = unit
                ? root.convertUnit(
                    unit.value,
                    unit.from,
                    unit.to
                  )
                : null

            root.modeLabel =
                "Unit conversion"

            root.specialTitle =
                result === null ||
                !Number.isFinite(result)
                    ? "Invalid conversion"
                    : String(
                        Number(
                            result.toFixed(10)
                        )
                      ) + " " + unit.to

            root.specialText =
                result === null ||
                !Number.isFinite(result)
                    ? "Try 10 km to mi, 100 c to f, or 2 gb to mb"
                    : "Press Enter to copy the result"

            root.specialDetail = ""
            root.specialValid =
                result !== null &&
                Number.isFinite(result)

            root.filteredApps = []
        } else if (root.mode === "currency") {
            const currency =
                root.parseCurrency(q)

            root.modeLabel = "Currency"
            root.filteredApps = []

            if (!currency) {
                root.specialTitle =
                    "Invalid currency conversion"

                root.specialText =
                    "Try 100 USD to INR"

                root.specialDetail = ""
                root.specialValid = false
            } else {
                root.specialTitle =
                    LauncherService.currencyLoading
                        ? "Converting…"
                        : LauncherService.currencyError
                            ? "Unable to fetch exchange rate"
                            : LauncherService.currencyResult !== ""
                                ? LauncherService.currencyResult +
                                  " " +
                                  currency.to
                                : "Fetching exchange rate…"

                root.specialText =
                    LauncherService.currencyError
                        ? "Check your internet connection and try again"
                        : "Using a live exchange rate"

                root.specialDetail =
                    currency.amount +
                    " " +
                    currency.from +
                    " → " +
                    currency.to

                root.specialValid =
                    LauncherService.currencyResult !== ""

                const requestChanged =
                    LauncherService.currencyAmount !== currency.amount ||
                    LauncherService.currencyFrom !== currency.from ||
                    LauncherService.currencyTo !== currency.to

                if (!LauncherService.currencyLoading &&
                    requestChanged) {
                    LauncherService.convertCurrency(
                        currency.amount,
                        currency.from,
                        currency.to
                    )
                }
            }
        } else if (root.mode === "web" ||
                   root.mode === "google" ||
                   root.mode === "startpage") {
            const query = root.webQuery(q)

            root.modeLabel =
                root.mode === "google"
                    ? "Google"
                    : root.mode === "startpage"
                        ? "Startpage"
                        : "Web search"

            root.specialTitle =
                query !== ""
                    ? "Search for “" + query + "”"
                    : "Enter a search query"

            root.specialText =
                query !== ""
                    ? "Press Enter to open it in your browser"
                    : "Use ? for web search, !g for Google, or !s for Startpage"

            root.specialDetail = ""
            root.specialValid = query !== ""
            root.filteredApps = []
        } else {
            const command =
                q.substring(1).trim()

            root.modeLabel = "Command"

            root.specialTitle =
                command !== ""
                    ? command
                    : "Run a shell command"

            root.specialText =
                command !== ""
                    ? "Press Enter to execute it"
                    : "Type > followed by a command"

            root.specialDetail = ""
            root.specialValid =
                command !== ""

            root.filteredApps = []
        }

        root.selectedIndex = 0
    }

    function onSearchTextChanged() {
        root.filterApps()
    }

    function launch(idx, focusExisting) {
        const app = root.filteredApps[idx]

        if (!app)
            return

        if (focusExisting) {
            if (LauncherService.focusExisting(app)) {
                Popups.launcherOpen = false
                return
            }
        }

        LauncherService.recordLaunch(app)
        app.execute()

        Popups.launcherOpen = false
    }

    function runSpecial() {
        const q = searchBar.text.trim()

        if (root.mode === "command") {
            const command =
                q.substring(1).trim()

            if (!command)
                return

            Quickshell.execDetached([
                "sh",
                "-c",
                command
            ])

            Popups.launcherOpen = false
            return
        }

        if (root.mode === "calculator") {
            if (root.specialValid)
                Quickshell.clipboardText =
                    root.specialTitle

            return
        }

        if (root.mode === "unit") {
            if (root.specialValid)
                Quickshell.clipboardText =
                    root.specialTitle

            return
        }

        if (root.mode === "currency") {
            if (root.specialValid)
                Quickshell.clipboardText =
                    root.specialTitle

            return
        }

        if (root.mode === "web" ||
            root.mode === "google" ||
            root.mode === "startpage") {
            if (
                root.specialValid &&
                root.openWebSearch(q)
            ) {
                Popups.launcherOpen = false
            }
        }
    }

    function toggleActions() {
        if (
            root.mode !== "apps" ||
            root.filteredApps.length === 0
        ) {
            return
        }

        root.actionsOpen =
            !root.actionsOpen

        if (root.actionsOpen) {
            actionMenu.appData =
                root.filteredApps[
                    root.selectedIndex
                ]

            actionMenu.selectedAction = 0
            actionMenu.forceActiveFocus()
        } else {
            searchBar.forceActiveFocus()
        }
    }

    function pinSelected() {
        if (
            root.mode !== "apps" ||
            !root.filteredApps[
                root.selectedIndex
            ]
        ) {
            return
        }

        LauncherService.togglePin(
            root.filteredApps[
                root.selectedIndex
            ]
        )
    }

    Rectangle {
        anchors.fill: parent

        color:
            Qt.rgba(
                0,
                0,
                0,
                0.55
            )

        opacity:
            Popups.launcherOpen
                ? 1
                : 0

        Behavior on opacity {
            NumberAnimation {
                duration:
                    Theme.animDuration

                easing.type:
                    Easing.InOutCubic
            }
        }

        MouseArea {
            anchors.fill: parent

            onClicked:
                Popups.launcherOpen = false
        }
    }

    Rectangle {
        id: card

        anchors.horizontalCenter:
            parent.horizontalCenter

        anchors.top:
            parent.top

        anchors.topMargin:
            Math.max(
                72,
                (parent.height - height) * 0.28
            )

        width:  620

        height:
            searchBar.height +
            topSectionHeight +
            contentArea.height +
            footer.height

        radius:
            Theme.popupRadius + 6

        color:
            Colors.surfaceContainer

        border.color:
            Colors.outlineVariant

        border.width:
            Theme.popupBorder

        clip:
            true

        property real yOffset:
            Popups.launcherOpen
                ? 0
                : -18

        Behavior on yOffset {
            NumberAnimation {
                duration:
                    Theme.animDuration

                easing.type:
                    Easing.OutCubic
            }
        }

        transform: Translate {
            y: card.yOffset
        }

        opacity:
            Popups.launcherOpen
                ? 1
                : 0

        Behavior on opacity {
            NumberAnimation {
                duration:
                    Theme.animDuration

                easing.type:
                    Easing.OutCubic
            }
        }

        readonly property int topSectionHeight:
            quickAccess.visible
                ? quickAccess.height +
                  quickDivider.height
                : divider.height

        LauncherSearchBar {
            id: searchBar

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            resultCount:
                root.filteredApps.length

            showCount:
                root.mode === "apps"

            mode:
                root.mode

            modeLabel:
                root.modeLabel

            onTextChanged:
                root.onSearchTextChanged()

            onEscapePressed: {
                if (root.actionsOpen)
                    root.actionsOpen = false
                else
                    Popups.launcherOpen = false
            }

            onReturnPressed:
                (focusExisting) => {
                    if (root.actionsOpen) {
                        actionMenu.executeAction(
                            actionMenu.selectedAction
                        )
                    } else if (
                        root.mode === "apps"
                    ) {
                        root.launch(
                            root.selectedIndex,
                            focusExisting
                        )
                    } else {
                        root.runSpecial()
                    }
                }

            onUpPressed: {
                if (root.actionsOpen) {
                    actionMenu.selectedAction =
                        (
                            actionMenu.selectedAction -
                            1 +
                            actionMenu.actionCount
                        ) %
                        actionMenu.actionCount

                    return
                }

                if (
                    root.mode !== "apps" ||
                    root.filteredApps.length === 0
                ) {
                    return
                }

                if (root.selectedIndex > 0) {
                    root.selectedIndex--

                    resultsList.positionAt(
                        root.selectedIndex
                    )
                }
            }

            onDownPressed: {
                if (root.actionsOpen) {
                    actionMenu.selectedAction =
                        (
                            actionMenu.selectedAction +
                            1
                        ) %
                        actionMenu.actionCount

                    return
                }

                if (
                    root.mode !== "apps" ||
                    root.filteredApps.length === 0
                ) {
                    return
                }

                if (
                    root.selectedIndex <
                    root.filteredApps.length - 1
                ) {
                    root.selectedIndex++

                    resultsList.positionAt(
                        root.selectedIndex
                    )
                }
            }

            onTabPressed: {
                if (root.actionsOpen)
                    return

                if (
                    root.mode !== "apps" ||
                    root.filteredApps.length === 0
                ) {
                    return
                }

                root.selectedIndex =
                    (
                        root.selectedIndex + 1
                    ) %
                    Math.max(
                        root.filteredApps.length,
                        1
                    )

                resultsList.positionAt(
                    root.selectedIndex
                )
            }

            onHomePressed: {
                if (
                    root.mode !== "apps" ||
                    root.filteredApps.length === 0
                ) {
                    return
                }

                root.selectedIndex = 0

                resultsList.positionAt(
                    root.selectedIndex
                )
            }

            onEndPressed: {
                if (
                    root.mode !== "apps" ||
                    root.filteredApps.length === 0
                ) {
                    return
                }

                root.selectedIndex =
                    root.filteredApps.length - 1

                resultsList.positionAt(
                    root.selectedIndex
                )
            }

            onRightPressed:
                root.toggleActions()

            onLeftPressed: {
                if (root.actionsOpen) {
                    root.actionsOpen = false
                    searchBar.forceActiveFocus()
                }
            }

            onPinPressed:
                root.pinSelected()
        }

        Rectangle {
            id: divider

            visible:
                !quickAccess.visible

            anchors {
                top: searchBar.bottom
                left: parent.left
                right: parent.right
            }

            height: 1

            color:
                Colors.outlineVariant

            opacity:
                0.5
        }

        LauncherQuickAccess {
            id: quickAccess

            anchors {
                top: searchBar.bottom
                left: parent.left
                right: parent.right
            }

            visible:
                root.mode === "apps" &&
                searchBar.text.trim() === "" &&
                (
                    LauncherService.pinnedApps.length +
                    LauncherService.recentApps.length
                ) > 0

            pinnedApps:
                LauncherService.pinnedApps

            recentApps:
                LauncherService.recentApps

            onLaunched: (app) => {
                LauncherService.recordLaunch(app)
                app.execute()
                Popups.launcherOpen = false
            }
        }

        Rectangle {
            id: quickDivider

            visible:
                quickAccess.visible

            anchors {
                top: quickAccess.bottom
                left: parent.left
                right: parent.right
            }

            height: 1

            color:
                Colors.outlineVariant

            opacity:
                0.5
        }

        Item {
            id: contentArea

            anchors {
                top:
                    quickAccess.visible
                        ? quickDivider.bottom
                        : divider.bottom

                left: parent.left
                right: parent.right
            }

            height:
                root.actionsOpen
                    ? 180
                    : root.mode === "apps"
                        ? resultsList.height
                        : 112

            LauncherResultsList {
                id: resultsList

                visible:
                    root.mode === "apps" &&
                    !root.actionsOpen

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                filteredApps:
                    root.filteredApps

                selectedIndex:
                    root.selectedIndex

                searchText:
                    searchBar.text

                onLaunched:
                    (idx) =>
                        root.launch(
                            idx,
                            false
                        )

                onSelectionChanged:
                    (idx) =>
                        root.selectedIndex = idx

                layer.enabled:
                    true

                layer.effect:
                    OpacityMask {
                        maskSource:
                            Rectangle {
                                width:
                                    resultsList.width

                                height:
                                    resultsList.height

                                bottomLeftRadius:
                                    Theme.popupRadius + 6

                                bottomRightRadius:
                                    Theme.popupRadius + 6
                            }
                    }
            }

            LauncherActionsMenu {
                id: actionMenu

                visible:
                    root.actionsOpen

                anchors.fill:
                    parent

                appData:
                    root.filteredApps.length > 0
                        ? root.filteredApps[
                            root.selectedIndex
                          ]
                        : null

                onCloseRequested: {
                    root.actionsOpen = false
                    searchBar.forceActiveFocus()
                }

                onFinished: {
                    root.actionsOpen = false
                    searchBar.forceActiveFocus()
                    root.filterApps()
                }
            }

            Rectangle {
                anchors.fill: parent

                visible:
                    root.mode !== "apps" &&
                    !root.actionsOpen

                color:
                    "transparent"

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

                        text:
                            root.specialTitle

                        color:
                            Colors.on_Surface

                        font.pixelSize: 18
                        font.family: Fonts.fontM
                        font.weight: Font.Medium

                        horizontalAlignment:
                            Text.AlignHCenter

                        elide:
                            Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true

                        text:
                            root.specialText

                        color:
                            Colors.on_SurfaceVariant

                        font.pixelSize: 12
                        font.family: Fonts.font

                        horizontalAlignment:
                            Text.AlignHCenter

                        wrapMode:
                            Text.WordWrap
                    }

                    Text {
                        visible:
                            root.specialDetail !== ""

                        Layout.fillWidth: true

                        text:
                            root.specialDetail

                        color:
                            Colors.on_SurfaceVariant

                        font.pixelSize: 11
                        font.family: Fonts.font

                        opacity:
                            0.65

                        horizontalAlignment:
                            Text.AlignHCenter
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

                color:
                    Colors.outlineVariant

                opacity:
                    0.5
            }

            Text {
                anchors.centerIn:
                    parent

                text:
                    root.actionsOpen
                        ? "↑↓ Navigate    ↵ Select    ← Back    Esc Close"
                        : root.mode !== "apps"
                            ? "↵ Run    Esc Close"
                            : "↑↓ Navigate    ↵ Launch    ⇧↵ Focus    → Actions    Ctrl+P Pin    Esc Close"

                color:
                    Colors.on_SurfaceVariant

                font.pixelSize: 10
                font.family:     Fonts.font

                opacity: 0.7
            }
        }
    }
}

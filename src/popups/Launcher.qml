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

        const compactText =
            text.replace(/\s+/g, "")

        const compactQuery =
            query.replace(/\s+/g, "")

        let score = 0
        let cursor = 0
        let previous = -1
        let firstMatch = -1
        let matched = 0

        for (
            let i = 0;
            i < compactQuery.length;
            i++
        ) {
            const character =
                compactQuery.charAt(i)

            const index =
                compactText.indexOf(
                    character,
                    cursor
                )

            if (index === -1)
                return -1

            if (firstMatch === -1)
                firstMatch = index

            matched++

            if (index === cursor)
                score += 45
            else
                score += 8

            if (
                previous >= 0 &&
                index === previous + 1
            ) {
                score += 30
            }

            previous = index
            cursor = index + 1
        }

        const coverage =
            matched /
            Math.max(
                compactText.length,
                1
            )

        score += coverage * 60

        if (firstMatch === 0)
            score += 70

        return score
    }

    function acronymScore(text, query) {
        if (!text || !query)
            return -1

        const words =
            text
                .split(/\s+/)
                .filter(word => word !== "")

        if (words.length < 2)
            return -1

        const acronym =
            words
                .map(word => word.charAt(0))
                .join("")

        if (acronym === query)
            return 7000

        if (acronym.startsWith(query))
            return 6000 - (
                acronym.length -
                query.length
            ) * 10

        return -1
    }

    function scoreText(
        text,
        q,
        exactScore,
        prefixScore,
        containsScore,
        fuzzyBase
    ) {
        const normalized =
            root.normalize(text)

        if (!normalized)
            return -1

        if (normalized === q)
            return exactScore

        if (normalized.startsWith(q))
            return prefixScore -
                Math.max(
                    0,
                    normalized.length -
                    q.length
                )

        const words =
            normalized.split(" ")

        for (
            let i = 0;
            i < words.length;
            i++
        ) {
            if (
                words[i] === q
            ) {
                return prefixScore + 80
            }

            if (
                words[i].startsWith(q)
            ) {
                return prefixScore - 80
            }
        }

        if (normalized.includes(q))
            return containsScore -
                normalized.indexOf(q)

        const acronym =
            root.acronymScore(
                normalized,
                q
            )

        if (acronym >= 0)
            return acronym

        const fuzzy =
            root.fuzzyScore(
                normalized,
                q
            )

        if (fuzzy >= 0)
            return fuzzyBase + fuzzy

        return -1
    }

    function scoreApp(app, q) {
        const nameScore =
            root.scoreText(
                app.name,
                q,
                10000,
                9000,
                7300,
                2400
            )

        if (nameScore >= 0)
            return nameScore

        const genericScore =
            root.scoreText(
                app.genericName,
                q,
                6800,
                6400,
                6000,
                1500
            )

        if (genericScore >= 0)
            return genericScore

        const keywords =
            root.normalize(
                (app.keywords || [])
                    .join(" ")
            )

        if (
            keywords === q
        ) {
            return 5500
        }

        if (
            keywords.startsWith(q)
        ) {
            return 5300
        }

        if (
            keywords.includes(q)
        ) {
            return 5100
        }

        const commentScore =
            root.scoreText(
                app.comment,
                q,
                4500,
                4300,
                4100,
                900
            )

        if (commentScore >= 0)
            return commentScore

        const categoryScore =
            root.scoreText(
                (app.categories || [])
                    .join(" "),
                q,
                3100,
                3000,
                2900,
                500
            )

        if (categoryScore >= 0)
            return categoryScore

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

        if (
            root.parseUnit(q) !== null
        ) {
            return "unit"
        }

        if (
            /^[-+]?\d+(?:\.\d+)?\s+[a-z]{3}\s+(?:in|to|\/|→)\s+[a-z]{3}$/i.test(q)
        ) {
            return "currency"
        }

        if (
            /\d/.test(q) &&
            /^[0-9+\-*/%^().,\sA-Za-z]+$/.test(q)
        ) {
            return "calculator"
        }

        return "apps"
    }

    function calculatorFunction(name) {
        switch (name.toLowerCase()) {
        case "sqrt":
            return "Math.sqrt"
        case "abs":
            return "Math.abs"
        case "round":
            return "Math.round"
        case "floor":
            return "Math.floor"
        case "ceil":
            return "Math.ceil"
        case "sin":
            return "(Math.sin"
        case "cos":
            return "(Math.cos"
        case "tan":
            return "(Math.tan"
        case "asin":
            return "(Math.asin"
        case "acos":
            return "(Math.acos"
        case "atan":
            return "(Math.atan"
        case "log":
            return "Math.log10"
        case "ln":
            return "Math.log"
        case "exp":
            return "Math.exp"
        default:
            return ""
        }
    }

    function calculatorResult(expression) {
        let expr =
            String(expression || "")
                .replace(/,/g, "")
                .trim()

        if (!expr)
            return ""

        expr = expr
            .replace(/\bpi\b/gi, "PI")
            .replace(/\be\b/g, "E")
            .replace(/\^/g, "**")
            .replace(
                /(-?\d+(?:\.\d+)?)%/g,
                "($1/100)"
            )

        if (
            !/^[0-9+\-*/%.()\sA-Za-z]+$/.test(expr)
        ) {
            return ""
        }

        const allowedNames = [
            "sqrt",
            "abs",
            "round",
            "floor",
            "ceil",
            "sin",
            "cos",
            "tan",
            "asin",
            "acos",
            "atan",
            "log",
            "ln",
            "exp",
            "PI",
            "E"
        ]

        const identifiers =
            expr.match(
                /[A-Za-z_][A-Za-z0-9_]*/g
            ) || []

        for (
            let i = 0;
            i < identifiers.length;
            i++
        ) {
            if (
                allowedNames.indexOf(
                    identifiers[i]
                ) === -1
            ) {
                return ""
            }
        }

        try {
            const sin =
                value =>
                    Math.sin(
                        value * Math.PI / 180
                    )

            const cos =
                value =>
                    Math.cos(
                        value * Math.PI / 180
                    )

            const tan =
                value =>
                    Math.tan(
                        value * Math.PI / 180
                    )

            const asin =
                value =>
                    Math.asin(value) *
                    180 / Math.PI

            const acos =
                value =>
                    Math.acos(value) *
                    180 / Math.PI

            const atan =
                value =>
                    Math.atan(value) *
                    180 / Math.PI

            const sqrt =
                value =>
                    Math.sqrt(value)

            const abs =
                value =>
                    Math.abs(value)

            const round =
                value =>
                    Math.round(value)

            const floor =
                value =>
                    Math.floor(value)

            const ceil =
                value =>
                    Math.ceil(value)

            const log =
                value =>
                    Math.log10(value)

            const ln =
                value =>
                    Math.log(value)

            const exp =
                value =>
                    Math.exp(value)

            const value =
                Function(
                    "sqrt",
                    "abs",
                    "round",
                    "floor",
                    "ceil",
                    "sin",
                    "cos",
                    "tan",
                    "asin",
                    "acos",
                    "atan",
                    "log",
                    "ln",
                    "exp",
                    "PI",
                    "E",
                    "\"use strict\"; return (" +
                        expr +
                        ")"
                )(
                    sqrt,
                    abs,
                    round,
                    floor,
                    ceil,
                    sin,
                    cos,
                    tan,
                    asin,
                    acos,
                    atan,
                    log,
                    ln,
                    exp,
                    Math.PI,
                    Math.E
                )

            if (!Number.isFinite(value))
                return ""

            if (
                Math.abs(value) >
                Number.MAX_SAFE_INTEGER
            ) {
                return ""
            }

            return String(
                Number(
                    value.toFixed(12)
                )
            )
        } catch (error) {
            return ""
        }
    }

    function convertUnit(
        value,
        from,
        to
    ) {
        const units = {
            mm:     ["length", 0.001],
            cm:     ["length", 0.01],
            m:      ["length", 1],
            km:     ["length", 1000],
            in:     ["length", 0.0254],
            ft:     ["length", 0.3048],
            yd:     ["length", 0.9144],
            mi:     ["length", 1609.344],

            mg:     ["mass", 0.000001],
            g:      ["mass", 0.001],
            kg:     ["mass", 1],
            oz:     ["mass", 0.028349523125],
            lb:     ["mass", 0.45359237],

            b:      ["data", 1],
            kb:     ["data", 1024],
            mb:     ["data", 1024 * 1024],
            gb:     ["data", 1024 * 1024 * 1024],
            tb:     ["data", 1024 * 1024 * 1024 * 1024],

            ms:     ["time", 0.001],
            s:      ["time", 1],
            min:    ["time", 60],
            h:      ["time", 3600],
            d:      ["time", 86400],

            mps:    ["speed", 1],
            kmh:    ["speed", 1000 / 3600],
            mph:    ["speed", 1609.344 / 3600],
            knot:   ["speed", 1852 / 3600],

            mm2:    ["area", 0.000001],
            cm2:    ["area", 0.0001],
            m2:     ["area", 1],
            km2:    ["area", 1000000],
            in2:    ["area", 0.00064516],
            ft2:    ["area", 0.09290304],
            yd2:    ["area", 0.83612736],
            mi2:    ["area", 2589988.110336],
            acre:   ["area", 4046.8564224],
            hectare:["area", 10000],

            ml:     ["volume", 0.001],
            l:      ["volume", 1],
            tsp:    ["volume", 0.00492892159],
            tbsp:   ["volume", 0.0147867648],
            cup:    ["volume", 0.2365882365],
            pt:     ["volume", 0.473176473],
            qt:     ["volume", 0.946352946],
            gal:    ["volume", 3.785411784],

            pa:     ["pressure", 1],
            kpa:    ["pressure", 1000],
            mpa:    ["pressure", 1000000],
            bar:    ["pressure", 100000],
            psi:    ["pressure", 6894.757293168],
            atm:    ["pressure", 101325],

            j:      ["energy", 1],
            kj:     ["energy", 1000],
            mj:     ["energy", 1000000],
            cal:    ["energy", 4.184],
            kcal:   ["energy", 4184],
            wh:     ["energy", 3600],
            kwh:    ["energy", 3600000],

            hz:     ["frequency", 1],
            khz:    ["frequency", 1000],
            mhz:    ["frequency", 1000000],
            ghz:    ["frequency", 1000000000]
        }

        const f =
            String(from)
                .toLowerCase()

        const t =
            String(to)
                .toLowerCase()

        if (
            (f === "c" || f === "°c") &&
            (t === "f" || t === "°f")
        ) {
            return value * 9 / 5 + 32
        }

        if (
            (f === "c" || f === "°c") &&
            t === "k"
        ) {
            return value + 273.15
        }

        if (
            (f === "f" || f === "°f") &&
            (t === "c" || t === "°c")
        ) {
            return (value - 32) * 5 / 9
        }

        if (
            (f === "f" || f === "°f") &&
            t === "k"
        ) {
            return (
                (value - 32) * 5 / 9
            ) + 273.15
        }

        if (
            f === "k" &&
            (t === "c" || t === "°c")
        ) {
            return value - 273.15
        }

        if (
            f === "k" &&
            (t === "f" || t === "°f")
        ) {
            return (
                (value - 273.15) * 9 / 5
            ) + 32
        }

        if (
            !units[f] ||
            !units[t] ||
            units[f][0] !== units[t][0]
        ) {
            return null
        }

        return (
            value *
            units[f][1] /
            units[t][1]
        )
    }

    function parseCurrency(q) {
        const match =
            q.match(
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
        const match =
            q.match(
                /^([-+]?\d+(?:\.\d+)?)\s*([a-z0-9²³./]+)\s+(?:in|to|\/)\s*([a-z0-9²³./]+)$/i
            )

        if (!match)
            return null

        const from =
            match[2]
                .toLowerCase()
                .replace(/²/g, "2")
                .replace(/³/g, "3")

        const to =
            match[3]
                .toLowerCase()
                .replace(/²/g, "2")
                .replace(/³/g, "3")

        const knownUnits = [
            "mm",
            "cm",
            "m",
            "km",
            "in",
            "ft",
            "yd",
            "mi",

            "mg",
            "g",
            "kg",
            "oz",
            "lb",

            "b",
            "kb",
            "mb",
            "gb",
            "tb",

            "ms",
            "s",
            "min",
            "h",
            "d",

            "mps",
            "kmh",
            "mph",
            "knot",

            "mm2",
            "cm2",
            "m2",
            "km2",
            "in2",
            "ft2",
            "yd2",
            "mi2",
            "acre",
            "hectare",

            "ml",
            "l",
            "tsp",
            "tbsp",
            "cup",
            "pt",
            "qt",
            "gal",

            "pa",
            "kpa",
            "mpa",
            "bar",
            "psi",
            "atm",

            "j",
            "kj",
            "mj",
            "cal",
            "kcal",
            "wh",
            "kwh",

            "hz",
            "khz",
            "mhz",
            "ghz",

            "c",
            "°c",
            "f",
            "°f",
            "k"
        ]

        if (
            knownUnits.indexOf(from) === -1 ||
            knownUnits.indexOf(to) === -1
        ) {
            return null
        }

        return {
            value: Number(match[1]),
            from:  from,
            to:    to
        }
    }

    function webQuery(q) {
        if (
            q.toLowerCase()
                .startsWith("!g")
        ) {
            return q.substring(2).trim()
        }

        if (
            q.toLowerCase()
                .startsWith("!s")
        ) {
            return q.substring(2).trim()
        }

        if (q.startsWith("?"))
            return q.substring(1).trim()

        return ""
    }

    function openWebSearch(q) {
        const query =
            root.webQuery(q)

        if (!query)
            return false

        let base =
            LauncherService.defaultSearchUrl

        if (
            q.toLowerCase()
                .startsWith("!g")
        ) {
            base =
                "https://www.google.com/search?q="
        }

        if (
            q.toLowerCase()
                .startsWith("!s")
        ) {
            base =
                "https://www.startpage.com/sp/search?query="
        }

        return Qt.openUrlExternally(
            base +
            encodeURIComponent(query)
        )
    }

    function filterApps() {
        const q =
            searchBar.text
                .toLowerCase()
                .trim()

        root._pendingQuery = q
        root.mode =
            root.detectMode(q)

        root.actionsOpen = false

        root.specialTitle = ""
        root.specialText = ""
        root.specialDetail = ""
        root.specialValid = false
        root.modeLabel = ""

        if (root.mode === "apps") {
            LauncherService.refreshApps(
                root.allApps
            )

            const apps = []
            const seen = {}

            for (
                let i = 0;
                i < root.allApps.length;
                i++
            ) {
                const app =
                    root.allApps[i]

                const key =
                    LauncherService.appKey(
                        app
                    )

                if (
                    !key ||
                    app.noDisplay ||
                    seen[key]
                ) {
                    continue
                }

                seen[key] = true

                if (q === "") {
                    apps.push({
                        app:   app,
                        score: 0
                    })

                    continue
                }

                const score =
                    root.scoreApp(
                        app,
                        q
                    )

                if (score >= 0) {
                    apps.push({
                        app:   app,
                        score: score
                    })
                }
            }

            apps.sort((a, b) => {
                if (
                    a.score !==
                    b.score
                ) {
                    return (
                        b.score -
                        a.score
                    )
                }

                return (
                    a.app.name || ""
                ).localeCompare(
                    b.app.name || ""
                )
            })

            root.filteredApps =
                apps.map(
                    item => item.app
                )
        } else if (
            root.mode === "calculator"
        ) {
            const result =
                root.calculatorResult(q)

            root.modeLabel =
                "Calculator"

            root.specialTitle =
                result !== ""
                    ? result
                    : "Invalid expression"

            root.specialText =
                result !== ""
                    ? "Press Enter to copy the result"
                    : "Try pi * 10, sqrt(144), sin(30), or 2^10"

            root.specialDetail = ""

            root.specialValid =
                result !== ""

            root.filteredApps = []
        } else if (
            root.mode === "unit"
        ) {
            const unit =
                root.parseUnit(q)

            const result =
                unit
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
                      ) +
                      " " +
                      unit.to

            root.specialText =
                result === null ||
                !Number.isFinite(result)
                    ? "Try 10 km to mi, 100 kmh to mph, or 2 gb to mb"
                    : "Press Enter to copy the result"

            root.specialDetail = ""
            root.specialValid =
                result !== null &&
                Number.isFinite(result)

            root.filteredApps = []
        } else if (
            root.mode === "currency"
        ) {
            const currency =
                root.parseCurrency(q)

            root.modeLabel =
                "Currency"

            root.filteredApps = []

            if (!currency) {
                root.specialTitle =
                    "Invalid currency conversion"

                root.specialText =
                    "Try 100 USD to INR"

                root.specialDetail = ""
                root.specialValid =
                    false
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
                        : "Using a live or cached exchange rate"

                root.specialDetail =
                    currency.amount +
                    " " +
                    currency.from +
                    " → " +
                    currency.to

                root.specialValid =
                    LauncherService.currencyResult !== ""

                const requestChanged =
                    LauncherService.currencyAmount !==
                        currency.amount ||
                    LauncherService.currencyFrom !==
                        currency.from ||
                    LauncherService.currencyTo !==
                        currency.to

                if (
                    !LauncherService.currencyLoading &&
                    requestChanged
                ) {
                    LauncherService.convertCurrency(
                        currency.amount,
                        currency.from,
                        currency.to
                    )
                }
            }
        } else if (
            root.mode === "web" ||
            root.mode === "google" ||
            root.mode === "startpage"
        ) {
            const query =
                root.webQuery(q)

            root.modeLabel =
                root.mode === "google"
                    ? "Google"
                    : root.mode === "startpage"
                        ? "Startpage"
                        : "Web search"

            root.specialTitle =
                query !== ""
                    ? "Search for “" +
                      query +
                      "”"
                    : "Enter a search query"

            root.specialText =
                query !== ""
                    ? "Press Enter to open it in your browser"
                    : "Use ? for web search, !g for Google, or !s for Startpage"

            root.specialDetail = ""
            root.specialValid =
                query !== ""

            root.filteredApps = []
        } else {
            const command =
                q.substring(1).trim()

            root.modeLabel =
                "Command"

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

    function launch(
        idx,
        focusExisting
    ) {
        const app =
            root.filteredApps[idx]

        if (!app)
            return

        if (focusExisting) {
            if (
                LauncherService.focusExisting(
                    app
                )
            ) {
                return
            }
        }

        LauncherService.recordLaunch(app)

        app.execute()

        Popups.launcherOpen = false
    }

    function runSpecial() {
        const q =
            searchBar.text.trim()

        if (
            root.mode === "command"
        ) {
            const command =
                q.substring(1).trim()

            if (!command)
                return

            Quickshell.execDetached([
                "sh",
                "-c",
                command
            ])

            Popups.launcherOpen =
                false

            return
        }

        if (
            root.mode === "calculator" ||
            root.mode === "unit" ||
            root.mode === "currency"
        ) {
            if (root.specialValid) {
                Quickshell.clipboardText =
                    root.specialTitle
            }

            return
        }

        if (
            root.mode === "web" ||
            root.mode === "google" ||
            root.mode === "startpage"
        ) {
            if (
                root.specialValid &&
                root.openWebSearch(q)
            ) {
                Popups.launcherOpen =
                    false
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

            actionMenu.selectedAction =
                0

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
                Popups.launcherOpen =
                    false
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
                    Popups.launcherOpen =
                        false
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

                if (
                    root.selectedIndex > 0
                ) {
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
                        root.selectedIndex +
                        1
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

                root.selectedIndex =
                    0

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

            height:
                1

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

            height:
                1

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
                    ? Math.max(
                        180,
                        actionMenu.actionCount *
                        46 +
                        54
                    )
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
                        root.selectedIndex =
                            idx

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

                    spacing:
                        4

                    Text {
                        Layout.fillWidth:
                            true

                        text:
                            root.specialTitle

                        color:
                            Colors.on_Surface

                        font.pixelSize:
                            18

                        font.family:
                            Fonts.fontM

                        font.weight:
                            Font.Medium

                        horizontalAlignment:
                            Text.AlignHCenter

                        elide:
                            Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth:
                            true

                        text:
                            root.specialText

                        color:
                            Colors.on_SurfaceVariant

                        font.pixelSize:
                            12

                        font.family:
                            Fonts.font

                        horizontalAlignment:
                            Text.AlignHCenter

                        wrapMode:
                            Text.WordWrap
                    }

                    Text {
                        visible:
                            root.specialDetail !== ""

                        Layout.fillWidth:
                            true

                        text:
                            root.specialDetail

                        color:
                            Colors.on_SurfaceVariant

                        font.pixelSize:
                            11

                        font.family:
                            Fonts.font

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

            height:
                34

            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                height:
                    1

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

                font.pixelSize:
                    10

                font.family:
                    Fonts.font

                opacity:
                    0.7
            }
        }
    }
}

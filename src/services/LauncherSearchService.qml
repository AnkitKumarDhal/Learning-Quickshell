pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string defaultSearchUrl:
        Quickshell.env("LAUNCHER_SEARCH_URL") ||
        "https://www.google.com/search?q="

    function normalize(value) {
        return String(value || "")
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, " ")
            .trim()
    }

    function appKey(app) {
        if (!app)
            return ""

        if (app.id)
            return app.id

        return (
            app.name || ""
        ) + "|" + (
            app.command || []
        ).join("\u0001")
    }

    function fuzzyScore(text, query) {
        if (!text || !query)
            return -1

        const compactText =
            text.replace(/\s+/g, "")

        const compactQuery =
            query.replace(/\s+/g, "")

        if (!compactQuery)
            return -1

        let score = 0
        let cursor = 0
        let previous = -1
        let firstMatch = -1

        for (
            let i = 0;
            i < compactQuery.length;
            i++
        ) {
            const index =
                compactText.indexOf(
                    compactQuery.charAt(i),
                    cursor
                )

            if (index === -1)
                return -1

            if (firstMatch === -1)
                firstMatch = index

            if (index === cursor)
                score += 45
            else
                score += 8

            if (
                previous >= 0 &&
                index === previous + 1
            ) {
                score += 35
            }

            if (
                index === 0 ||
                compactText.charAt(index - 1) === " "
            ) {
                score += 20
            }

            previous = index
            cursor = index + 1
        }

        score += (
            compactQuery.length /
            Math.max(
                compactText.length,
                1
            )
        ) * 80

        if (firstMatch === 0)
            score += 75

        return score
    }

    function acronymScore(text, query) {
        if (!text || !query)
            return -1

        const words =
            text
                .split(/\s+/)
                .filter(
                    word =>
                        word !== ""
                )

        if (words.length < 2)
            return -1

        const acronym =
            words
                .map(
                    word =>
                        word.charAt(0)
                )
                .join("")

        if (acronym === query)
            return 7200

        if (
            acronym.startsWith(query)
        ) {
            return 6100 - (
                acronym.length -
                query.length
            ) * 10
        }

        return -1
    }

    function scoreText(
        text,
        query,
        exactScore,
        prefixScore,
        containsScore,
        fuzzyBase
    ) {
        const normalized =
            root.normalize(text)

        if (!normalized)
            return -1

        if (normalized === query)
            return exactScore

        if (
            normalized.startsWith(query)
        ) {
            return prefixScore -
                Math.max(
                    0,
                    normalized.length -
                    query.length
                )
        }

        const words =
            normalized.split(" ")

        for (
            let i = 0;
            i < words.length;
            i++
        ) {
            if (
                words[i] === query
            ) {
                return prefixScore + 120
            }

            if (
                words[i].startsWith(query)
            ) {
                return prefixScore - 80
            }
        }

        if (
            normalized.includes(query)
        ) {
            return containsScore -
                normalized.indexOf(query)
        }

        const acronym =
            root.acronymScore(
                normalized,
                query
            )

        if (acronym >= 0)
            return acronym

        const fuzzy =
            root.fuzzyScore(
                normalized,
                query
            )

        if (fuzzy >= 0)
            return fuzzyBase + fuzzy

        return -1
    }

    function scoreApp(
        app,
        query,
        recentKeys,
        pinnedKeys
    ) {
        let score =
            root.scoreText(
                app.name,
                query,
                10000,
                9000,
                7300,
                2500
            )

        if (score < 0) {
            score =
                root.scoreText(
                    app.genericName,
                    query,
                    6900,
                    6500,
                    6050,
                    1650
                )
        }

        if (score < 0) {
            const keywords =
                root.normalize(
                    (app.keywords || [])
                        .join(" ")
                )

            if (
                keywords === query
            ) {
                score = 5600
            } else if (
                keywords.startsWith(query)
            ) {
                score = 5350
            } else if (
                keywords.includes(query)
            ) {
                score = 5100
            }
        }

        if (score < 0) {
            score =
                root.scoreText(
                    app.comment,
                    query,
                    4600,
                    4350,
                    4100,
                    950
                )
        }

        if (score < 0) {
            score =
                root.scoreText(
                    (
                        app.categories ||
                        []
                    ).join(" "),
                    query,
                    3200,
                    3050,
                    2900,
                    550
                )
        }

        if (score < 0)
            return -1

        const key =
            root.appKey(app)

        if (
            pinnedKeys.indexOf(key) !== -1
        ) {
            score += 100
        }

        const recentIndex =
            recentKeys.indexOf(key)

        if (recentIndex !== -1) {
            score += Math.max(
                0,
                250 -
                recentIndex * 10
            )
        }

        return score
    }

    function calculate(expression) {
        let expr =
            String(expression || "")
                .replace(/,/g, "")
                .trim()

        if (!expr)
            return ""

        expr = expr
            .replace(
                /\^/g,
                "**"
            )
            .replace(
                /\bpi\b/gi,
                "PI"
            )
            .replace(
                /\be\b/g,
                "E"
            )
            .replace(
                /(-?\d+(?:\.\d+)?)%/g,
                "($1/100)"
            )

        if (
            !/^[0-9+\-*/%^.()\s,A-Za-z]+$/.test(
                expr
            )
        ) {
            return ""
        }

        const allowed = [
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
            "min",
            "max",
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
                allowed.indexOf(
                    identifiers[i]
                ) === -1
            ) {
                return ""
            }
        }

        function sin(value) {
            return Math.sin(
                value *
                Math.PI /
                180
            )
        }

        function cos(value) {
            return Math.cos(
                value *
                Math.PI /
                180
            )
        }

        function tan(value) {
            return Math.tan(
                value *
                Math.PI /
                180
            )
        }

        function asin(value) {
            return Math.asin(value) *
                180 /
                Math.PI
        }

        function acos(value) {
            return Math.acos(value) *
                180 /
                Math.PI
        }

        function atan(value) {
            return Math.atan(value) *
                180 /
                Math.PI
        }

        try {
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
                    "min",
                    "max",
                    "PI",
                    "E",
                    "\"use strict\"; return (" +
                    expr +
                    ")"
                )(
                    Math.sqrt,
                    Math.abs,
                    Math.round,
                    Math.floor,
                    Math.ceil,
                    sin,
                    cos,
                    tan,
                    asin,
                    acos,
                    atan,
                    Math.log10,
                    Math.log,
                    Math.exp,
                    Math.min,
                    Math.max,
                    Math.PI,
                    Math.E
                )

            if (
                !Number.isFinite(value)
            ) {
                return ""
            }

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

    function detectMode(query) {
        if (
            query.startsWith(">")
        ) {
            return "command"
        }

        if (
            query.startsWith("?")
        ) {
            return "web"
        }

        if (
            /^!g(?:\s|$)/i.test(query)
        ) {
            return "google"
        }

        if (
            /^!s(?:\s|$)/i.test(query)
        ) {
            return "startpage"
        }

        if (
            LauncherConvertService.parseUnit(
                query
            )
        ) {
            return "unit"
        }

        if (
            /^[-+]?\d+(?:\.\d+)?\s+[a-z]{3}\s+(?:in|to|\/|→)\s+[a-z]{3}$/i.test(
                query
            )
        ) {
            return "currency"
        }

        if (
            /\d/.test(query) &&
            /^[0-9+\-*/%^().,\sA-Za-z]+$/.test(
                query
            )
        ) {
            return "calculator"
        }

        if (
            /^(?:pi|e)$/i.test(query)
        ) {
            return "calculator"
        }

        return "apps"
    }

    function webQuery(query) {
        if (
            /^!g/i.test(query)
        ) {
            return query
                .substring(2)
                .trim()
        }

        if (
            /^!s/i.test(query)
        ) {
            return query
                .substring(2)
                .trim()
        }

        if (
            query.startsWith("?")
        ) {
            return query
                .substring(1)
                .trim()
        }

        return ""
    }

    function openWebSearch(query) {
        const value =
            root.webQuery(query)

        if (!value)
            return false

        let base =
            root.defaultSearchUrl

        if (
            /^!g/i.test(query)
        ) {
            base =
                "https://www.google.com/search?q="
        }

        if (
            /^!s/i.test(query)
        ) {
            base =
                "https://www.startpage.com/sp/search?query="
        }

        return Qt.openUrlExternally(
            base +
            encodeURIComponent(value)
        )
    }

    function search(
        apps,
        query,
        recentKeys,
        pinnedKeys
    ) {
        const raw =
            String(query || "")
                .trim()

        const normalized =
            root.normalize(raw)

        const mode =
            root.detectMode(
                normalized
            )

        if (
            mode === "calculator"
        ) {
            const result =
                root.calculate(raw)

            return {
                mode: mode,
                results: [],
                title:
                    result !== ""
                        ? result
                        : "Invalid expression",
                text:
                    result !== ""
                        ? "Press Enter to copy the result"
                        : "Try pi * 10, sqrt(144), sin(30), or 2^10",
                detail: "",
                valid:
                    result !== ""
            }
        }

        if (
            mode === "unit"
        ) {
            const parsed =
                LauncherConvertService.parseUnit(
                    raw
                )

            const result =
                LauncherConvertService.convertUnit(
                    raw
                )

            return {
                mode: mode,
                results: [],
                title:
                    result !== null &&
                    Number.isFinite(result)
                        ? String(
                            Number(
                                result.toFixed(10)
                            )
                          ) +
                          " " +
                          parsed.to
                        : "Invalid conversion",
                text:
                    result !== null &&
                    Number.isFinite(result)
                        ? "Press Enter to copy the result"
                        : "Try 10 km to mi, 100 kmh to mph, or 2 gb to mb",
                detail:
                    parsed
                        ? parsed.value +
                          " " +
                          parsed.from +
                          " → " +
                          parsed.to
                        : "",
                valid:
                    result !== null &&
                    Number.isFinite(result)
            }
        }

        if (
            mode === "currency"
        ) {
            const parsed =
                LauncherConvertService.parseCurrency(
                    raw
                )

            if (!parsed) {
                return {
                    mode: mode,
                    results: [],
                    title:
                        "Invalid currency conversion",
                    text:
                        "Try 100 USD to INR",
                    detail: "",
                    valid: false
                }
            }

            if (
                !LauncherConvertService.currencyLoading &&
                !(
                    LauncherConvertService.currencyFrom === parsed.from &&
                    LauncherConvertService.currencyTo === parsed.to &&
                    LauncherConvertService.currencyAmount === String(parsed.amount) &&
                    LauncherConvertService.currencyResult !== ""
                )
            ) {
                LauncherConvertService.convertCurrency(
                    parsed.amount,
                    parsed.from,
                    parsed.to
                )
            }

            return {
                mode: mode,
                results: [],
                title:
                    LauncherConvertService.currencyLoading
                        ? "Converting…"
                        : LauncherConvertService.currencyError
                            ? "Unable to fetch exchange rate"
                            : LauncherConvertService.currencyResult !== ""
                                ? LauncherConvertService.currencyResult +
                                  " " +
                                  parsed.to
                                : "Fetching exchange rate…",
                text:
                    LauncherConvertService.currencyError
                        ? "Check your internet connection and try again"
                        : "Using a live or cached exchange rate",
                detail:
                    parsed.amount +
                    " " +
                    parsed.from +
                    " → " +
                    parsed.to,
                valid:
                    LauncherConvertService.currencyResult !== ""
            }
        }

        if (
            mode === "web" ||
            mode === "google" ||
            mode === "startpage"
        ) {
            const value =
                root.webQuery(raw)

            return {
                mode: mode,
                results: [],
                title:
                    value !== ""
                        ? "Search for “" +
                          value +
                          "”"
                        : "Enter a search query",
                text:
                    value !== ""
                        ? "Press Enter to open it in your browser"
                        : "Use ? for web search, !g for Google, or !s for Startpage",
                detail: "",
                valid:
                    value !== ""
            }
        }

        if (
            mode === "command"
        ) {
            const command =
                raw.substring(1)
                    .trim()

            return {
                mode: mode,
                results: [],
                title:
                    command !== ""
                        ? command
                        : "Run a shell command",
                text:
                    command !== ""
                        ? "Press Enter to execute it"
                        : "Type > followed by a command",
                detail: "",
                valid:
                    command !== ""
            }
        }

        const results = []
        const seen = {}

        const recent =
            Array.isArray(recentKeys)
                ? recentKeys
                : []

        const pinned =
            Array.isArray(pinnedKeys)
                ? pinnedKeys
                : []

        for (
            let i = 0;
            i < apps.length;
            i++
        ) {
            const app =
                apps[i]

            const key =
                root.appKey(app)

            if (
                !key ||
                app.noDisplay ||
                seen[key]
            ) {
                continue
            }

            seen[key] = true

            if (
                normalized === ""
            ) {
                results.push({
                    app: app,
                    score: 0
                })

                continue
            }

            const score =
                root.scoreApp(
                    app,
                    normalized,
                    recent,
                    pinned
                )

            if (score >= 0) {
                results.push({
                    app: app,
                    score: score
                })
            }
        }

        results.sort((a, b) => {
            if (
                a.score !== b.score
            ) {
                return b.score -
                    a.score
            }

            return (
                a.app.name || ""
            ).localeCompare(
                b.app.name || ""
            )
        })

        return {
            mode: "apps",

            results:
                results.map(
                    item => item.app
                ),

            title: "",
            text: "",
            detail: "",
            valid: false
        }
    }
}

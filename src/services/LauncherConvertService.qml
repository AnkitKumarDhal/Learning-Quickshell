pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool currencyLoading: false
    property string currencyResult: ""
    property bool currencyError: false
    property string currencyFrom: ""
    property string currencyTo: ""
    property string currencyAmount: ""
    property string currencyDate: ""

    property var currencyCache: ({})

    readonly property int currencyCacheLifetime: 30 * 60 * 1000
    readonly property string currencyCachePath: Quickshell.statePath("launcher-currency.json")

    function normalizeUnit(value) {
        const unit = String(value || "")
                .toLowerCase()
                .trim()
                .replace(/²/g, "2")
                .replace(/³/g, "3")
                .replace(/[\s_-]+/g, "")

        const aliases = {
            millimeter:          "mm",
            millimeters:         "mm",
            centimeter:          "cm",
            centimeters:         "cm",
            meter:               "m",
            meters:              "m",
            kilometer:           "km",
            kilometers:          "km",
            inch:                "in",
            inches:              "in",
            foot:                "ft",
            feet:                "ft",
            yard:                "yd",
            yards:               "yd",
            mile:                "mi",
            miles:               "mi",

            milligram:           "mg",
            milligrams:          "mg",
            gram:                "g",
            grams:               "g",
            kilogram:            "kg",
            kilograms:           "kg",
            ounce:               "oz",
            ounces:              "oz",
            pound:               "lb",
            pounds:              "lb",

            byte:                "b",
            bytes:               "b",
            kib:                 "kb",
            mib:                 "mb",
            gib:                 "gb",
            tib:                 "tb",

            millisecond:         "ms",
            milliseconds:        "ms",
            second:              "s",
            seconds:             "s",
            minute:              "min",
            minutes:             "min",
            hour:                "h",
            hours:               "h",
            day:                 "d",
            days:                "d",

            "m/s":               "mps",
            "km/h":              "kmh",
            kph:                 "kmh",
            kilometerperhour:    "kmh",
            kilometersperhour:   "kmh",
            mileperhour:         "mph",
            milesperhour:        "mph",
            knot:                "knot",
            knots:               "knot",

            squaremillimeter:    "mm2",
            squaremillimeters:   "mm2",
            squarecentimeter:    "cm2",
            squarecentimeters:   "cm2",
            squaremeter:         "m2",
            squaremeters:        "m2",
            squarekilometer:     "km2",
            squarekilometers:   "km2",
            squareinch:          "in2",
            squareinches:        "in2",
            squarefoot:          "ft2",
            squarefeet:          "ft2",
            squareyard:          "yd2",
            squareyards:         "yd2",
            squaremile:          "mi2",
            squaremiles:         "mi2",

            acre:                "acre",
            acres:               "acre",
            hectare:             "hectare",
            hectares:            "hectare",

            milliliter:          "ml",
            milliliters:         "ml",
            liter:               "l",
            liters:              "l",
            litre:               "l",
            litres:              "l",
            teaspoon:            "tsp",
            teaspoons:           "tsp",
            tablespoon:          "tbsp",
            tablespoons:         "tbsp",
            cup:                 "cup",
            cups:                "cup",
            pint:                "pt",
            pints:               "pt",
            quart:               "qt",
            quarts:              "qt",
            gallon:              "gal",
            gallons:             "gal",

            pascal:              "pa",
            pascals:             "pa",
            kilopascal:          "kpa",
            kilopascals:         "kpa",
            megapascal:          "mpa",
            megapascals:         "mpa",
            bar:                 "bar",
            bars:                "bar",
            psi:                 "psi",
            atm:                 "atm",
            atmosphere:          "atm",
            atmospheres:         "atm",

            joule:               "j",
            joules:              "j",
            kilojoule:           "kj",
            kilojoules:          "kj",
            megajoule:           "mj",
            megajoules:          "mj",
            calorie:             "cal",
            calories:            "cal",
            kilocalorie:         "kcal",
            kilocalories:        "kcal",
            watthour:            "wh",
            watthours:           "wh",
            kilowatthour:        "kwh",
            kilowatthours:       "kwh",

            hertz:               "hz",
            kilohertz:           "khz",
            megahertz:           "mhz",
            gigahertz:           "ghz",

            celsius:             "c",
            "°c":                "c",
            centigrade:          "c",

            fahrenheit:          "f",
            "°f":                "f",

            kelvin:              "k"
        }

        return aliases[unit] || unit
    }

    function unitTable() {
        return {
            mm:       ["length",    0.001],
            cm:       ["length",    0.01],
            m:        ["length",    1],
            km:       ["length",    1000],
            in:       ["length",    0.0254],
            ft:       ["length",    0.3048],
            yd:       ["length",    0.9144],
            mi:       ["length",    1609.344],

            mg:       ["mass",      0.000001],
            g:        ["mass",      0.001],
            kg:       ["mass",      1],
            oz:       ["mass",      0.028349523125],
            lb:       ["mass",      0.45359237],

            b:        ["data",      1],
            kb:       ["data",      1024],
            mb:       ["data",      1024 * 1024],
            gb:       ["data",      1024 * 1024 * 1024],
            tb:       ["data",      1024 * 1024 * 1024 * 1024],

            ms:       ["time",      0.001],
            s:        ["time",      1],
            min:      ["time",      60],
            h:        ["time",      3600],
            d:        ["time",      86400],

            mps:      ["speed",     1],
            kmh:      ["speed",     1000 / 3600],
            mph:      ["speed",     1609.344 / 3600],
            knot:     ["speed",     1852 / 3600],

            mm2:      ["area",      0.000001],
            cm2:      ["area",      0.0001],
            m2:       ["area",      1],
            km2:      ["area",      1000000],
            in2:      ["area",      0.00064516],
            ft2:      ["area",      0.09290304],
            yd2:      ["area",      0.83612736],
            mi2:      ["area",      2589988.110336],
            acre:     ["area",      4046.8564224],
            hectare:  ["area",      10000],

            ml:       ["volume",    0.001],
            l:        ["volume",    1],
            tsp:      ["volume",    0.00492892159],
            tbsp:     ["volume",    0.0147867648],
            cup:      ["volume",    0.2365882365],
            pt:       ["volume",    0.473176473],
            qt:       ["volume",    0.946352946],
            gal:      ["volume",    3.785411784],

            pa:       ["pressure",  1],
            kpa:      ["pressure",  1000],
            mpa:      ["pressure",  1000000],
            bar:      ["pressure",  100000],
            psi:      ["pressure",  6894.757293168],
            atm:      ["pressure",  101325],

            j:        ["energy",    1],
            kj:       ["energy",    1000],
            mj:       ["energy",    1000000],
            cal:      ["energy",    4.184],
            kcal:     ["energy",    4184],
            wh:       ["energy",    3600],
            kwh:      ["energy",    3600000],

            hz:       ["frequency", 1],
            khz:      ["frequency", 1000],
            mhz:      ["frequency", 1000000],
            ghz:      ["frequency", 1000000000]
        }
    }

    function parseUnit(query) {
        const match = String(query || "")
                .trim()
                .match(/^([-+]?\d+(?:\.\d+)?)\s+(.+?)\s+(?:in|to|\/)\s+(.+)$/i)

        if (!match) return null
        const value = Number(match[1])
        const from = root.normalizeUnit(match[2])
        const to = root.normalizeUnit(match[3])

        if (!Number.isFinite(value)) {
            return null
        }

        const units = root.unitTable()
        const temperatureUnits = ["c", "f", "k"]
        const fromIsTemperature = temperatureUnits.indexOf(from) !== -1
        const toIsTemperature = temperatureUnits.indexOf(to) !== -1
        if (fromIsTemperature && toIsTemperature) {
            return {
                value: value,
                from:  from,
                to:    to
            }
        }

        if (fromIsTemperature || toIsTemperature) {
            return null
        }
        if (!units[from] || !units[to]) {
            return null
        }
        if (units[from][0] !== units[to][0]) {
            return null
        }

        return {
            value: value,
            from:  from,
            to:    to
        }
    }

    function convertUnit(query) {
        const parsed = root.parseUnit(query)
        if (!parsed) return null

        const value = parsed.value
        const from = parsed.from
        const to = parsed.to

        if (from === to) return value
        if (from === "c" && to === "f") {
            return (value * 9 / 5) + 32
        }
        if (from === "c" && to === "k") {
            return value + 273.15
        }
        if (from === "f" && to === "c") {
            return (value - 32) * 5 / 9
        }
        if (from === "f" && to === "k") {
            return ((value - 32) * 5 / 9) + 273.15
        }
        if (from === "k" && to === "c") {
            return value - 273.15
        }
        if (from === "k" && to === "f") {
            return ((value - 273.15) * 9 / 5) + 32
        }

        const units = root.unitTable()
        if ( !units[from] || !units[to] || units[from][0] !== units[to][0]) {
            return null
        }

        return (value * units[from][1] / units[to][1])
    }

    function parseCurrency(query) {
        const match = String(query || "")
                .trim()
                .match(/^([-+]?\d+(?:\.\d+)?)\s*([a-z]{3})\s+(?:in|to|\/|→)\s*([a-z]{3})$/i)

        if (!match) return null

        return {
            amount: Number(match[1]),
            from: match[2].toUpperCase(),
            to: match[3].toUpperCase()
        }
    }

    function currencyPairKey(from, to) {
        return (String(from).toUpperCase() + "|" + String(to).toUpperCase())
    }

    function formatCurrencyResult(amount, rate) {
        const value = Number(amount) * Number(rate)
        return String(Number(value.toFixed(4)))
    }

    function setCurrencyResult(amount, from, to, rate, date) {
        root.currencyAmount = String(amount)
        root.currencyFrom = from
        root.currencyTo = to
        root.currencyDate = date || ""
        root.currencyResult = root.formatCurrencyResult(amount, rate)
        root.currencyError = false
        root.currencyLoading = false
    }

    function convertCurrency(amount, fromCurrency, toCurrency) {
        const amountNumber = Number(amount)
        const from = String(fromCurrency || "").toUpperCase()
        const to = String(toCurrency || "").toUpperCase()

        if (!Number.isFinite(amountNumber) || !/^[A-Z]{3}$/.test(from) || !/^[A-Z]{3}$/.test(to)) {
            return false
        }

        root.currencyAmount = String(amountNumber)
        root.currencyFrom = from
        root.currencyTo = to
        root.currencyError = false

        if (from === to) {
            root.setCurrencyResult(amountNumber, from, to, 1, "")
            return true
        }

        const key = root.currencyPairKey(from, to)
        const cached = root.currencyCache[key]

        if (cached && cached.rate !== undefined && cached.timestamp !== undefined && Date.now() - Number(cached.timestamp) < root.currencyCacheLifetime) {
            root.setCurrencyResult(amountNumber, from, to, cached.rate, cached.date || "")
            return true
        }

        if (currencyProcess.running) {
            if (currencyProcess.fromCurrency === from && currencyProcess.toCurrency === to) {
                return true
            }
            return false
        }

        root.currencyResult = ""
        root.currencyLoading = true
        currencyProcess.fromCurrency = from
        currencyProcess.toCurrency = to
        currencyProcess.amount = amountNumber
        currencyProcess.pairKey = key
        currencyProcess.lines = []
        currencyProcess.command = [
            "curl",
            "-fsS",
            "--max-time",
            "6",
            "https://api.frankfurter.dev/v2/rate/" +
            encodeURIComponent(from) +
            "/" +
            encodeURIComponent(to)
        ]
        currencyProcess.running = true

        return true
    }

    function saveCurrencyCache() {
        currencyCacheFile.setText(JSON.stringify(root.currencyCache))
    }

    FileView {
        id: currencyCacheFile

        path: root.currencyCachePath
        preload: true
        watchChanges: false
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(currencyCacheFile.text())
                root.currencyCache = data && typeof data === "object" ? data : {}
            } catch (error) {
                root.currencyCache = {}
            }
        }

        onLoadFailed: root.currencyCache = {}
    }

    Process {
        id: currencyProcess

        property string fromCurrency: ""
        property string toCurrency: ""
        property string pairKey: ""
        property real amount: 0

        property var lines: []

        stdout: SplitParser {
            onRead: (line) => {
                const text = line.trim()
                if (text !== "") {
                    currencyProcess.lines.push(text)
                }
            }
        }

        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            let success = false
            if (exitCode === 0 && currencyProcess.lines.length > 0) {
                try {
                    const data = JSON.parse(currencyProcess.lines.join(""))
                    const rate = Number(data.rate)

                    if (Number.isFinite(rate)) {
                        root.currencyCache[currencyProcess.pairKey] = {rate: rate, timestamp: Date.now(), date: data.date || "" }
                        root.setCurrencyResult(
                            currencyProcess.amount,
                            currencyProcess.fromCurrency,
                            currencyProcess.toCurrency,
                            rate,
                            data.date || ""
                        )
                        root.saveCurrencyCache()
                        success = true
                    }
                } catch (error) {
                    success = false
                }
            }

            if (!success) {
                root.currencyResult = ""
                root.currencyError = true
                root.currencyLoading = false
            }

            currencyProcess.lines = []
        }
    }
}

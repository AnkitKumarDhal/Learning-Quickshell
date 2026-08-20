import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.src.components
import qs.src.theme

PillBase {
    id: root

    property var window

    // ------------------------------------------------------------
    // Tray state
    // ------------------------------------------------------------

    property bool collapsed: true

    property int iconSize: 20
    property int iconSpacing: 8
    property int toggleWidth: 28

    readonly property int trayCount:
        SystemTray.items.values.length

    /*
     * Number of pinned icons allowed to remain visible while collapsed.
     *
     * Change this to 1, 2, 3, etc.
     */
    property int collapsedVisibleItems: 2

    /*
     * Items that should remain visible while the tray is collapsed.
     *
     * Matching is case-insensitive and checks:
     *   - SystemTrayItem.id
     *   - title
     *   - tooltipTitle
     *   - tooltipDescription
     *
     * You don't need the exact value. A partial string is enough.
     *
     * Examples:
     *   "kde connect"
     *   "discord"
     *   "heroic"
     *   "music presence"
     */
    property list<string> pinnedItems: [
        "kde connect",
        "vesktop",
        "heroic",
        "music presence"
    ]

    /*
     * Returns whether a tray item matches one of the configured pinned
     * identifiers.
     */
    function isPinned(item) {
        if (!item || root.pinnedItems.length === 0)
            return false

        const candidates = [
            item.id,
            item.title,
            item.tooltipTitle,
            item.tooltipDescription
        ]

        for (let p = 0; p < root.pinnedItems.length; ++p) {
            const needle =
                String(root.pinnedItems[p])
                    .trim()
                    .toLowerCase()

            if (needle.length === 0)
                continue

            for (let c = 0; c < candidates.length; ++c) {
                const value =
                    String(candidates[c] || "")
                        .toLowerCase()

                if (
                    value.length > 0 &&
                    value.includes(needle)
                ) {
                    return true
                }
            }
        }

        return false
    }

    /*
     * Build the list shown while collapsed.
     *
     * We preserve the actual tray order rather than rearranging applications
     * according to the pin list.
     */
    readonly property var collapsedItems: {
        const all = SystemTray.items.values
        const result = []

        for (let i = 0; i < all.length; ++i) {
            if (root.isPinned(all[i])) {
                result.push(all[i])

                if (
                    result.length >=
                    root.collapsedVisibleItems
                ) {
                    break
                }
            }
        }

        return result
    }

    readonly property var overflowItems: {
        const all = SystemTray.items.values
        const pinned = root.collapsedItems
        const result = []

        for (let i = 0; i < all.length; ++i) {
            if (pinned.indexOf(all[i]) === -1)
                result.push(all[i])
        }

        return result
    }

    readonly property int collapsedItemCount:
        root.collapsedItems.length

    readonly property int hiddenTrayCount:
        root.overflowItems.length

    hoverExpand: false
    hoverEnabled: false
    mouseEnabled: false

    visible:
        trayCount > 0

    function toggleCollapsed() {
        collapsed = !collapsed
    }

    RowLayout {
        id: trayLayout

        spacing:
            root.iconSpacing

        // --------------------------------------------------------
        // Expand / collapse button
        // --------------------------------------------------------

        Item {
            id: toggleArea

            Layout.preferredWidth:
                root.toggleWidth

            Layout.preferredHeight:
                24

            Layout.alignment:
                Qt.AlignVCenter

            Rectangle {
                anchors.fill:
                    parent

                radius:
                    8

                color:
                    toggleMouse.containsMouse
                        ? Colors.primaryContainer
                        : "transparent"

                opacity:
                    toggleMouse.containsMouse
                        ? 1
                        : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration:
                            Theme.hoverFadeDuration

                        easing.type:
                            Easing.OutCubic
                    }
                }
            }

            Text {
                anchors.centerIn:
                    parent

                text:
                    root.collapsed
                        ? "<"
                        : ">"

                color:
                    Colors.primary

                font.family:
                    Fonts.font

                font.pixelSize:
                    16

                font.bold:
                    true
            }

            /*
             * Only count items that are actually hidden.
             *
             * Previously this showed the total number of tray items even
             * when some icons were visible while collapsed.
             */
            Rectangle {
                visible:
                    root.collapsed &&
                    root.hiddenTrayCount > 0

                anchors.right:
                    parent.right

                anchors.rightMargin:
                    -1

                anchors.bottom:
                    parent.bottom

                anchors.bottomMargin:
                    -4

                width:
                    root.hiddenTrayCount > 9
                        ? 18
                        : 14

                height:
                    12

                radius:
                    6

                color:
                    Colors.primary

                Text {
                    anchors.fill:
                        parent

                    text:
                        root.hiddenTrayCount > 9
                            ? "9+"
                            : String(
                                root.hiddenTrayCount
                            )

                    color:
                        Colors.on_Primary

                    font.family:
                        Fonts.font

                    font.pixelSize:
                        8

                    font.bold:
                        true

                    horizontalAlignment:
                        Text.AlignHCenter

                    verticalAlignment:
                        Text.AlignVCenter
                }
            }

            MouseArea {
                id: toggleMouse

                anchors.fill:
                    parent

                hoverEnabled:
                    true

                cursorShape:
                    Qt.PointingHandCursor

                onClicked:
                    root.toggleCollapsed()
            }
        }

    // ------------------------------------------------------------
// Tray icons
// ------------------------------------------------------------

RowLayout {
    id: iconContainer

    Layout.preferredHeight: 24

    spacing:
        root.iconSpacing

    // --------------------------------------------------------
    // Pinned tray items
    //
    // This row NEVER changes width when collapsing.
    // --------------------------------------------------------

    Row {
        id: pinnedRow

        Layout.preferredWidth:
            implicitWidth

        Layout.preferredHeight:
            root.iconSize

        spacing:
            root.iconSpacing

        Repeater {
            model:
                root.collapsedItems

            delegate: Item {
                id: pinnedDelegate

                required property var modelData

                width:
                    root.iconSize

                height:
                    root.iconSize

                readonly property bool needsAttention:
                    modelData.status ===
                    Status.NeedsAttention

                readonly property bool hasTooltip:
                    Boolean(
                        modelData.tooltipTitle ||
                        modelData.tooltipDescription ||
                        modelData.title
                    )

                Rectangle {
                    anchors.fill:
                        parent

                    radius:
                        7

                    color:
                        pinnedHover.containsMouse
                            ? Colors.primary
                            : "transparent"

                    opacity:
                        pinnedHover.containsMouse
                            ? 0.12
                            : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration:
                                Theme.hoverFadeDuration
                        }
                    }
                }

                Image {
                    anchors.centerIn:
                        parent

                    width:
                        root.iconSize

                    height:
                        root.iconSize

                    source:
                        modelData.icon || ""

                    fillMode:
                        Image.PreserveAspectFit

                    smooth:
                        true

                    mipmap:
                        true
                }

                Text {
                    visible:
                        modelData.icon === ""

                    anchors.centerIn:
                        parent

                    text:
                        "◈"

                    color:
                        Colors.on_SurfaceVariant

                    font.family:
                        Fonts.font

                    font.pixelSize:
                        13
                }

                Rectangle {
                    visible:
                        pinnedDelegate.needsAttention

                    width:
                        6

                    height:
                        6

                    radius:
                        3

                    anchors.right:
                        parent.right

                    anchors.top:
                        parent.top

                    color:
                        Colors.error

                    border.width:
                        1

                    border.color:
                        Colors.background

                    SequentialAnimation on opacity {
                        running:
                            pinnedDelegate.needsAttention

                        loops:
                            Animation.Infinite

                        NumberAnimation {
                            to:
                                0.35

                            duration:
                                650

                            easing.type:
                                Easing.InOutSine
                        }

                        NumberAnimation {
                            to:
                                1

                            duration:
                                650

                            easing.type:
                                Easing.InOutSine
                        }
                    }
                }

                Rectangle {
                    visible:
                        pinnedDelegate.hasTooltip &&
                        pinnedHover.containsMouse

                    z:
                        100

                    x:
                        Math.max(
                            -80,
                            Math.min(
                                -20,
                                (
                                    parent.width -
                                    width
                                ) / 2
                            )
                        )

                    y:
                        parent.height + 7

                    width:
                        Math.min(
                            260,
                            Math.max(
                                120,
                                pinnedTooltipText.implicitWidth +
                                20
                            )
                        )

                    height:
                        pinnedTooltipText.implicitHeight +
                        14

                    radius:
                        8

                    color:
                        Colors.surfaceContainerHigh

                    border.width:
                        1

                    border.color:
                        Colors.outlineVariant

                    Text {
                        id:
                            pinnedTooltipText

                        anchors.fill:
                            parent

                        anchors.margins:
                            10

                        text:
                            modelData.tooltipTitle ||
                            modelData.tooltipDescription ||
                            modelData.title ||
                            ""

                        color:
                            Colors.on_Surface

                        font.family:
                            Fonts.font

                        font.pixelSize:
                            11

                        wrapMode:
                            Text.WordWrap

                        maximumLineCount:
                            3

                        elide:
                            Text.ElideRight

                        verticalAlignment:
                            Text.AlignVCenter
                    }
                }

                MouseArea {
                    id:
                        pinnedHover

                    anchors.fill:
                        parent

                    hoverEnabled:
                        true

                    cursorShape:
                        Qt.PointingHandCursor

                    acceptedButtons:
                        Qt.LeftButton |
                        Qt.RightButton |
                        Qt.MiddleButton

                    onClicked: (mouse) => {
                        if (
                            mouse.button ===
                            Qt.LeftButton
                        ) {
                            if (
                                modelData.onlyMenu &&
                                modelData.hasMenu
                            ) {
                                root.openTrayMenu(
                                    modelData,
                                    pinnedDelegate
                                )
                            } else {
                                modelData.activate()
                            }
                        } else if (
                            mouse.button ===
                            Qt.MiddleButton
                        ) {
                            modelData.secondaryActivate()
                        } else if (
                            mouse.button ===
                            Qt.RightButton
                        ) {
                            root.openTrayMenu(
                                modelData,
                                pinnedDelegate
                            )
                        }
                    }

                    onWheel: (wheel) => {
                        const horizontal =
                            Math.abs(
                                wheel.angleDelta.x
                            ) >
                            Math.abs(
                                wheel.angleDelta.y
                            )

                        const delta =
                            horizontal
                                ? wheel.angleDelta.x
                                : wheel.angleDelta.y

                        modelData.scroll(
                            delta > 0 ? 1 : -1,
                            horizontal
                        )
                    }
                }
            }
        }
    }

    // --------------------------------------------------------
    // Overflow tray items
    //
    // These delegates always exist. Only the ROW'S visible
    // width changes, so they are never destroyed.
    // --------------------------------------------------------

    Item {
        id:
            overflowViewport

        Layout.preferredWidth:
            root.collapsed
                ? 0
                : overflowRow.implicitWidth

        Layout.minimumWidth:
            0

        Layout.maximumWidth:
            overflowRow.implicitWidth

        Layout.preferredHeight:
            root.iconSize

        clip:
            true

        Behavior on Layout.preferredWidth {
            NumberAnimation {
                duration:
                    Theme.animDuration

                easing.type:
                    Easing.OutCubic
            }
        }

        Row {
            id:
                overflowRow

            width:
                implicitWidth

            height:
                root.iconSize

            spacing:
                root.iconSpacing

            Repeater {
                model:
                    root.overflowItems

                delegate: Item {
                    id:
                        overflowDelegate

                    required property var modelData

                    width:
                        root.iconSize

                    height:
                        root.iconSize

                    readonly property bool needsAttention:
                        modelData.status ===
                        Status.NeedsAttention

                    readonly property bool hasTooltip:
                        Boolean(
                            modelData.tooltipTitle ||
                            modelData.tooltipDescription ||
                            modelData.title
                        )

                    opacity:
                        root.collapsed
                            ? 0
                            : 1

                    scale:
                        root.collapsed
                            ? 0.92
                            : 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration:
                                Theme.animDuration

                            easing.type:
                                Easing.OutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration:
                                Theme.animDuration

                            easing.type:
                                Easing.OutCubic
                        }
                    }

                    Rectangle {
                        anchors.fill:
                            parent

                        radius:
                            7

                        color:
                            overflowHover.containsMouse
                                ? Colors.primary
                                : "transparent"

                        opacity:
                            overflowHover.containsMouse
                                ? 0.12
                                : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration:
                                    Theme.hoverFadeDuration
                            }
                        }
                    }

                    Image {
                        anchors.centerIn:
                            parent

                        width:
                            root.iconSize

                        height:
                            root.iconSize

                        source:
                            modelData.icon || ""

                        fillMode:
                            Image.PreserveAspectFit

                        smooth:
                            true

                        mipmap:
                            true
                    }

                    Text {
                        visible:
                            modelData.icon === ""

                        anchors.centerIn:
                            parent

                        text:
                            "◈"

                        color:
                            Colors.on_SurfaceVariant

                        font.family:
                            Fonts.font

                        font.pixelSize:
                            13
                    }

                    Rectangle {
                        visible:
                            overflowDelegate.needsAttention

                        width:
                            6

                        height:
                            6

                        radius:
                            3

                        anchors.right:
                            parent.right

                        anchors.top:
                            parent.top

                        color:
                            Colors.error

                        border.width:
                            1

                        border.color:
                            Colors.background

                        SequentialAnimation on opacity {
                            running:
                                overflowDelegate.needsAttention

                            loops:
                                Animation.Infinite

                            NumberAnimation {
                                to:
                                    0.35

                                duration:
                                    650

                                easing.type:
                                    Easing.InOutSine
                            }

                            NumberAnimation {
                                to:
                                    1

                                duration:
                                    650

                                easing.type:
                                    Easing.InOutSine
                            }
                        }
                    }

                    Rectangle {
                        visible:
                            overflowDelegate.hasTooltip &&
                            overflowHover.containsMouse

                        z:
                            100

                        x:
                            Math.max(
                                -80,
                                Math.min(
                                    -20,
                                    (
                                        parent.width -
                                        width
                                    ) / 2
                                )
                            )

                        y:
                            parent.height + 7

                        width:
                            Math.min(
                                260,
                                Math.max(
                                    120,
                                    overflowTooltipText.implicitWidth +
                                    20
                                )
                            )

                        height:
                            overflowTooltipText.implicitHeight +
                            14

                        radius:
                            8

                        color:
                            Colors.surfaceContainerHigh

                        border.width:
                            1

                        border.color:
                            Colors.outlineVariant

                        Text {
                            id:
                                overflowTooltipText

                            anchors.fill:
                                parent

                            anchors.margins:
                                10

                            text:
                                modelData.tooltipTitle ||
                                modelData.tooltipDescription ||
                                modelData.title ||
                                ""

                            color:
                                Colors.on_Surface

                            font.family:
                                Fonts.font

                            font.pixelSize:
                                11

                            wrapMode:
                                Text.WordWrap

                            maximumLineCount:
                                3

                            elide:
                                Text.ElideRight

                            verticalAlignment:
                                Text.AlignVCenter
                        }
                    }

                    MouseArea {
                        id:
                            overflowHover

                        anchors.fill:
                            parent

                        hoverEnabled:
                            true

                        cursorShape:
                            Qt.PointingHandCursor

                        acceptedButtons:
                            Qt.LeftButton |
                            Qt.RightButton |
                            Qt.MiddleButton

                        onClicked: (mouse) => {
                            if (
                                mouse.button ===
                                Qt.LeftButton
                            ) {
                                if (
                                    modelData.onlyMenu &&
                                    modelData.hasMenu
                                ) {
                                    root.openTrayMenu(
                                        modelData,
                                        overflowDelegate
                                    )
                                } else {
                                    modelData.activate()
                                }
                            } else if (
                                mouse.button ===
                                Qt.MiddleButton
                            ) {
                                modelData.secondaryActivate()
                            } else if (
                                mouse.button ===
                                Qt.RightButton
                            ) {
                                root.openTrayMenu(
                                    modelData,
                                    overflowDelegate
                                )
                            }
                        }

                        onWheel: (wheel) => {
                            const horizontal =
                                Math.abs(
                                    wheel.angleDelta.x
                                ) >
                                Math.abs(
                                    wheel.angleDelta.y
                                )

                            const delta =
                                horizontal
                                    ? wheel.angleDelta.x
                                    : wheel.angleDelta.y

                            modelData.scroll(
                                delta > 0 ? 1 : -1,
                                horizontal
                            )
                        }
                    }
                }
            }
        }
    }
}}

    // ------------------------------------------------------------
    // Custom tray menu
    // ------------------------------------------------------------

    TrayContextMenu {
        id: trayMenu

        screen:
            root.window
                ? root.window.screen
                : null
    }

    function openTrayMenu(item, delegate) {
        if (
            !item ||
            !item.hasMenu
        ) {
            return
        }

        if (!root.window)
            return

        const p =
            root.window.contentItem.mapFromItem(
                delegate,
                delegate.width / 2,
                delegate.height
            )

        trayMenu.open(
            item.menu,
            p.x,
            p.y,
            item.title || "Tray"
        )
    }
}

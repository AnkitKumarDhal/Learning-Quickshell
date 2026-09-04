import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.src.theme

FocusScope {
    id: root

    property var menuHandle: null
    property string menuTitle: ""

    property int menuWidth: 272
    property int rowHeight: 38
    property int separatorHeight: 10
    property int outerPadding: 8
    property int headerHeight:
        menuTitle.length > 0 ? 24 : 0

    readonly property int maxMenuHeight: Math.max(120, Math.min(560, hostHeight - 16))
    property int hostWidth: width
    property int hostHeight: height
    property int hostX: x

    property var submenuHandle: null
    property int submenuY: 0
    property bool submenuOpen: false
    property int pendingSubmenuIndex: -1

    property int currentIndex: -1
    signal triggered()
    signal pointerEntered()

    readonly property int contentHeight: calculateContentHeight()
    readonly property int bodyHeight: Math.max(48, Math.min(contentHeight, maxMenuHeight - outerPadding * 2 - headerHeight))
    readonly property int menuHeight: outerPadding * 2 + headerHeight + bodyHeight

    width: menuWidth
    height: menuHeight

    implicitWidth: menuWidth
    implicitHeight: menuHeight

    focus: true

    function calculateContentHeight() {
        if (!menuHandle) return 0
        const entries = menuOpener.children.values

        let total = 0

        for (let i = 0; i < entries.length; ++i) {
            total += entries[i].isSeparator ? separatorHeight : rowHeight
            if (i < entries.length - 1) total += 2
        }

        return total
    }

    function isSelectable(index) {
        const entries = menuOpener.children.values
        if (index < 0 || index >= entries.length) return false
        const entry = entries[index]
        return !entry.isSeparator && entry.enabled !== false
    }

    function firstSelectableIndex() {
        const entries = menuOpener.children.values
        for (let i = 0; i < entries.length; ++i) {
            if (isSelectable(i)) return i
        }
        return -1
    }

    function lastSelectableIndex() {
        const entries = menuOpener.children.values
        for (let i = entries.length - 1; i >= 0; --i) {
            if (isSelectable(i)) return i
        }
        return -1
    }

    function nextSelectableIndex(index, direction) {
        const entries = menuOpener.children.values
        if (entries.length === 0) return -1
        let i = index

        for (let step = 0; step < entries.length; ++step) {
            i += direction
            if (i < 0) i = entries.length - 1
            if (i >= entries.length) i = 0
            if (isSelectable(i)) return i
        }

        return -1
    }

    function resetKeyboard() {
        currentIndex = firstSelectableIndex()
        ensureCurrentIndexVisible()
    }

    function selectNext() {
        if (currentIndex < 0) {
            currentIndex = firstSelectableIndex()
        } else {
            currentIndex = nextSelectableIndex(currentIndex, 1)
        }
        ensureCurrentIndexVisible()
    }

    function selectPrevious() {
        if (currentIndex < 0) {
            currentIndex = lastSelectableIndex()
        } else {
            currentIndex = nextSelectableIndex(currentIndex, -1)
        }
        ensureCurrentIndexVisible()
    }

    function activateCurrent() {
        const entries = menuOpener.children.values
        if (!isSelectable(currentIndex)) return
        const entry = entries[currentIndex]
        if (entry.hasChildren) {
            openSubmenu(currentIndex, true)
        } else {
            entry.triggered()
            root.triggered()
        }
    }

    function openSubmenu(index, keyboardOpen) {
        const entries = menuOpener.children.values

        if (index < 0 || index >= entries.length) {
            return
        }

        const entry = entries[index]

        if (!entry.hasChildren || entry.enabled === false) {
            return
        }

        submenuHandle = entry
        submenuY = menuColumn.y + menuColumn.spacing * index + menuItemPosition(index)
        submenuOpen = true

        if (keyboardOpen) submenuFocusTimer.restart()
    }

    function menuItemPosition(index) {
        let position = 0
        const entries = menuOpener.children.values

        for (let i = 0; i < index; ++i) {
            position += entries[i].isSeparator ? separatorHeight : rowHeight
            if (i < entries.length - 1) position += 2
        }

        return position
    }

    function closeSubmenu() {
        submenuCloseTimer.stop()
        submenuOpen = false
        submenuHandle = null
    }

    function closeSubmenuSoon(delay) {
        submenuCloseTimer.interval = delay !== undefined ? delay : 320
        submenuCloseTimer.restart()
    }

    function cancelSubmenuClose() {
        submenuCloseTimer.stop()
    }

    function ensureCurrentIndexVisible() {
        if (currentIndex < 0) return

        const entryY = menuColumn.y - contentFlick.contentY + menuItemPosition(currentIndex)
        const entryBottom = entryY + rowHeight
        if (entryY < contentFlick.contentY) {
            contentFlick.contentY = menuItemPosition(currentIndex)
        } else if (entryBottom > contentFlick.contentY + contentFlick.height) {
            contentFlick.contentY = menuItemPosition(currentIndex) + rowHeight - contentFlick.height
        }
    }

    QsMenuOpener {
        id: menuOpener
        menu: root.menuHandle
        onChildrenChanged: { root.resetKeyboard() }
    }

    Timer {
        id: submenuCloseTimer
        interval: 320
        onTriggered: { root.closeSubmenu() }
    }

    Timer {
        id: submenuFocusTimer
        interval: 0
        onTriggered: {
            if (submenuLoader.item && root.submenuOpen) {
                submenuLoader.item.resetKeyboard()
                submenuLoader.item.forceActiveFocus()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Colors.surfaceContainer
        border.width: 1
        border.color: Colors.outlineVariant
    }

    Item {
        visible: root.headerHeight > 0
        x: root.outerPadding
        y: root.outerPadding
        width: parent.width - root.outerPadding * 2
        height: root.headerHeight

        Text {
            anchors.fill: parent
            text: root.menuTitle
            color: Colors.on_SurfaceVariant
            font.family: Fonts.font
            font.pixelSize: 10
            font.bold: true
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            opacity: 0.8
        }
    }

    Flickable {
        id: contentFlick
        x: root.outerPadding
        y: root.outerPadding + root.headerHeight
        width: root.width - root.outerPadding * 2
        height: root.bodyHeight
        clip: true
        contentWidth: width
        contentHeight: menuColumn.implicitHeight
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 1800

        onContentYChanged: {
            if (contentHeight <= height) contentY = 0
        }

        Column {
            id: menuColumn
            width: contentFlick.width
            spacing: 2

            Repeater {
                model: menuOpener.children
                delegate: Item {
                    id: menuItem

                    required property var modelData
                    required property int index
                    readonly property bool isSeparator: modelData.isSeparator
                    readonly property bool hasChildren: modelData.hasChildren
                    readonly property bool enabledItem: modelData.enabled !== false
                    readonly property string buttonTypeName: {
                        if (isSeparator || modelData.buttonType === undefined) {
                            return "None"
                        }
                        return QsMenuButtonType.toString(modelData.buttonType)
                    }

                    readonly property bool hasButton: buttonTypeName !== "None"
                    readonly property bool checked: hasButton && modelData.checkState !== Qt.Unchecked

                    width: menuColumn.width
                    height: isSeparator ? root.separatorHeight : root.rowHeight

                    Rectangle {
                        visible: !menuItem.isSeparator && root.currentIndex === menuItem.index
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: 9
                        color: Colors.primary
                        opacity: menuItem.enabledItem ? 0.13 : 0.05
                    }

                    Rectangle {
                        visible: hoverArea.containsMouse && !menuItem.isSeparator && root.currentIndex !== menuItem.index
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: 9
                        color: Colors.primary
                        opacity: 0.10

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.hoverFadeDuration
                            }
                        }
                    }

                    Rectangle {
                        visible: menuItem.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: Colors.outlineVariant
                        opacity: 0.7
                    }

                    RowLayout {
                        visible: !menuItem.isSeparator
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10
                        opacity: menuItem.enabledItem ? 1 : 0.42

                        Item {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20

                            IconImage {
                                id: menuIcon
                                visible: !menuItem.hasButton && modelData.icon !== undefined && modelData.icon !== ""
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                source: modelData.icon || ""
                                mipmap: true
                            }

                            Rectangle {
                                visible: menuItem.buttonTypeName === "CheckBox"
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                radius: 4
                                color: menuItem.checked ? Colors.primary : "transparent"
                                border.width: 1
                                border.color: menuItem.checked ? Colors.primary : Colors.outline

                                Text {
                                    visible: menuItem.checked
                                    anchors.centerIn: parent
                                    text: "✓"
                                    color: Colors.on_Primary
                                    font.family: Fonts.font
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                visible: menuItem.buttonTypeName === "RadioButton"
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                radius: 8
                                color: "transparent"
                                border.width: 1
                                border.color: menuItem.checked ? Colors.primary : Colors.outline

                                Rectangle {
                                    visible: menuItem.checked
                                    anchors.centerIn: parent
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: Colors.primary
                                }
                            }
                        }

                        Text {
                            text: modelData.text || ""
                            color: Colors.on_Surface
                            font.family: Fonts.font
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            visible: menuItem.hasChildren
                            text: "›"
                            color: Colors.on_SurfaceVariant
                            font.family: Fonts.font
                            font.pixelSize: 18
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: menuItem.enabledItem && !menuItem.isSeparator
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onEntered: {
                            root.pointerEntered()
                            root.currentIndex = menuItem.index
                            if (menuItem.hasChildren) {
                                root.openSubmenu(menuItem.index, false)
                            } else {
                                root.closeSubmenuSoon(120)
                            }
                        }

                        onClicked: {
                            if (menuItem.hasChildren) {
                                root.openSubmenu(menuItem.index, false)
                            } else {
                                menuItem.modelData.triggered()
                                root.triggered()
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: scrollHandle
        visible: contentFlick.contentHeight > contentFlick.height
        x: root.width - root.outerPadding - 4
        y: contentFlick.y + 4 + (contentFlick.contentY / Math.max(1, contentFlick.contentHeight - contentFlick.height)) * Math.max(1, contentFlick.height - 8 - scrollHandle.height)
        width: 3
        height: Math.max(24, contentFlick.height * contentFlick.height / Math.max(1, contentFlick.contentHeight))
        radius: 2
        color: Colors.on_SurfaceVariant
        opacity: 0.65
    }

    Loader {
        id: submenuLoader
        active: root.submenuOpen && root.submenuHandle !== null
        source: active ? Qt.resolvedUrl("TrayMenuLevel.qml") : ""
        width: root.menuWidth
        height: item ? item.height : 0
        x: {
            const openRight = root.hostX + root.width + root.menuWidth <= root.hostWidth
            return openRight ? root.width - 2 : -root.menuWidth + 2
        }

        y: {
            if (!item) return root.submenuY - root.y
            const preferredY = root.submenuY - root.y
            return Math.max(8, Math.min(preferredY, root.hostHeight - item.height - 8))
        }

        Binding {
            target: submenuLoader.item
            property: "menuHandle"
            value: root.submenuHandle
            when: submenuLoader.item !== null
        }

        Binding {
            target: submenuLoader.item
            property: "hostWidth"
            value: root.hostWidth
            when: submenuLoader.item !== null
        }

        Binding {
            target: submenuLoader.item
            property: "hostHeight"
            value: root.hostHeight
            when: submenuLoader.item !== null
        }

        Binding {
            target: submenuLoader.item
            property: "hostX"
            value: root.hostX + submenuLoader.x
            when: submenuLoader.item !== null
        }

        Binding {
            target: submenuLoader.item
            property: "menuWidth"
            value: root.menuWidth
            when: submenuLoader.item !== null
        }

        Binding {
            target: submenuLoader.item
            property: "menuTitle"
            value: ""
            when: submenuLoader.item !== null
        }

        Binding {
            target: submenuLoader.item
            property: "parentLevel"
            value: root
            when: submenuLoader.item !== null
        }

        onLoaded: {
            if (!item) return
            item.triggered.connect(root.triggered)
            item.pointerEntered.connect(root.cancelSubmenuClose)
            if (root.submenuOpen) item.resetKeyboard()
        }
    }

    Keys.onPressed: (event) => {
        switch (event.key) {
            case Qt.Key_Down:
                root.selectNext()
                event.accepted = true
                break

            case Qt.Key_Up:
                root.selectPrevious()
                event.accepted = true
                break

            case Qt.Key_Home:
                root.currentIndex = root.firstSelectableIndex()
                root.ensureCurrentIndexVisible()
                event.accepted = true
                break

            case Qt.Key_End:
                root.currentIndex = root.lastSelectableIndex()
                root.ensureCurrentIndexVisible()
                event.accepted = true
                break

            case Qt.Key_Right:
                if (root.currentIndex >= 0) {
                    const entries = menuOpener.children.values
                    if (entries[root.currentIndex] && entries[root.currentIndex].hasChildren) {
                        root.openSubmenu(root.currentIndex, true)
                    }
                }
                event.accepted = true
                break

            case Qt.Key_Left:
                if (root.parentLevel) {
                    root.parentLevel.closeSubmenu()
                    root.parentLevel.forceActiveFocus()
                }
                event.accepted = true
                break

            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
                root.activateCurrent()
                event.accepted = true
                break

            case Qt.Key_Escape:
                root.triggered()
                event.accepted = true
                break
        }
    }

    property var parentLevel: null
}

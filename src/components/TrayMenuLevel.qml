import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.src.theme

// One level of the tray's custom menu. Submenus are loaded recursively into
// the same overlay window, so the Hyprland focus grab never loses ownership
// of the menu interaction when moving into a submenu.
Item {
    id: root

    property var menuHandle: null
    property string menuTitle: ""
    property int menuWidth: 272
    property int rowHeight: 38
    property int separatorHeight: 10
    property int outerPadding: 8
    property int headerHeight:
        menuTitle.length > 0 ? 24 : 0

    property int hostWidth: width
    property int hostHeight: height
    property int hostX: x

    signal triggered()

    readonly property bool hasMenu:
        menuHandle !== null

    readonly property int menuHeight:
        calculateMenuHeight()

    width: menuWidth
    height: menuHeight

    implicitWidth: menuWidth
    implicitHeight: menuHeight

    function calculateMenuHeight() {
        if (!menuHandle)
            return 0

        const entries = menuOpener.children.values
        const spacingHeight =
            Math.max(0, entries.length - 1) * 2

        let height =
            outerPadding * 2 +
            headerHeight +
            spacingHeight

        for (let i = 0; i < entries.length; ++i) {
            height +=
                entries[i].isSeparator
                    ? separatorHeight
                    : rowHeight
        }

        return Math.max(52, height)
    }

    property var submenuHandle: null
    property int submenuY: 0
    property bool submenuOpen: false

    QsMenuOpener {
        id: menuOpener
        menu: root.menuHandle
    }

    // Main menu surface.
    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Colors.surfaceContainer
        border.width: 1
        border.color: Colors.outlineVariant
    }

    // Optional application name at the top.
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

    Column {
        id: menuColumn

        x: root.outerPadding
        y: root.outerPadding + root.headerHeight

        width: parent.width - root.outerPadding * 2
        spacing: 2

        Repeater {
            model: menuOpener.children

            delegate: Item {
                id: menuItem

                required property var modelData
                required property int index

                readonly property bool isSeparator:
                    modelData.isSeparator

                readonly property bool hasChildren:
                    modelData.hasChildren

                readonly property bool enabledItem:
                    modelData.enabled !== false

                readonly property string buttonTypeName: {
                    if (
                        isSeparator ||
                        modelData.buttonType === undefined
                    ) {
                        return "None"
                    }

                    return QsMenuButtonType.toString(
                        modelData.buttonType
                    )
                }

                readonly property bool hasButton:
                    buttonTypeName !== "None"

                readonly property bool checked:
                    hasButton &&
                    modelData.checkState !== Qt.Unchecked

                width: menuColumn.width

                height:
                    isSeparator
                        ? root.separatorHeight
                        : root.rowHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1

                    radius: 9
                    color: Colors.primary

                    opacity:
                        hoverArea.containsMouse &&
                        menuItem.enabledItem &&
                        !menuItem.isSeparator
                            ? 0.10
                            : 0

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

                    opacity:
                        menuItem.enabledItem
                            ? 1
                            : 0.42

                    // Fixed leading slot keeps labels aligned whether an
                    // entry is an icon, checkbox, radio button, or action.
                    Item {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20

                        Image {
                            visible:
                                !menuItem.hasButton &&
                                modelData.icon !== undefined &&
                                modelData.icon !== ""

                            anchors.centerIn: parent

                            width: 18
                            height: 18

                            source: modelData.icon || ""
                            sourceSize: Qt.size(18, 18)

                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }

                        Rectangle {
                            visible:
                                menuItem.buttonTypeName === "CheckBox"

                            anchors.centerIn: parent

                            width: 16
                            height: 16

                            radius: 4

                            color:
                                menuItem.checked
                                    ? Colors.primary
                                    : "transparent"

                            border.width: 1

                            border.color:
                                menuItem.checked
                                    ? Colors.primary
                                    : Colors.outline

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
                            visible:
                                menuItem.buttonTypeName ===
                                "RadioButton"

                            anchors.centerIn: parent

                            width: 16
                            height: 16

                            radius: 8

                            color: "transparent"

                            border.width: 1

                            border.color:
                                menuItem.checked
                                    ? Colors.primary
                                    : Colors.outline

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

                    enabled:
                        menuItem.enabledItem &&
                        !menuItem.isSeparator

                    cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        if (menuItem.hasChildren) {
                            root.submenuHandle =
                                menuItem.modelData

                            root.submenuY =
                                menuColumn.y +
                                menuItem.y

                            root.submenuOpen = true
                        } else {
                            root.submenuHandle = null
                            root.submenuOpen = false
                        }
                    }

                    onClicked: {
                        if (menuItem.hasChildren) {
                            root.submenuHandle =
                                menuItem.modelData

                            root.submenuY =
                                menuColumn.y +
                                menuItem.y

                            root.submenuOpen = true
                        } else {
                            menuItem.modelData.triggered()
                            root.triggered()
                        }
                    }
                }
            }
        }
    }

    // Recursively loaded child menu.
    Loader {
        id: submenuLoader

        active:
            root.submenuOpen &&
            root.submenuHandle !== null

        source:
            active
                ? Qt.resolvedUrl("TrayMenuLevel.qml")
                : ""

        width: root.menuWidth
        height: item ? item.implicitHeight : 0

        x:
            root.hostX +
            root.width +
            root.menuWidth <= root.hostWidth
                ? root.width - 2
                : -root.menuWidth + 2

        y:
            root.submenuY - root.y

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
            value:
                root.hostX +
                submenuLoader.x

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

        onLoaded: {
            if (item)
                item.triggered.connect(root.triggered)
        }
    }
}

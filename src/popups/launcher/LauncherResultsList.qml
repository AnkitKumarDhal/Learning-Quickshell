import QtQuick
import QtQuick.Controls
import qs.src.theme

Item {
    id: root

    property var    filteredApps:  []
    property int    selectedIndex: 0
    property string searchText:    ""

    signal launched(int index)
    signal selectionChanged(int index)

    function positionAt(idx) {
        listView.positionViewAtIndex(
            idx,
            ListView.Contain
        )
    }

    readonly property int itemH:    54
    readonly property int emptyH:   72
    readonly property int maxListH: 416

    height:
        root.filteredApps.length > 0
            ? Math.min(
                root.filteredApps.length * root.itemH,
                root.maxListH
            )
            : root.emptyH

    Item {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        height: root.emptyH

        visible: root.filteredApps.length === 0

        Text {
            anchors.centerIn: parent

            text:
                root.searchText === ""
                    ? "Loading applications…"
                    : "No results for " + root.searchText

            color:          Colors.on_SurfaceVariant
            font.pixelSize: 13
            font.family:    Fonts.font
            opacity:        0.6
        }
    }

    ListView {
        id: listView

        anchors.fill: parent

        visible:
            root.filteredApps.length > 0

        model: root.filteredApps

        clip: true

        boundsBehavior:
            Flickable.StopAtBounds

        keyNavigationEnabled: false

        ScrollBar.vertical: ScrollBar {
            policy:
                listView.contentHeight > listView.height
                    ? ScrollBar.AlwaysOn
                    : ScrollBar.AlwaysOff

            contentItem: Rectangle {
                implicitWidth:  3
                implicitHeight: 40
                radius:         1.5
                color:          Qt.rgba(1, 1, 1, 0.25)
            }

            background: Item {}
        }

        delegate: LauncherResultItem {
            required property var modelData
            required property int index

            width:
                listView.width -
                (listView.contentHeight > listView.height
                    ? 10
                    : 0)

            appData:    modelData
            isSelected: index === root.selectedIndex

            onActivated:
                root.launched(index)

            onHovered:
                root.selectionChanged(index)
        }
    }
}

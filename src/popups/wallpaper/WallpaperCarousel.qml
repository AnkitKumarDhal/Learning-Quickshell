import QtQuick
import qs.src.theme
import qs.src.popups.wallpaper

Item {
    id: root

    signal wallpaperSelected(int index)
    signal applyRequested()
    signal escapeRequested()

    property var    wallpapers:      []
    property int    selectedIndex:   0
    property string currentWall:     ""
    property bool   applying:        false
    property int    thumbnailWidth:  420
    property int    thumbnailHeight: 280
    property string wallpaperDir:    "~/wallpapers"

    clip: true

    onSelectedIndexChanged: {
        Qt.callLater(() => {
            root.positionAt(root.selectedIndex)
        })
    }

    onWallpapersChanged: {
        Qt.callLater(() => {
            if (root.wallpapers.length === 0) return

            root.positionAt(root.selectedIndex)
        })
    }

    ListView {
        id: wallCarousel

        anchors.fill: parent

        orientation:               ListView.Horizontal
        spacing:                   18
        clip:                      true
        boundsBehavior:            Flickable.StopAtBounds
        snapMode:                  ListView.SnapToItem

        preferredHighlightBegin:   Math.max(0, (width - 500) / 2)
        preferredHighlightEnd:     Math.max(0, (width - 500) / 2) + 500

        highlightRangeMode:        ListView.StrictlyEnforceRange
        highlightFollowsCurrentItem: true

        interactive:               root.wallpapers.length > 1
        focus:                     true

        model:                     root.wallpapers

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                root.escapeRequested()
                event.accepted = true
            } else if (event.key === Qt.Key_Left) {
                root.selectRelative(-1)
                event.accepted = true
            } else if (event.key === Qt.Key_Right) {
                root.selectRelative(1)
                event.accepted = true
            } else if (event.key === Qt.Key_Home) {
                root.selectWallpaper(0)
                event.accepted = true
            } else if (event.key === Qt.Key_End) {
                root.selectWallpaper(root.wallpapers.length - 1)
                event.accepted = true
            } else if (event.key === Qt.Key_Return ||
                       event.key === Qt.Key_Enter ||
                       event.key === Qt.Key_Space) {
                root.applyRequested()
                event.accepted = true
            }
        }

        onMovementEnded: {
            if (currentIndex >= 0 &&
                currentIndex < root.wallpapers.length &&
                root.selectedIndex !== currentIndex) {
                root.wallpaperSelected(currentIndex)
            }
        }

        delegate: Item {
            id: thumbDelegate

            required property var modelData
            required property int index

            width:  500
            height: Math.min(parent ? parent.height - 8 : 260, 280)

            WallpaperCard {
                anchors.fill: parent

                sourcePath:       thumbDelegate.modelData.sourcePath
                thumbnailPath:    thumbDelegate.modelData.thumbnailPath
                thumbReady:       thumbDelegate.modelData.thumbReady
                selected:         root.selectedIndex === thumbDelegate.index
                active:           root.currentWall === thumbDelegate.modelData.sourcePath
                applying:         root.applying
                thumbnailWidth:   root.thumbnailWidth
                thumbnailHeight:  root.thumbnailHeight

                onClicked: {
                    root.selectWallpaper(thumbDelegate.index)
                    wallCarousel.forceActiveFocus()
                }
            }
        }
    }

    // Previous button
    Rectangle {
        visible:             root.wallpapers.length > 1
        anchors.left:        parent.left
        anchors.leftMargin:  6
        anchors.verticalCenter: parent.verticalCenter

        width:               38
        height:              38
        radius:              19

        color:               previousHov.containsMouse
                                ? Qt.rgba(
                                      Colors.primary.r,
                                      Colors.primary.g,
                                      Colors.primary.b,
                                      0.18)
                                : Qt.rgba(
                                      Colors.surfaceContainerHighest.r,
                                      Colors.surfaceContainerHighest.g,
                                      Colors.surfaceContainerHighest.b,
                                      0.88)

        Behavior on color {
            ColorAnimation {
                duration: Theme.hoverFadeDuration
            }
        }

        Text {
            anchors.centerIn: parent

            text:             "󰁍"

            color:            previousHov.containsMouse
                                ? Colors.primary
                                : Colors.on_SurfaceVariant

            font.pixelSize:   16
            font.family:      Fonts.fontM
        }

        MouseArea {
            id:           previousHov

            anchors.fill: parent

            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor

            onClicked: {
                root.selectRelative(-1)
                wallCarousel.forceActiveFocus()
            }
        }
    }

    // Next button
    Rectangle {
        visible:             root.wallpapers.length > 1
        anchors.right:       parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter

        width:               38
        height:              38
        radius:              19

        color:               nextHov.containsMouse
                                ? Qt.rgba(
                                      Colors.primary.r,
                                      Colors.primary.g,
                                      Colors.primary.b,
                                      0.18)
                                : Qt.rgba(
                                      Colors.surfaceContainerHighest.r,
                                      Colors.surfaceContainerHighest.g,
                                      Colors.surfaceContainerHighest.b,
                                      0.88)

        Behavior on color {
            ColorAnimation {
                duration: Theme.hoverFadeDuration
            }
        }

        Text {
            anchors.centerIn: parent

            text:             "󰁔"

            color:            nextHov.containsMouse
                                ? Colors.primary
                                : Colors.on_SurfaceVariant

            font.pixelSize:   16
            font.family:      Fonts.fontM
        }

        MouseArea {
            id:           nextHov

            anchors.fill: parent

            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor

            onClicked: {
                root.selectRelative(1)
                wallCarousel.forceActiveFocus()
            }
        }
    }

    Text {
        visible:          root.wallpapers.length === 0
        anchors.centerIn: parent

        text:             "No images found in " + root.wallpaperDir

        font.family:      Fonts.font
        font.pixelSize:   12
        color:            Colors.outline
    }

    function selectWallpaper(index) {
        if (root.wallpapers.length === 0) return

        const nextIndex = Math.max(
            0,
            Math.min(index, root.wallpapers.length - 1)
        )

        root.wallpaperSelected(nextIndex)
    }

    function selectRelative(delta) {
        if (root.wallpapers.length === 0) return

        root.selectWallpaper(
            root.selectedIndex + delta
        )
    }

    function positionAt(index) {
        if (root.wallpapers.length === 0) return
        if (index < 0 || index >= root.wallpapers.length) return
        if (wallCarousel.count <= index) return

        wallCarousel.currentIndex = index

        wallCarousel.positionViewAtIndex(
            index,
            ListView.SnapPosition
        )
    }

    function forceActiveFocus() {
        wallCarousel.forceActiveFocus()
    }

    property int count: wallCarousel.count
}

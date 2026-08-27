import QtQuick
import qs.src.theme
import qs.src.popups.wallpaper

Item {
    id: root

    signal wallpaperSelected(int index)
    signal applyRequested()
    signal escapeRequested()

    property var    wallpapers:      null
    property int    selectedIndex:   0
    property string currentWall:     ""
    property bool   applying:        false
    property int    thumbnailWidth:  420
    property int    thumbnailHeight: 280
    property string wallpaperDir:    "~/wallpapers"

    property bool   _positionedOnce: false

    readonly property real centerX: width / 2

    clip: true

    onSelectedIndexChanged: {
        Qt.callLater(() => {
            root.positionAt(
                root.selectedIndex,
                root._positionedOnce
            )

            root._positionedOnce = true
        })
    }

    NumberAnimation {
        id: carouselAnimation

        target:   wallCarousel
        property: "contentX"

        duration: 280

        easing.type: Easing.OutCubic
    }

    ListView {
        id: wallCarousel

        anchors.fill: parent

        orientation: ListView.Horizontal

        model: root.wallpapers

        clip: true

        boundsBehavior: Flickable.StopAtBounds

        snapMode: ListView.SnapToItem

        spacing: -40

        interactive: root.wallpapers &&
                     root.wallpapers.count > 1

        focus: true

        preferredHighlightBegin:
            Math.max(0, (width - 500) / 2)

        preferredHighlightEnd:
            Math.max(0, (width - 500) / 2) + 500

        highlightRangeMode:
            ListView.StrictlyEnforceRange

        highlightFollowsCurrentItem: true

        delegate: Item {
            id: thumbDelegate

            required property string sourcePath
            required property string thumbnailPath
            required property bool   thumbReady
            required property int    index

            width:  500
            height: 280

            z: visualZ

            readonly property real delegateCenter:
                x + width / 2

            readonly property real viewportCenter:
                wallCarousel.contentX +
                wallCarousel.width / 2

            readonly property real distance:
                Math.abs(
                    delegateCenter -
                    viewportCenter
                )

            readonly property real normalizedDistance:
                Math.min(
                    distance / 500,
                    1.0
                )

            readonly property real visualScale:
                1.0 -
                (
                    normalizedDistance *
                    0.16
                )

            readonly property real visualOpacity:
                1.0 -
                (
                    normalizedDistance *
                    0.30
                )

            readonly property real visualOffsetY:
                normalizedDistance * 8

            readonly property real visualZ:
                100 -
                Math.round(
                    normalizedDistance * 50
                )

            readonly property bool isCentered:
                distance < 40

            WallpaperCard {
                anchors.fill: parent

                sourcePath:      thumbDelegate.sourcePath
                thumbnailPath:   thumbDelegate.thumbnailPath
                thumbReady:      thumbDelegate.thumbReady

                selected:        thumbDelegate.isCentered

                active:          root.currentWall ===
                                 thumbDelegate.sourcePath

                applying:        root.applying

                thumbnailWidth:  root.thumbnailWidth
                thumbnailHeight: root.thumbnailHeight

                visualScale:     thumbDelegate.visualScale
                visualOpacity:   thumbDelegate.visualOpacity
                visualOffsetY:   thumbDelegate.visualOffsetY

                onClicked: {
                    root.selectWallpaper(
                        thumbDelegate.index
                    )

                    wallCarousel.forceActiveFocus()
                }
            }
        }

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
                root.selectWallpaper(
                    root.wallpapers.count - 1
                )
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
                root.wallpapers &&
                currentIndex < root.wallpapers.count &&
                root.selectedIndex !== currentIndex) {

                root.wallpaperSelected(currentIndex)
            }
        }
    }

    // Previous button
    Rectangle {
        visible: root.wallpapers &&
                 root.wallpapers.count > 1

        anchors.left:        parent.left
        anchors.leftMargin:  6
        anchors.verticalCenter: parent.verticalCenter

        width:  38
        height: 38
        radius: 19

        color: previousHov.containsMouse
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

            text: "󰁍"

            color: previousHov.containsMouse
                       ? Colors.primary
                       : Colors.on_SurfaceVariant

            font.pixelSize: 16
            font.family:    Fonts.fontM
        }

        MouseArea {
            id: previousHov

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
        visible: root.wallpapers &&
                 root.wallpapers.count > 1

        anchors.right:       parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter

        width:  38
        height: 38
        radius: 19

        color: nextHov.containsMouse
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

            text: "󰁔"

            color: nextHov.containsMouse
                       ? Colors.primary
                       : Colors.on_SurfaceVariant

            font.pixelSize: 16
            font.family:    Fonts.fontM
        }

        MouseArea {
            id: nextHov

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
        visible: !root.wallpapers ||
                 root.wallpapers.count === 0

        anchors.centerIn: parent

        text: "No images found in " + root.wallpaperDir

        font.family:    Fonts.font
        font.pixelSize: 12
        color:          Colors.outline
    }

    function selectWallpaper(index) {
        if (!root.wallpapers ||
            root.wallpapers.count === 0) {
            return
        }

        const nextIndex = Math.max(
            0,
            Math.min(
                index,
                root.wallpapers.count - 1
            )
        )

        root.wallpaperSelected(nextIndex)
    }

    function selectRelative(delta) {
        if (!root.wallpapers ||
            root.wallpapers.count === 0) {
            return
        }

        root.selectWallpaper(
            root.selectedIndex + delta
        )
    }

    function positionAt(index, animate) {
        if (!root.wallpapers) return
        if (root.wallpapers.count === 0) return

        if (index < 0 ||
            index >= root.wallpapers.count) {
            return
        }

        if (wallCarousel.count <= index) return

        carouselAnimation.stop()

        const oldX = wallCarousel.contentX

        wallCarousel.currentIndex = index

        wallCarousel.positionViewAtIndex(
            index,
            ListView.SnapPosition
        )

        const targetX = wallCarousel.contentX

        if (!animate ||
            Math.abs(targetX - oldX) < 1) {
            wallCarousel.contentX = targetX
            return
        }

        wallCarousel.contentX = oldX

        carouselAnimation.from = oldX
        carouselAnimation.to   = targetX

        carouselAnimation.start()
    }

    function forceActiveFocus() {
        wallCarousel.forceActiveFocus()
    }

    property int count: {
        return root.wallpapers
            ? wallCarousel.count
            : 0
    }
}

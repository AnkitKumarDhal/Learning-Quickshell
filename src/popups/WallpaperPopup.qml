import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.src.components
import qs.src.theme
import qs.src.state
import qs.src.popups.wallpaper

PanelWindow {
    id: root

    color:         "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        bottom: true
        left:   true
        right:  true
    }

    implicitWidth:  screen ? screen.width : 1880
    implicitHeight: 520

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Popups.wallpaperOpen
                                  ? WlrKeyboardFocus.Exclusive
                                  : WlrKeyboardFocus.None

    visible: slide.windowVisible

    mask:
        Region {
            x:      (root.implicitWidth - wallRec.width) / 2
            y:      root.implicitHeight - wallRec.height - 18
            width:  wallRec.width
            height: wallRec.height
        }

    WallpaperModel {
        id: wallpaperModel
    }

    Connections {
        target: Popups

        function onWallpaperOpenChanged() {
            if (Popups.wallpaperOpen) {
                root._preparePopup()
            }
        }
    }

    Component.onCompleted: {
        wallpaperModel.queryCurrentWallpaper()

        if (Popups.wallpaperOpen) {
            root._preparePopup()
        }
    }

    function _preparePopup() {
        directoryBar.updateDirectory(
            wallpaperModel.wallpaperDir
        )

        wallpaperModel.queryCurrentWallpaper()
        wallpaperModel.scanWallpapers()

        Qt.callLater(() => {
            wallpaperCarousel.forceActiveFocus()
        })
    }

    PopupSlide {
        id:           slide

        anchors.fill: parent

        edge:         "bottom"

        open:         Popups.wallpaperOpen

        onCloseRequested: Popups.wallpaperOpen = false

        Rectangle {
            id: wallRec

            anchors {
                bottom:           parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin:     18
            }

            width:  Math.min(parent.width - 36, 960)
            height: 460

            radius:       Theme.popupRadius
            color:        Colors.surfaceContainer
            border.color: Colors.outlineVariant
            border.width: Theme.popupBorder
            clip:         true

            ColumnLayout {
                anchors {
                    fill:         parent
                    margins:      16
                    bottomMargin: 12
                }

                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    spacing: 10

                    Text {
                        text:           "󰋲"

                        color:          Colors.primary

                        font.pixelSize: 18
                        font.family:    Fonts.fontM
                    }

                    Text {
                        text:             "Wallpapers"

                        color:            Colors.on_Surface

                        font.pixelSize:   14
                        font.bold:        true
                        font.family:      Fonts.font

                        Layout.fillWidth: true
                    }

                    Text {
                        visible:        wallpaperModel.applying

                        text:           "Applying…"

                        color:          Colors.primary

                        font.pixelSize: 11
                        font.family:    Fonts.font

                        SequentialAnimation on opacity {
                            running: wallpaperModel.applying
                            loops:   Animation.Infinite

                            NumberAnimation {
                                to:       0.3
                                duration: 600
                                easing.type: Easing.InOutSine
                            }

                            NumberAnimation {
                                to:       0.7
                                duration: 600
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }

                WallpaperDirectoryBar {
                    id: directoryBar

                    Layout.fillWidth: true

                    directory: wallpaperModel.wallpaperDir

                    onDirectoryAccepted: (directory) => {
                        wallpaperModel.wallpaperDir = directory
                        wallpaperModel.scanWallpapers()
                        wallpaperCarousel.forceActiveFocus()
                    }

                    onRescanRequested: (directory) => {
                        wallpaperModel.wallpaperDir = directory
                        wallpaperModel.scanWallpapers()
                        wallpaperCarousel.forceActiveFocus()
                    }

                    onEscapeRequested: {
                        Popups.wallpaperOpen = false
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true

                    height:           1

                    color:            Colors.outlineVariant
                    opacity:          0.5
                }

                Item {
                    Layout.fillWidth:  true
                    Layout.fillHeight: true

                    clip:              true

                    WallpaperCarousel {
                        id: wallpaperCarousel

                        anchors.fill: parent

                        wallpapers:      wallpaperModel.wallpapers
                        selectedIndex:   wallpaperModel.selectedIndex
                        currentWall:     wallpaperModel.currentWall
                        applying:        wallpaperModel.applying
                        thumbnailWidth:  wallpaperModel.thumbnailWidth
                        thumbnailHeight: wallpaperModel.thumbnailHeight
                        wallpaperDir:    wallpaperModel.wallpaperDir

                        onWallpaperSelected: (index) => {
                            wallpaperModel.selectWallpaper(index)
                        }

                        onApplyRequested: {
                            wallpaperModel.applySelectedWallpaper()
                            wallpaperCarousel.forceActiveFocus()
                        }

                        onEscapeRequested: {
                            Popups.wallpaperOpen = false
                        }
                    }
                }

                WallpaperControls {
                    id: controls

                    Layout.fillWidth: true

                    filename: wallpaperModel.wallpapers.count > 0 &&
                              wallpaperModel.selectedIndex < wallpaperModel.wallpapers.count
                                  ? wallpaperModel.wallpapers.get(
                                        wallpaperModel.selectedIndex
                                    ).sourcePath.split("/").pop()
                                  : "No wallpaper selected"

                    index:     wallpaperModel.selectedIndex
                    count:     wallpaperModel.wallpapers.count

                    applying:  wallpaperModel.applying

                    applied: wallpaperModel.wallpapers.count > 0 &&
                             wallpaperModel.selectedIndex < wallpaperModel.wallpapers.count &&
                             wallpaperModel.wallpapers.get(
                                 wallpaperModel.selectedIndex
                             ).sourcePath === wallpaperModel.currentWall

                    onApplyRequested: {
                        wallpaperModel.applySelectedWallpaper()
                        wallpaperCarousel.forceActiveFocus()
                    }
                }
            }
        }
    }
}

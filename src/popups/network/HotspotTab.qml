import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.src.services
import qs.src.theme

ColumnLayout {
    id: root

    Layout.fillWidth:
        true

    spacing:
        8

    // ── Header ───────────────────────────────────────────────────────────────

    RowLayout {
        Layout.fillWidth:
            true

        Text {
            text:
                "Hotspot"

            font.family:
                Fonts.font

            font.pixelSize:
                14

            font.bold:
                true

            color:
                Colors.on_Surface

            Layout.fillWidth:
                true
        }

        Rectangle {
            width:
                40

            height:
                22

            radius:
                11

            color:
                HotspotService.active
                    ? Colors.primary
                    : Colors.surfaceContainerHighest

            border.width:
                HotspotService.active
                    ? 0
                    : 1

            border.color:
                Colors.outlineVariant

            opacity:
                HotspotService.available
                    ? 1
                    : 0.45

            Rectangle {
                width:
                    16

                height:
                    16

                radius:
                    8

                anchors.verticalCenter:
                    parent.verticalCenter

                x:
                    HotspotService.active
                        ? 21
                        : 3

                color:
                    HotspotService.active
                        ? Colors.on_Primary
                        : Colors.outline

                Behavior on x {
                    NumberAnimation {
                        duration:
                            Theme.hoverFadeDuration

                        easing.type:
                            Easing.OutCubic
                    }
                }
            }

            MouseArea {
                anchors.fill:
                    parent

                enabled:
                    HotspotService.available &&
                    !HotspotService.busy

                cursorShape:
                    Qt.PointingHandCursor

                onClicked: {
                    if (HotspotService.active)
                        HotspotService.stop();
                    else
                        HotspotService.start();
                }
            }
        }
    }

    // ── Status card ──────────────────────────────────────────────────────────

    Rectangle {
        Layout.fillWidth:
            true

        implicitHeight:
            statusColumn.implicitHeight + 20

        radius:
            12

        color:
            HotspotService.active
                ? Colors.primaryContainer
                : Colors.surfaceContainerHigh

        Behavior on color {
            ColorAnimation {
                duration:
                    Theme.hoverFadeDuration
            }
        }

        RowLayout {
            anchors {
                fill:
                    parent

                leftMargin:
                    12

                rightMargin:
                    12

                topMargin:
                    10

                bottomMargin:
                    10
            }

            spacing:
                10

            Text {
                text:
                    "󰀂"

                font.family:
                    Fonts.fontM

                font.pixelSize:
                    22

                color:
                    HotspotService.active
                        ? Colors.on_PrimaryContainer
                        : Colors.outline
            }

            ColumnLayout {
                id:
                    statusColumn

                Layout.fillWidth:
                    true

                spacing:
                    1

                Text {
                    text:
                        HotspotService.active
                            ? "Hotspot active"
                            : "Hotspot disabled"

                    font.family:
                        Fonts.font

                    font.pixelSize:
                        11

                    font.bold:
                        true

                    color:
                        HotspotService.active
                            ? Colors.on_PrimaryContainer
                            : Colors.on_Surface
                }

                Text {
                    text:
                        HotspotService.available
                            ? HotspotService.active
                                ? HotspotService.ssid
                                : "Share this connection over Wi-Fi"
                            : "No Wi-Fi device available"

                    font.family:
                        Fonts.font

                    font.pixelSize:
                        9

                    color:
                        HotspotService.active
                            ? Colors.on_PrimaryContainer
                            : Colors.on_SurfaceVariant

                    elide:
                        Text.ElideRight

                    Layout.fillWidth:
                        true
                }
            }
        }
    }

    // ── Settings ─────────────────────────────────────────────────────────────

    ColumnLayout {
        visible:
            !HotspotService.active

        Layout.fillWidth:
            true

        spacing:
            6

        Text {
            text:
                "Network name"

            font.family:
                Fonts.font

            font.pixelSize:
                10

            font.bold:
                true

            color:
                Colors.on_SurfaceVariant
        }

        TextField {
            id:
                ssidField

            Layout.fillWidth:
                true

            height:
                34

            text:
                HotspotService.ssid

            placeholderText:
                "Hotspot name"

            font.family:
                Fonts.font

            font.pixelSize:
                11

            color:
                Colors.on_Surface

            placeholderTextColor:
                Colors.outline

            background:
                Rectangle {
                    radius:
                        8

                    color:
                        Colors.surfaceContainerHigh

                    border.width:
                        ssidField.activeFocus
                            ? 1
                            : 0

                    border.color:
                        Colors.primary
                }

            onTextChanged:
                HotspotService.ssid = text
        }

        Text {
            text:
                "Password"

            font.family:
                Fonts.font

            font.pixelSize:
                10

            font.bold:
                true

            color:
                Colors.on_SurfaceVariant

            topPadding:
                4
        }

        RowLayout {
            Layout.fillWidth:
                true

            spacing:
                6

            TextField {
                id:
                    passwordField

                Layout.fillWidth:
                    true

                height:
                    34

                text:
                    HotspotService.password

                placeholderText:
                    "At least 8 characters"

                echoMode:
                    TextInput.Password

                font.family:
                    Fonts.font

                font.pixelSize:
                    11

                color:
                    Colors.on_Surface

                placeholderTextColor:
                    Colors.outline

                background:
                    Rectangle {
                        radius:
                            8

                        color:
                            Colors.surfaceContainerHigh

                        border.width:
                            passwordField.activeFocus
                                ? 1
                                : 0

                        border.color:
                            Colors.primary
                    }

                onTextChanged:
                    HotspotService.password = text
            }

            Rectangle {
                width:
                    34

                height:
                    34

                radius:
                    8

                color:
                    regenerateHover.hovered
                        ? Colors.primary
                        : Colors.surfaceContainerHighest

                Behavior on color {
                    ColorAnimation {
                        duration:
                            Theme.hoverFadeDuration
                    }
                }

                HoverHandler {
                    id:
                        regenerateHover
                }

                Text {
                    anchors.centerIn:
                        parent

                    text:
                        "󰑐"

                    font.family:
                        Fonts.fontM

                    font.pixelSize:
                        14

                    color:
                        regenerateHover.hovered
                            ? Colors.on_Primary
                            : Colors.on_Surface
                }

                MouseArea {
                    anchors.fill:
                        parent

                    enabled:
                        !HotspotService.busy

                    cursorShape:
                        Qt.PointingHandCursor

                    onClicked:
                        HotspotService.generatePassword()
                }
            }
        }
    }

    // ── Error ────────────────────────────────────────────────────────────────

    Text {
        visible:
            HotspotService.errorMessage.length > 0

        text:
            HotspotService.errorMessage

        Layout.fillWidth:
            true

        wrapMode:
            Text.Wrap

        font.family:
            Fonts.font

        font.pixelSize:
            9

        color:
            Colors.error

        topPadding:
            2
    }

    // ── Start / Stop ─────────────────────────────────────────────────────────

    Rectangle {
        visible:
            !HotspotService.active

        Layout.fillWidth:
            true

        implicitHeight:
            36

        radius:
            18

        color:
            startHover.hovered
                ? Colors.primaryContainer
                : Colors.primary

        Behavior on color {
            ColorAnimation {
                duration:
                    Theme.hoverFadeDuration
            }
        }

        opacity:
            HotspotService.busy
                ? 0.6
                : 1

        HoverHandler {
            id:
                startHover
        }

        Text {
            anchors.centerIn:
                parent

            text:
                HotspotService.busy
                    ? "Starting…"
                    : "Start Hotspot"

            font.family:
                Fonts.font

            font.pixelSize:
                10

            font.bold:
                true

            color:
                startHover.hovered
                    ? Colors.on_PrimaryContainer
                    : Colors.on_Primary
        }

        MouseArea {
            anchors.fill:
                parent

            enabled:
                HotspotService.available &&
                !HotspotService.busy

            cursorShape:
                Qt.PointingHandCursor

            onClicked:
                HotspotService.start()
        }
    }

    Rectangle {
        visible:
            HotspotService.active

        Layout.fillWidth:
            true

        implicitHeight:
            36

        radius:
            18

        color:
            stopHover.hovered
                ? Colors.errorContainer
                : Colors.surfaceContainerHighest

        Behavior on color {
            ColorAnimation {
                duration:
                    Theme.hoverFadeDuration
            }
        }

        HoverHandler {
            id:
                stopHover
        }

        Text {
            anchors.centerIn:
                parent

            text:
                HotspotService.busy
                    ? "Stopping…"
                    : "Stop Hotspot"

            font.family:
                Fonts.font

            font.pixelSize:
                10

            font.bold:
                true

            color:
                stopHover.hovered
                    ? Colors.on_ErrorContainer
                    : Colors.on_Surface
        }

        MouseArea {
            anchors.fill:
                parent

            enabled:
                !HotspotService.busy

            cursorShape:
                Qt.PointingHandCursor

            onClicked:
                HotspotService.stop()
        }
    }
}

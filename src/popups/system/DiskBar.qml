import QtQuick
import QtQuick.Layouts
import qs.src.theme

Item {
    id: root

    property string label:      "/"
    property string mountPoint: "/"
    property string fsType:     ""
    property real   usedBytes:  0
    property real   totalBytes: 1
    property real   freeBytes:  1

    readonly property real fraction: totalBytes > 0 ? Math.max(0, Math.min(usedBytes / totalBytes, 1)) : 0

    function formatSize(bytes) {
        if (bytes >= 1e12) return (bytes / 1e12).toFixed(1) + " TB"
        if (bytes >= 1e9)  return (bytes / 1e9).toFixed(1)  + " GB"
        if (bytes >= 1e6)  return (bytes / 1e6).toFixed(1)  + " MB"
        return bytes.toFixed(0) + " B"
    }

    implicitHeight: 36

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        RowLayout {
            Layout.fillWidth: true

            Text {
                text:           root.label
                color:          Colors.on_SurfaceVariant
                font.pixelSize: 11
                font.family:    Fonts.font
                Layout.fillWidth: true
                elide:          Text.ElideRight
            }

            Text {
                text:           Math.round(root.fraction * 100) + "%"
                color:          root.fraction >= 0.9
                                    ? Colors.error
                                    : root.fraction >= 0.7
                                        ? Colors.tertiary
                                        : Colors.on_Surface
                font.pixelSize: 11
                font.bold:      true
                font.family:    Fonts.font
            }

            Text {
                text:           root.formatSize(root.usedBytes) + " / " + root.formatSize(root.totalBytes)
                color:          Colors.on_Surface
                font.pixelSize: 11
                font.bold:      true
                font.family:    Fonts.font
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height:  6
            radius:  3
            color:   Colors.surfaceContainerHighest

            Rectangle {
                width:  parent.width * root.fraction
                height: parent.height
                radius: parent.radius
                color:  root.fraction >= 0.9
                            ? Colors.error
                            : root.fraction >= 0.7
                                ? Colors.tertiary
                                : Colors.primary

                Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation  { duration: 250 } }
            }
        }
    }
}

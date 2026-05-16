import QtQuick
import QtQuick.Layouts
import qs.src.theme

Item {
    id: root

    property real   value: 0.0
    property string label: ""
    property color  color: Colors.primary

    implicitWidth:  100
    implicitHeight: 100

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx        = getContext("2d")
            const cx         = width  / 2
            const cy         = height / 2 + 10
            const radius     = Math.min(width, height) / 2 - 10
            const startAngle = 150 * Math.PI / 180
            const endAngle   = 390 * Math.PI / 180
            const valueAngle = startAngle + (endAngle - startAngle) * Math.min(root._animValue, 1.0)

            ctx.clearRect(0, 0, width, height)

            ctx.beginPath()
            ctx.arc(cx, cy, radius, startAngle, endAngle)
            ctx.strokeStyle = Qt.rgba(
                Colors.outlineVariant.r,
                Colors.outlineVariant.g,
                Colors.outlineVariant.b, 0.4)
            ctx.lineWidth = 8
            ctx.lineCap   = "round"
            ctx.stroke()

            if (root._animValue > 0) {
                ctx.beginPath()
                ctx.arc(cx, cy, radius, startAngle, valueAngle)
                ctx.strokeStyle = root.color
                ctx.lineWidth   = 8
                ctx.lineCap     = "round"
                ctx.stroke()
            }

            const ticks = [0.25, 0.5, 0.75]
            ticks.forEach(t => {
                const angle = startAngle + (endAngle - startAngle) * t
                const inner = radius - 12
                const outer = radius - 6
                ctx.beginPath()
                ctx.moveTo(cx + inner * Math.cos(angle), cy + inner * Math.sin(angle))
                ctx.lineTo(cx + outer * Math.cos(angle), cy + outer * Math.sin(angle))
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.2)
                ctx.lineWidth   = 1.5
                ctx.stroke()
            })
        }
    }

    property real _animValue: 0.0

    onValueChanged: _animValue = value

    Behavior on _animValue {
        NumberAnimation {
            duration:    800
            easing.type: Easing.OutCubic
            onRunningChanged: {
                if (running) canvas.requestPaint()
            }
        }
    }

    ColumnLayout {
        anchors.centerIn:            parent
        anchors.verticalCenterOffset: 8
        spacing: 0

        Text {
            Layout.alignment: Qt.AlignHCenter
            text:           Math.round(root._animValue * 100) + "%"
            color:          root.color
            font.pixelSize: 16
            font.bold:      true
            font.family:    Fonts.font
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text:           root.label
            color:          Colors.on_SurfaceVariant
            font.pixelSize: 10
            font.family:    Fonts.font
        }
    }
}

import QtQuick
import qs.src.theme

Canvas {
    id: root

    property var upHistory:   []
    property var downHistory: []
    property real slideOffset: 0.0

    NumberAnimation {
        id: slideAnim
        target: root
        property: "slideOffset"
        from: 1.0
        to: 0.0
        duration: 900
        easing.type: Easing.OutCubic
    }

    onUpHistoryChanged: {
        slideAnim.restart()
        requestPaint()
    }

    onDownHistoryChanged: requestPaint()
    onSlideOffsetChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        const allVals = (root.upHistory || []).concat(root.downHistory || [])
        const maxVal = Math.max(...allVals, 1024)
        const count = Math.max(root.upHistory.length, root.downHistory.length)
        const step = width / Math.max(count - 1, 1)

        ctx.strokeStyle = Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.35)
        ctx.lineWidth = 1

        for (let i = 1; i < 4; i++) {
            const y = Math.round((height / 4) * i) + 0.5
            ctx.beginPath()
            ctx.moveTo(0, y)
            ctx.lineTo(width, y)
            ctx.stroke()
        }

        if (count < 2) return

        ctx.save()
        ctx.beginPath()
        ctx.rect(0, 0, width, height)
        ctx.clip()
        ctx.translate(slideOffset * step, 0)

        function drawLine(history, color) {
            if (!history || history.length < 2) return

            const points = history.map((value, index) => ({
                x: index * step,
                y: height - (value / maxVal) * height * 0.86 - 2
            }))

            ctx.beginPath()
            ctx.moveTo(points[0].x, points[0].y)

            for (let i = 0; i < points.length - 1; i++) {
                const p1 = points[i]
                const p2 = points[i + 1]
                const midX = (p1.x + p2.x) / 2
                const midY = (p1.y + p2.y) / 2

                if (i === points.length - 2)
                    ctx.quadraticCurveTo(p1.x, p1.y, p2.x, p2.y)
                else
                    ctx.quadraticCurveTo(p1.x, p1.y, midX, midY)
            }

            ctx.strokeStyle = color
            ctx.lineWidth = 2
            ctx.lineJoin = "round"
            ctx.stroke()

            ctx.lineTo(points[points.length - 1].x, height)
            ctx.lineTo(points[0].x, height)
            ctx.closePath()
            ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, 0.12)
            ctx.fill()
        }

        drawLine(root.upHistory, Colors.tertiary)
        drawLine(root.downHistory, Colors.primary)
        ctx.restore()
    }
}

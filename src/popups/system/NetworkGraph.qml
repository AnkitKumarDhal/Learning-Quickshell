import QtQuick
import qs.src.theme

Canvas {
    id: root

    property var upHistory:   []
    property var downHistory: []
    property real slideOffset: 0.0

    // Drives the fluid 60FPS scrolling to match the 1000ms data polling
    NumberAnimation {
        id: slideAnim
        target: root
        property: "slideOffset"
        from: 1.0
        to: 0.0
        duration: 1000 
    }

    onUpHistoryChanged: slideAnim.restart()
    onSlideOffsetChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        if (!root.upHistory || !root.downHistory ||
            root.upHistory.length < 2 || root.downHistory.length < 2) return

        const allVals = root.upHistory.concat(root.downHistory)
        const maxVal  = Math.max(...allVals, 1024) 

        // 1. Save state and create a clipping mask so the graph doesn't bleed out
        ctx.save()
        ctx.beginPath()
        ctx.rect(0, 0, width, height)
        ctx.clip()

        // 2. Translate the canvas horizontally to animate the scroll
        const step = width / Math.max(root.upHistory.length - 2, 1)
        ctx.translate(slideOffset * step, 0)

        function drawLine(history, color) {
            ctx.beginPath()
            ctx.strokeStyle = color
            ctx.lineWidth   = 2.0
            ctx.lineJoin    = "round"

            // Shift initial X coordinate to the left by 1 step (-1) to hide data popping in
            const points = history.map((v, i) => ({
                x: (i - 1) * step, 
                y: height - (v / maxVal) * height * 0.85 
            }))

            ctx.moveTo(points[0].x, points[0].y)

            for (let i = 0; i < points.length - 1; i++) {
                const p1 = points[i]
                const p2 = points[i + 1]
                const midX = (p1.x + p2.x) / 2
                const midY = (p1.y + p2.y) / 2

                if (i === points.length - 2) {
                    ctx.quadraticCurveTo(p1.x, p1.y, p2.x, p2.y)
                } else {
                    ctx.quadraticCurveTo(p1.x, p1.y, midX, midY)
                }
            }
            ctx.stroke()

            // Fill under line safely using Qt.rgba
            ctx.lineTo(points[points.length - 1].x, height)
            ctx.lineTo(points[0].x, height)
            ctx.closePath()
            ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, 0.2)
            ctx.fill()
        }

        drawLine(root.upHistory, Colors.tertiary)
        drawLine(root.downHistory, Colors.primary)

        // 3. Restore state so the legend doesn't scroll or get clipped
        ctx.restore()
        const drawRoundedRect = (x, y, w, h, r) => {
            ctx.beginPath()
            ctx.moveTo(x + r, y)
            ctx.lineTo(x + w - r, y)
            ctx.quadraticCurveTo(x + w, y, x + w, y + r)
            ctx.lineTo(x + w, y + h - r)
            ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
            ctx.lineTo(x + r, y + h)
            ctx.quadraticCurveTo(x, y + h, x, y + h - r)
            ctx.lineTo(x, y + r)
            ctx.quadraticCurveTo(x, y, x + r, y)
            ctx.closePath()
        }
        // 4. Draw a highly visible static legend card on top
        ctx.fillStyle = Qt.rgba(Colors.surfaceContainerHighest.r, Colors.surfaceContainerHighest.g, Colors.surfaceContainerHighest.b, 0.9)
        ctx.beginPath()
        drawRoundedRect(8, 8, 76, 44, 8)
        ctx.fill()
        
        ctx.strokeStyle = Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.5)
        ctx.lineWidth = 1
        ctx.stroke()

        ctx.font = "bold 11px '" + Fonts.font + "'"
        
        // Up label
        ctx.fillStyle = Colors.tertiary
        ctx.beginPath()
        ctx.arc(20, 20, 4, 0, 2 * Math.PI)
        ctx.fill()
        ctx.fillStyle = Colors.on_Surface
        ctx.fillText("Up", 32, 24)

        // Down label
        ctx.fillStyle = Colors.primary
        ctx.beginPath()
        ctx.arc(20, 36, 4, 0, 2 * Math.PI)
        ctx.fill()
        ctx.fillStyle = Colors.on_Surface
        ctx.fillText("Down", 32, 40)
    }
}

import QtQuick
import qs.src.theme

// Scrolling line graph for network up/down rates
// upHistory and downHistory are arrays of raw byte/s values, newest last
// Max 60 samples (1 per second)

Canvas {
    id: root

    property var upHistory:   []
    property var downHistory: []

    onUpHistoryChanged:   requestPaint()
    onDownHistoryChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        if (!root.upHistory || !root.downHistory ||
        root.upHistory.length < 2 || root.downHistory.length < 2) return
        if (root.upHistory.length < 2 && root.downHistory.length < 2) return

        const allVals = root.upHistory.concat(root.downHistory)
        const maxVal  = Math.max(...allVals, 1024)  // min 1KB so graph never flatlines

        function drawLine(history, color) {
            if (history.length < 2) return
            const step = width / (history.length - 1)

            ctx.beginPath()
            ctx.strokeStyle = color
            ctx.lineWidth   = 1.5
            ctx.lineJoin    = "round"

            history.forEach((v, i) => {
                const x = i * step
                const y = height - (v / maxVal) * height * 0.85  // 85% max so line doesn't clip top
                i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y)
            })
            ctx.stroke()

            // Fill under line
            ctx.lineTo(width, height)
            ctx.lineTo(0, height)
            ctx.closePath()
            ctx.fillStyle = color.toString().replace(")", ", 0.1)").replace("rgb", "rgba")
            ctx.fill()
        }

        drawLine(root.upHistory,   Colors.tertiary.toString())
        drawLine(root.downHistory, Colors.primary.toString())

        // Legend
        ctx.font         = "10px '" + Fonts.font + "'"
        ctx.fillStyle    = Colors.tertiary.toString()
        ctx.fillText("↑ Up", 4, 12)
        ctx.fillStyle    = Colors.primary.toString()
        ctx.fillText("↓ Down", 4, 24)
    }
}

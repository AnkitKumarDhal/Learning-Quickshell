import QtQuick
import Quickshell.Io

QtObject {
    id: root

    signal loaded(var apps)
    signal failed()

    property bool   loading: false
    property string _buf:    ""

    readonly property string scriptPath:
        Qt.resolvedUrl("resolve_apps.py").toString().slice(7)

    function reload() {
        if (loading) return  // already loading, don't restart
        _buf    = ""
        loading = true
        loaderProc.running = true
    }

    property Process loaderProc: Process {
        command: ["python3", root.scriptPath]
        running: false

        stdout: SplitParser {
            onRead: (line) => { root._buf += line }
        }

        stderr: SplitParser {
            onRead: (line) => { console.warn("[resolve_apps]", line) }
        }

        onExited: (code, status) => {
            root.loading = false
            if (code !== 0) {
                console.warn("[resolve_apps] exited with code", code)
                root.failed()
                return
            }
            try {
                root.loaded(JSON.parse(root._buf))
            } catch(e) {
                console.warn("[resolve_apps] JSON parse failed:", e, root._buf.slice(0, 120))
                root.failed()
            }
        }
    }
}

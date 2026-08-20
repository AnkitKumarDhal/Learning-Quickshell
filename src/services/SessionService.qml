pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool busy: false

    Process {
        id: actionProcess

        command: []

        onExited: (exitCode, exitStatus) => {
            root.busy = false

            if (exitCode !== 0) {
                console.warn(
                    "SessionService: command exited with code",
                    exitCode
                )
            }
        }
    }

    function perform(action) {
        if (root.busy)
            return

        let command = []

        switch (action) {
        case "lock":
            command = ["hyprlock"]
            break

        case "logout":
            command = ["hyprctl", "dispatch", "hl.dsp.exit()"]
            break

        case "suspend":
            command = ["systemctl", "suspend"]
            break

        case "hibernate":
            command = ["systemctl", "hibernate"]
            break

        case "reboot":
            command = ["systemctl", "reboot"]
            break

        case "poweroff":
            command = ["systemctl", "poweroff"]
            break

        default:
            console.warn("SessionService: unknown action:", action)
            return
        }

        actionProcess.command = command
        root.busy = true
        actionProcess.running = true
    }
}

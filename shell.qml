import QtQuick
import Quickshell
import qs.src.windows

ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Component {
            Scope {
                required property var modelData
                TopBar { screen: modelData }
            }
        }
    }
}

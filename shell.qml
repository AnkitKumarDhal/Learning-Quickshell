import QtQuick
import Quickshell
import "components/bar"

Scope {
    id: shellRoot
    Variants {
        model: Quickshell.screens
        delegate: Component {
            Bar {
                required property var modelData
                screen: modelData
            }
        }
    }
}

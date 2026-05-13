import QtQuick
import Quickshell
import "services"
import "components/bar"
import "components/bar/notification"

ShellRoot {
    id: shellRoot

    NotificationService {
        id: notifService
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            Scope {
                required property var modelData

                Bar {screen: modelData}
                NotificationPanel {screen: modelData}
                NotificationToast {screen: modelData}
            }
        }
    }
}

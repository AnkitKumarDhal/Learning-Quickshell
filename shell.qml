import QtQuick
import Quickshell
import "components/bar"
import "components/bar/notification"
import "services"

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

                Bar {
                    screen: modelData
                }

                NotificationPanel {
                    screen: modelData
                }

                NotificationToast {
                    screen: modelData
                }

            }

        }

    }

}

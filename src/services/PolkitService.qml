pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

Singleton {
    id: root

    PolkitAgent {
        id: agent
    }

    readonly property bool    active:                agent.isActive
    readonly property bool    registered:            agent.isRegistered
    readonly property var     flow:                  agent.flow

    readonly property string  message:               flow ? flow.message : ""
    readonly property string  supplementaryMessage:  flow ? flow.supplementaryMessage : ""
    readonly property bool    supplementaryIsError:  flow ? flow.supplementaryIsError : false
    readonly property string  inputPrompt:           flow ? flow.inputPrompt : ""
    readonly property bool    responseVisible:       flow ? flow.responseVisible : false
    readonly property bool    responseRequired:      flow ? flow.isResponseRequired : false
    readonly property bool    failed:                flow ? flow.failed : false
    readonly property string  iconName:              flow ? flow.iconName : ""
    readonly property var     identities:            flow ? flow.identities : []

    property var              selectedIdentity:      flow ? flow.selectedIdentity : null

    function submit(value) {
        if (!flow || !flow.isResponseRequired) {
            return
        }

        flow.submit(value)
    }

    function cancel() {
        if (!flow)
            return

        flow.cancelAuthenticationRequest()
    }
Connections {
    target: agent

    function onFlowChanged() {
        console.log("Polkit flow changed:", agent.flow)
        console.log("Polkit active:", agent.isActive)

        if (agent.flow) {
            console.log("Message:", agent.flow.message)
            console.log("Supplementary:", agent.flow.supplementaryMessage)
            console.log("Prompt:", agent.flow.inputPrompt)
            console.log("Response required:", agent.flow.isResponseRequired)
            console.log("Response visible:", agent.flow.responseVisible)
        }
    }
}}

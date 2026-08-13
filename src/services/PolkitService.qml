pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

Singleton {
    id: root

    PolkitAgent {
        id: agent
    }

    // ── Agent state ──────────────────────────────────────────────────────────

    readonly property bool registered: agent.isRegistered
    readonly property bool active: agent.isActive
    readonly property var flow: agent.flow

    // ── Current request presentation state ───────────────────────────────────

    property string message: ""
    property string supplementaryMessage: ""
    property bool supplementaryIsError: false

    property string inputPrompt: ""
    property bool responseVisible: false
    property bool responseRequired: false

    property string iconName: ""
    property bool failed: false

    property var identities: []
    property var selectedIdentity: null

    // ── Synchronize UI state from the current AuthFlow ────────────────────────

    function syncFromFlow() {
        const current = agent.flow

        if (!current)
            return

        root.message = current.message
        root.supplementaryMessage = current.supplementaryMessage
        root.supplementaryIsError = current.supplementaryIsError

        root.inputPrompt = current.inputPrompt
        root.responseVisible = current.responseVisible
        root.responseRequired = current.isResponseRequired

        root.iconName = current.iconName
        root.failed = current.failed

        root.identities = current.identities
        root.selectedIdentity = current.selectedIdentity
    }

    // ── Authentication request lifecycle ─────────────────────────────────────

    Connections {
        target: agent

        function onAuthenticationRequestStarted() {
            root.syncFromFlow()
        }

        function onFlowChanged() {
            if (agent.flow)
                root.syncFromFlow()
        }
    }

    // ── Authentication conversation ──────────────────────────────────────────

    Connections {
        target: agent.flow

        function onIsResponseRequiredChanged() {
            root.syncFromFlow()
        }

        function onInputPromptChanged() {
            root.syncFromFlow()
        }

        function onResponseVisibleChanged() {
            root.syncFromFlow()
        }

        function onSupplementaryMessageChanged() {
            root.syncFromFlow()
        }

        function onSupplementaryIsErrorChanged() {
            root.syncFromFlow()
        }

        function onAuthenticationFailed() {
            root.syncFromFlow()
        }
    }

    // ── User actions ─────────────────────────────────────────────────────────

    function submit(value) {
        const current = agent.flow

        if (!current || !current.isResponseRequired)
            return

        current.submit(value)
    }

    function cancel() {
        const current = agent.flow

        if (!current)
            return

        current.cancelAuthenticationRequest()
    }

    // ── Clear visual state after the popup has finished closing ───────────────

    function clearPresentation() {
        root.message = ""
        root.supplementaryMessage = ""
        root.supplementaryIsError = false

        root.inputPrompt = ""
        root.responseVisible = false
        root.responseRequired = false

        root.iconName = ""
        root.failed = false

        root.identities = []
        root.selectedIdentity = null
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property var _lastActive: null

    readonly property var currentlyPlaying: {
        for (let i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing) return players[i]
        }

        return null
    }

    readonly property var activePlayer: {
        if (players.length === 0) return null
        if (currentlyPlaying) return currentlyPlaying
        if (_lastActive) {
            for (let i = 0; i < players.length; i++) {
                if (players[i] === _lastActive) return _lastActive
            }
        }

        return players[0]
    }

    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing ?? false
    readonly property bool hasArt: activePlayer !== null && activePlayer.trackArtUrl !== ""
    readonly property string playerIdentity: activePlayer?.identity || "Unknown Player"

    onCurrentlyPlayingChanged: {
        if (currentlyPlaying)
            _lastActive = currentlyPlaying
    }
}

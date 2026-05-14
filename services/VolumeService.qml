pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root
    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    } 

    property var sink: Pipewire.defaultAudioSink
    property var audio: sink ? sink.audio : null
    property real volume: audio ? audio.volume : 0.0
    property bool muted: audio ? audio.muted : false

    function toggleMute() {
        if (audio) {
            audio.muted = !audio.muted
        }
    }

    function changeVolume(step) {
        if (audio) {
            let newVol = audio.volume + step
            audio.volume = Math.max(0.0, Math.min(1.0, newVol))
        }
    }
}

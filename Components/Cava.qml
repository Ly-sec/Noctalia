import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Scope {
    id: root
    property int count: 32
    property int noiseReduction: 60
    property string channels: "mono"
    property string monoOption: "average"

    property var config: ({
            general: {
                bars: count,
                framerate: 30,
                autosens: 1
            },
            smoothing: {
                monstercat: 1,
                gravity: 1000000,
                noise_reduction: noiseReduction
            },
            output: {
                method: "raw",
                bit_format: 8,
                channels: channels,
                mono_option: monoOption
            }
        })

    property var values: Array(count).fill(0)

    Process {
        id: process
        property int index: 0
        stdinEnabled: true
        running: MusicManager.isPlaying
        command: ["cava", "-p", "/dev/stdin"]
        onExited: {
            stdinEnabled = true;
            index = 0;
            values = Array(count).fill(0);
        }
        onStarted: {
            for (const k in config) {
                if (typeof config[k] !== "object") {
                    write(k + "=" + config[k] + "\n");
                    continue;
                }
                write("[" + k + "]\n");
                const obj = config[k];
                for (const k2 in obj) {
                    write(k2 + "=" + obj[k2] + "\n");
                }
            }
            stdinEnabled = false;
        }
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                const newValues = Array(count).fill(0);
                for (let i = 0; i < values.length; i++) {
                    newValues[i] = values[i];
                }
                if (process.index + data.length > count) {
                    process.index = 0;
                }
                for (let i = 0; i < data.length; i += 1) {
                    newValues[process.index] = Math.min(data.charCodeAt(i), 128) / 128;
                    process.index = (process.index+1) % count;
                }
                values = newValues;
            }
        }
    }
}

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications
import QtQuick
import QtCore
import qs.Bar
import qs.Bar.Modules
import qs.Widgets
import qs.Widgets.LockScreen
import qs.Widgets.Notification
import qs.Settings
import qs.Helpers

import "./Helpers/IdleInhibitor.qml"
import "./Helpers/IPCHandlers.qml"

Scope {
    id: root

    property alias appLauncherPanel: appLauncherPanel
    property var notificationHistoryWin: notificationHistoryWin
    property bool pendingReload: false

    // Helper function to round value to nearest step
    function roundToStep(value, step) {
        return Math.round(value / step) * step;
    }

    // Volume property reflecting current audio volume in 0-100
    // Will be kept in sync dynamically below
    property int volume: (defaultAudioSink && defaultAudioSink.audio && !defaultAudioSink.audio.muted)
                        ? Math.round(defaultAudioSink.audio.volume * 100)
                        : 0

    // Function to update volume with clamping, stepping, and applying to audio sink
    function updateVolume(vol) {
        var clamped = Math.max(0, Math.min(100, vol));
        var stepped = roundToStep(clamped, 5);
        if (defaultAudioSink && defaultAudioSink.audio) {
            defaultAudioSink.audio.volume = stepped / 100;
        }
        volume = stepped;
    }

    Component.onCompleted: {
        Quickshell.shell = root;
    }

    Bar {
        id: bar
        shell: root
        property var notificationHistoryWin: notificationHistoryWin
    }

    Dock {
        id: dock
    }

    Applauncher {
        id: appLauncherPanel
        visible: false
    }

    LockScreen {
        id: lockScreen
        onLockedChanged: {
            if (!locked && root.pendingReload) {
                reloadTimer.restart();
                root.pendingReload = false;
            }
        }
    }

    IdleInhibitor {
        id: idleInhibitor
    }

    NotificationServer {
        id: notificationServer
        onNotification: function (notification) {
            console.log("Notification received:", notification.appName);
            notification.tracked = true;
            if (notificationPopup.notificationsVisible) {
                notificationPopup.addNotification(notification);
            }
            if (notificationHistoryWin) {
                notificationHistoryWin.addToHistory({
                    id: notification.id,
                    appName: notification.appName || "Notification",
                    summary: notification.summary || "",
                    body: notification.body || "",
                    urgency: notification.urgency,
                    timestamp: Date.now()
                });
            }
        }
    }

    NotificationPopup {
        id: notificationPopup
        barVisible: bar.visible
    }

    NotificationHistory {
        id: notificationHistoryWin
    }

    // Reference to the default audio sink from Pipewire
    property var defaultAudioSink: Pipewire.defaultAudioSink

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    IPCHandlers {
        appLauncherPanel: appLauncherPanel
        lockScreen: lockScreen
        idleInhibitor: idleInhibitor
        notificationPopup: notificationPopup
    }

    Connections {
        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup();
        }

        function onReloadFailed() {
            Quickshell.inhibitReloadPopup();
        }

        target: Quickshell
    }

    Timer {
        id: reloadTimer
        interval: 500 // ms
        repeat: false
        onTriggered: Quickshell.reload(true)
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (lockScreen.locked) {
                pendingReload = true;
            } else {
                reloadTimer.restart();
            }
        }
    }

    // --- NEW: Keep volume property in sync with actual Pipewire audio sink volume ---

    Connections {
        target: defaultAudioSink ? defaultAudioSink.audio : null
        function onVolumeChanged() {
            if (defaultAudioSink.audio && !defaultAudioSink.audio.muted) {
                volume = Math.round(defaultAudioSink.audio.volume * 100);
                console.log("Volume changed externally to:", volume);
            }
        }
        function onMutedChanged() {
            if (defaultAudioSink.audio) {
                if (defaultAudioSink.audio.muted) {
                    volume = 0;
                    console.log("Audio muted, volume set to 0");
                } else {
                    volume = Math.round(defaultAudioSink.audio.volume * 100);
                    console.log("Audio unmuted, volume restored to:", volume);
                }
            }
        }
    }
}

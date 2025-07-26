import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications
import QtQuick
import QtCore
import qs.Bar
import qs.Bar.Modules
import qs.Widgets
import qs.Widgets.Notification
import qs.Settings
import qs.Helpers

Scope {
    id: root

    property alias appLauncherPanel: appLauncherPanel
    property var notificationHistoryWin: notificationHistoryWin
    property bool pendingReload: false

    function updateVolume(vol) {
        volume = vol;
        if (defaultAudioSink && defaultAudioSink.audio) {
            defaultAudioSink.audio.volume = vol / 100;
        }
    }

    Component.onCompleted: {
        Quickshell.shell = root;
    }

    Bar {
        id: bar
        shell: root
        property var notificationHistoryWin: notificationHistoryWin
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

    NotificationServer {
        id: notificationServer
        onNotification: function (notification) {
            console.log("Notification received:", notification.appName);
            notification.tracked = true;
            notificationPopup.addNotification(notification);
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

    // Notification History Window
    NotificationHistory {
        id: notificationHistoryWin
    }

    property var defaultAudioSink: Pipewire.defaultAudioSink
    property int volume: defaultAudioSink && defaultAudioSink.audio && defaultAudioSink.audio.volume && !defaultAudioSink.audio.muted ? Math.round(defaultAudioSink.audio.volume * 100) : 0

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    IPCHandlers {
        appLauncherPanel: appLauncherPanel
        lockScreen: lockScreen
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
}

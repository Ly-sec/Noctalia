pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services

Singleton {
  id: root

  // Define our app directories
  // Default config directory: ~/.config/noctalia
  // Default cache directory: ~/.cache/noctalia
  property string shellName: "noctalia"
  property string configDir: Quickshell.env("NOCTALIA_CONFIG_DIR") || (Quickshell.env("XDG_CONFIG_HOME")
                                                                       || Quickshell.env(
                                                                         "HOME") + "/.config") + "/" + shellName + "/"
  property string cacheDir: Quickshell.env("NOCTALIA_CACHE_DIR") || (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env(
                                                                       "HOME") + "/.cache") + "/" + shellName + "/"
  property string cacheDirImages: cacheDir + "images/"

  property string settingsFile: Quickshell.env("NOCTALIA_SETTINGS_FILE") || (configDir + "settings.json")

  property string defaultWallpaper: Qt.resolvedUrl("../Assets/Tests/wallpaper.png")
  property string defaultAvatar: Quickshell.env("HOME") + "/.face"

  // Used to access via Settings.data.xxx.yyy
  property alias data: adapter

  // Flag to prevent unnecessary wallpaper calls during reloads
  property bool isInitialLoad: true

  // Function to validate monitor configurations
  function validateMonitorConfigurations() {
    var availableScreenNames = []
    for (var i = 0; i < Quickshell.screens.length; i++) {
      availableScreenNames.push(Quickshell.screens[i].name)
    }

    Logger.log("Settings", "Available monitors: [" + availableScreenNames.join(", ") + "]")
    Logger.log("Settings", "Configured bar monitors: [" + adapter.bar.monitors.join(", ") + "]")

    // Check bar monitors
    if (adapter.bar.monitors.length > 0) {
      var hasValidBarMonitor = false
      for (var j = 0; j < adapter.bar.monitors.length; j++) {
        if (availableScreenNames.includes(adapter.bar.monitors[j])) {
          hasValidBarMonitor = true
          break
        }
      }
      if (!hasValidBarMonitor) {
        Logger.log("Settings",
                   "No configured bar monitors found on system, clearing bar monitor list to show on all screens")
        adapter.bar.monitors = []
      } else {
        Logger.log("Settings", "Found valid bar monitors, keeping configuration")
      }
    } else {
      Logger.log("Settings", "Bar monitor list is empty, will show on all available screens")
    }
  }
  Item {
    Component.onCompleted: {

      // ensure settings dir exists
      Quickshell.execDetached(["mkdir", "-p", configDir])
      Quickshell.execDetached(["mkdir", "-p", cacheDir])
      Quickshell.execDetached(["mkdir", "-p", cacheDirImages])
    }
  }

  // Don't write settings to disk immediately
  // This avoid excessive IO when a variable changes rapidly (ex: sliders)
  Timer {
    id: saveTimer
    running: false
    interval: 1000
    onTriggered: settingsFileView.writeAdapter()
  }

  FileView {
    id: settingsFileView
    path: settingsFile
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: saveTimer.start()
    Component.onCompleted: function () {
      reload()
    }
    onLoaded: function () {
      Qt.callLater(function () {
        if (isInitialLoad) {
          Logger.log("Settings", "OnLoaded")
          // Only set wallpaper on initial load, not on reloads
          if (adapter.wallpaper.current !== "") {
            Logger.log("Settings", "Set current wallpaper", adapter.wallpaper.current)
            WallpaperService.setCurrentWallpaper(adapter.wallpaper.current, true)
          }

          // Validate monitor configurations, only once
          // if none of the configured monitors exist, clear the lists
          validateMonitorConfigurations()
        }

        isInitialLoad = false
      })
    }
    onLoadFailed: function (error) {
      if (error.toString().includes("No such file") || error === 2)
        // File doesn't exist, create it with default values
        writeAdapter()
    }

    JsonAdapter {
      id: adapter

      // bar
      property JsonObject bar: JsonObject {
        property string position: "top" // Possible values: "top", "bottom"
        property bool showActiveWindowIcon: true
        property bool alwaysShowBatteryPercentage: false
        property real backgroundOpacity: 1.0
        property bool showWorkspaceNames: false
        property list<string> monitors: []

        // Widget configuration for modular bar system
        property JsonObject widgets
        widgets: JsonObject {
          property list<string> left: ["SystemMonitor", "ActiveWindow", "MediaMini"]
          property list<string> center: ["Workspace"]
          property list<string> right: ["ScreenRecorderIndicator", "Tray", "ArchUpdater", "NotificationHistory", "WiFi", "Bluetooth", "Battery", "Volume", "Brightness", "Clock", "SidePanelToggle"]
        }
      }

      // general
      property JsonObject general: JsonObject {
        property string avatarImage: defaultAvatar
        property bool dimDesktop: false
        property bool showScreenCorners: false
        property real radiusRatio: 1.0
      }

      // location
      property JsonObject location: JsonObject {
        property string name: "Tokyo"
        property bool useFahrenheit: false
        property bool reverseDayMonth: false
        property bool use12HourClock: false
        property bool showDateWithClock: false
      }

      // screen recorder
      property JsonObject screenRecorder: JsonObject {
        property string directory: "~/Videos"
        property int frameRate: 60
        property string audioCodec: "opus"
        property string videoCodec: "h264"
        property string quality: "very_high"
        property string colorRange: "limited"
        property bool showCursor: true
        property string audioSource: "default_output"
        property string videoSource: "portal"
      }

      // wallpaper
      property JsonObject wallpaper: JsonObject {
        property string directory: "/usr/share/wallpapers"
        property string current: ""
        property bool isRandom: false
        property int randomInterval: 300
        property JsonObject swww

        onDirectoryChanged: WallpaperService.listWallpapers()
        onIsRandomChanged: WallpaperService.toggleRandomWallpaper()
        onRandomIntervalChanged: WallpaperService.restartRandomWallpaperTimer()

        swww: JsonObject {
          property bool enabled: false
          property string resizeMethod: "crop"
          property int transitionFps: 60
          property string transitionType: "random"
          property real transitionDuration: 1.1
        }
      }

      // applauncher
      property JsonObject appLauncher: JsonObject {
        // When disabled, Launcher hides clipboard command and ignores cliphist
        property bool enableClipboardHistory: true
        // Position: center, top_left, top_right, bottom_left, bottom_right
        property string position: "center"
        property list<string> pinnedExecs: []
      }

      // dock
      property JsonObject dock: JsonObject {
        property bool autoHide: false
        property bool exclusive: false
        property list<string> monitors: []
      }

      // network
      property JsonObject network: JsonObject {
        property bool wifiEnabled: true
        property bool bluetoothEnabled: true
      }

      // notifications
      property JsonObject notifications: JsonObject {
        property list<string> monitors: []
      }

      // audio
      property JsonObject audio: JsonObject {
        property bool showMiniplayerAlbumArt: false
        property bool showMiniplayerCava: false
        property string visualizerType: "linear"
        property int volumeStep: 5
        property int cavaFrameRate: 60
      }

      // ui
      property JsonObject ui: JsonObject {
        property string fontDefault: "Roboto" // Default font for all text
        property string fontFixed: "DejaVu Sans Mono" // Fixed width font for terminal
        property string fontBillboard: "Inter" // Large bold font for clocks and prominent displays

        // Legacy compatibility
        property string fontFamily: fontDefault // Keep for backward compatibility

        // Idle inhibitor state
        property bool idleInhibitorEnabled: false
      }

      // Scaling (not stored inside JsonObject, or it crashes)
      property var monitorsScaling: {

      }

      // brightness
      property JsonObject brightness: JsonObject {
        property int brightnessStep: 5
      }

      property JsonObject colorSchemes: JsonObject {
        property bool useWallpaperColors: false
        property string predefinedScheme: ""
        property bool darkMode: true
        // External app theming (GTK & Qt)
        property bool themeApps: false
      }
    }
  }
}

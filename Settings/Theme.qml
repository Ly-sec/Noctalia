// Theme.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Settings

Singleton {
    id: root

    function applyOpacity(color, opacity) {
        return color.replace("#", "#" + opacity);
    }
    
    // FileView to load theme data from JSON file
    FileView {
        id: themeFile
        path: Settings.settingsDir + "Theme.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: function(error) {
            if (error.includes("No such file")) {
                themeData = {}
                writeAdapter()
            }
        }
        JsonAdapter {
            id: themeData
            
            // Backgrounds
            property string backgroundPrimary: "#0C0D11"
            property string backgroundSecondary: "#151720"
            property string backgroundTertiary: "#1D202B"
            
            // Surfaces & Elevation
            property string surface: "#1A1C26"
            property string surfaceVariant: "#2A2D3A"
            
            // Text Colors
            property string textPrimary: "#CACEE2"
            property string textSecondary: "#B7BBD0"
            property string textDisabled: "#6B718A"
            
            // Accent Colors
            property string accentPrimary: "#A8AEFF"
            property string accentSecondary: "#9EA0FF"
            property string accentTertiary: "#8EABFF"
            
            // Error/Warning
            property string error: "#FF6B81"
            property string warning: "#FFBB66"
            
            // Highlights & Focus
            property string highlight: "#E3C2FF"
            property string rippleEffect: "#F3DEFF"
            
            // Additional Theme Properties
            property string onAccent: "#1A1A1A"
            property string outline: "#44485A"
            
            // Shadows & Overlays
            property string shadow: "#000000"
            property string overlay: "#11121A"
        }
    }
    
    // Backgrounds
    property color backgroundPrimary: themeData.backgroundPrimary
    property color backgroundSecondary: themeData.backgroundSecondary
    property color backgroundTertiary: themeData.backgroundTertiary

    // Surfaces & Elevation
    property color surface: themeData.surface
    property color surfaceVariant: themeData.surfaceVariant

    // Text Colors
    property color textPrimary: themeData.textPrimary
    property color textSecondary: themeData.textSecondary
    property color textDisabled: themeData.textDisabled

    // Accent Colors
    property color accentPrimary: themeData.accentPrimary
    property color accentSecondary: themeData.accentSecondary
    property color accentTertiary: themeData.accentTertiary

    // Error/Warning
    property color error: themeData.error
    property color warning: themeData.warning

    // Highlights & Focus
    property color highlight: themeData.highlight
    property color rippleEffect: themeData.rippleEffect

    // Additional Theme Properties
    property color onAccent: themeData.onAccent
    property color outline: themeData.outline

    // Shadows & Overlays
    property color shadow: themeData.shadow
    property color overlay: themeData.overlay

    // Font Properties
    property string fontFamily: "Roboto"         // Family for all text

    property int fontSizeHeader: 32              // Headers and titles
    property int fontSizeBody: 16                // Body text and general content
    property int fontSizeSmall: 14               // Small text like clock, labels
    property int fontSizeCaption: 12             // Captions and fine print
}


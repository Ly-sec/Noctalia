import QtQuick
import Quickshell
import Quickshell.Io
import qs.Components
import qs.Settings

Item {
    id: brightnessDisplay
    property int brightness: -1
    property int previousBrightness: -1
    property var screen: (typeof modelData !== 'undefined' ? modelData : null)
    property string monitorName: screen ? screen.name : "DP-1"
    property bool isSettingBrightness: false
    property bool hasPendingSet: false
    property int pendingSetValue: -1

    width: pill.width
    height: pill.height
    visible: brightness >= 0
    
    Process {
        id: getBrightnessProcess
        command: [Quickshell.shellDir + "/Programs/zigbrightness", "get", monitorName]
        
        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim()
                const val = parseInt(output)
                
                if (!isNaN(val) && val >= 0 && val !== previousBrightness) {
                    previousBrightness = brightness
                    brightness = val
                    pill.text = brightness + "%"
                    pill.show()
                }
            }
        }
    }
    
    function getBrightness() {
        if (isSettingBrightness) {
            return
        }
        
        getBrightnessProcess.running = true
    }
    
    Process {
        id: setBrightnessProcess
        property int targetValue: -1
        command: [Quickshell.shellDir + "/Programs/zigbrightness", "set", monitorName, targetValue.toString()]
        
        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim()
                const val = parseInt(output)
                
                if (!isNaN(val) && val >= 0) {
                    brightness = val
                    pill.text = brightness + "%"
                    pill.show()
                }
                
                isSettingBrightness = false
                
                if (hasPendingSet) {
                    hasPendingSet = false
                    const pendingValue = pendingSetValue
                    pendingSetValue = -1
                    setBrightness(pendingValue)
                }
            }
        }
    }
    
    function setBrightness(newValue) {
        newValue = Math.max(0, Math.min(100, newValue))
        
        if (isSettingBrightness) {
            hasPendingSet = true
            pendingSetValue = newValue
            return
        }
        
        isSettingBrightness = true
        setBrightnessProcess.targetValue = newValue
        setBrightnessProcess.running = true
    }

    PillIndicator {
        id: pill
        icon: "brightness_high"
        text: brightness >= 0 ? brightness + "%" : "--"
        pillColor: Theme.surfaceVariant
        iconCircleColor: Theme.accentPrimary
        iconTextColor: Theme.backgroundPrimary
        textColor: Theme.textPrimary
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                getBrightness()
                brightnessTooltip.tooltipVisible = true
            }
            onExited: brightnessTooltip.tooltipVisible = false
            
            onWheel: function(wheel) {
                const delta = wheel.angleDelta.y > 0 ? 5 : -5
                const newBrightness = brightness + delta
                setBrightness(newBrightness)
            }
        }
        StyledTooltip {
            id: brightnessTooltip
            text: "Brightness: " + brightness + "%"
            tooltipVisible: false
            targetItem: pill
            delay: 200
        }
    }

    Component.onCompleted: {
        getBrightness()
        if (brightness >= 0) {
            pill.show()
        }
    }
}
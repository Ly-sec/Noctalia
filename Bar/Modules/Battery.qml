import QtQuick
import Quickshell
import Quickshell.Services.UPower
import QtQuick.Layouts
import qs.Components
import qs.Settings

Item {
    id: batteryWidget

    // Test mode
    property bool testMode: false
    property int testPercent: 49
    property bool testCharging: true

    property var battery: UPower.displayDevice
    property bool isReady: testMode ? true : (battery && battery.ready && battery.isLaptopBattery && battery.isPresent)
    property real percent: testMode ? testPercent : (isReady ? (battery.percentage * 100) : 0)
    property bool charging: testMode ? testCharging : (isReady ? battery.state === UPowerDeviceState.Charging : false)
    property bool show: isReady && percent > 0

    // Choose icon based on charge and charging state
    function batteryIcon() {
        if (!show)
            return "";

        if (charging)
            return "battery_android_bolt";

        if (percent >= 95)
           return "battery_android_full";

        // Hardcoded battery symbols
        if (percent >= 85)
            return "battery_android_6";
        if (percent >= 70)
            return "battery_android_5";
        if (percent >= 55)
            return "battery_android_4";
        if (percent >= 40)
            return "battery_android_3";
        if (percent >= 25)
            return "battery_android_2";
        if (percent >= 10)
            return "battery_android_1";
        if (percent >= 0)
            return "battery_android_0";
    }

    visible: testMode || (isReady && battery.isLaptopBattery)
    width: pill.width
    height: pill.height

    PillIndicator {
        id: pill
        icon: batteryWidget.batteryIcon()
        text: Math.round(batteryWidget.percent) + "%"
        pillColor: Theme.surfaceVariant
        iconCircleColor: Theme.accentPrimary
        iconTextColor: Theme.backgroundPrimary
        textColor: charging ? Theme.accentPrimary : Theme.textPrimary
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                pill.showDelayed();
                batteryTooltip.tooltipVisible = true;
            }
            onExited: {
                pill.hide();
                batteryTooltip.tooltipVisible = false;
            }
        }
        StyledTooltip {
            id: batteryTooltip
            positionAbove: false
            text: {
                let lines = [];
                if (batteryWidget.isReady) {
                    lines.push(batteryWidget.charging ? "Charging" : "Discharging");
                    lines.push(Math.round(batteryWidget.percent) + "%");
                    if (batteryWidget.battery.changeRate !== undefined)
                        lines.push("Rate: " + batteryWidget.battery.changeRate.toFixed(2) + " W");
                    if (batteryWidget.battery.timeToEmpty > 0)
                        lines.push("Time left: " + Math.floor(batteryWidget.battery.timeToEmpty / 60) + " min");
                    if (batteryWidget.battery.timeToFull > 0)
                        lines.push("Time to full: " + Math.floor(batteryWidget.battery.timeToFull / 60) + " min");
                    if (batteryWidget.battery.healthPercentage !== undefined)
                        lines.push("Health: " + Math.round(batteryWidget.battery.healthPercentage) + "%");
                }
                return lines.join("\n");
            }
            tooltipVisible: false
            targetItem: pill
            delay: 1500
        }
    }
}

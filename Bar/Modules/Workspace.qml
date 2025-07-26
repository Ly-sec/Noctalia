import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.Settings
import qs.Services

Item {
    id: root
    required property ShellScreen screen
    property bool isDestroying: false
    property bool hovered: false

    signal workspaceChanged(int workspaceId, color accentColor)

    property ListModel localWorkspaces: ListModel {}
    property real masterProgress: 0.0
    property bool effectsActive: false
    property color effectColor: Theme.accentPrimary

    property int horizontalPadding: 16
    property int spacingBetweenPills: 8

    width: {
        let total = 0;
        for (let i = 0; i < localWorkspaces.count; i++) {
            const ws = localWorkspaces.get(i);
            if (ws.isFocused)
                total += 44;
            else if (ws.isActive)
                total += 28;
            else
                total += 16;
        }
        total += Math.max(localWorkspaces.count - 1, 0) * spacingBetweenPills;
        total += horizontalPadding * 2;
        return total;
    }

    height: 36

    Component.onCompleted: {
        localWorkspaces.clear();
        for (let i = 0; i < WorkspaceManager.workspaces.count; i++) {
            const ws = WorkspaceManager.workspaces.get(i);
            if (ws.output.toLowerCase() === screen.name.toLowerCase()) {
                localWorkspaces.append(ws);
            }
        }
        workspaceRepeater.model = localWorkspaces;
        updateWorkspaceFocus();
    }

    Connections {
        target: WorkspaceManager
        function onWorkspacesChanged() {
            localWorkspaces.clear();
            for (let i = 0; i < WorkspaceManager.workspaces.count; i++) {
                const ws = WorkspaceManager.workspaces.get(i);
                if (ws.output.toLowerCase() === screen.name.toLowerCase()) {
                    localWorkspaces.append(ws);
                }
            }

            workspaceRepeater.model = localWorkspaces;
            updateWorkspaceFocus();
        }
    }

    function triggerUnifiedWave() {
        effectColor = Theme.accentPrimary;
        masterAnimation.restart();
    }

    SequentialAnimation {
        id: masterAnimation
        PropertyAction {
            target: root
            property: "effectsActive"
            value: true
        }
        NumberAnimation {
            target: root
            property: "masterProgress"
            from: 0.0
            to: 1.0
            duration: 1000
            easing.type: Easing.OutQuint
        }
        PropertyAction {
            target: root
            property: "effectsActive"
            value: false
        }
        PropertyAction {
            target: root
            property: "masterProgress"
            value: 0.0
        }
    }

    function updateWorkspaceFocus() {
        for (let i = 0; i < localWorkspaces.count; i++) {
            const ws = localWorkspaces.get(i);
            if (ws.isFocused === true) {
                root.triggerUnifiedWave();
                root.workspaceChanged(ws.id, Theme.accentPrimary);
                break;
            }
        }
    }

    Rectangle {
        id: workspaceBackground
        width: parent.width - 15
        height: 26
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        radius: 12
        color: Theme.surfaceVariant
        border.color: Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.1)
        border.width: 1
        layer.enabled: true
        layer.effect: DropShadow {
            color: "black"
            radius: 12
            samples: 24
            verticalOffset: 0
            horizontalOffset: 0
            opacity: 0.10
        }
    }

    Row {
        id: pillRow
        spacing: spacingBetweenPills
        anchors.verticalCenter: workspaceBackground.verticalCenter
        width: root.width - horizontalPadding * 2
        x: horizontalPadding
        Repeater {
            id: workspaceRepeater
            model: localWorkspaces
            Item {
                id: workspacePillContainer
                height: 12
                width: {
                    if (model.isFocused)
                        return 44;
                    else if (model.isActive)
                        return 28;
                    else
                        return 16;
                }

                Rectangle {
                    id: workspacePill
                    anchors.fill: parent
                    radius: {
                        if (model.isFocused)
                            return 12;
                        else
                            // half of focused height (if you want to animate this too)
                            return 6;
                    }
                    color: {
                        if (model.isFocused)
                            return Theme.accentPrimary;
                        if (model.isUrgent)
                            return Theme.error;
                        if (model.isActive)
                            return Theme.accentSecondary;
                        if (model.isOccupied)
                            return Theme.accentSecondary;
                        if (model.isUrgent)
                            return Theme.error;

                        return Theme.surfaceVariant.lighter(1.5);
                    }
                    scale: model.isFocused ? 1.0 : 0.9
                    z: 0

                    MouseArea {
                        id: pillMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            WorkspaceManager.switchToWorkspace(model.idx);
                        }
                        z: 20
                        hoverEnabled: true
                    }
                    // Material 3-inspired smooth animation for width, height, scale, color, opacity, and radius
                    Behavior on width {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutBack
                        }
                    }
                    Behavior on height {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutBack
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutBack
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.InOutCubic
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutCubic
                        }
                    }
                    Behavior on radius {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutBack
                        }
                    }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutBack
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutBack
                    }
                }
                // Burst effect overlay for focused pill (smaller outline)
                Rectangle {
                    id: pillBurst
                    anchors.centerIn: workspacePillContainer
                    width: workspacePillContainer.width + 18 * root.masterProgress
                    height: workspacePillContainer.height + 18 * root.masterProgress
                    radius: width / 2
                    color: "transparent"
                    border.color: root.effectColor
                    border.width: 2 + 6 * (1.0 - root.masterProgress)
                    opacity: root.effectsActive && model.isFocused ? (1.0 - root.masterProgress) * 0.7 : 0
                    visible: root.effectsActive && model.isFocused
                    z: 1
                }
            }
        }
    }

    Component.onDestruction: {
        root.isDestroying = true;
    }
}

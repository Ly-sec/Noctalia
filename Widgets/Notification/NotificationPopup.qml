import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Settings

PanelWindow {
    id: window
    implicitWidth: 350
    implicitHeight: notificationColumn.implicitHeight
    color: "transparent"
    visible: notificationModel.count > 0
    screen: Quickshell.primaryScreen !== undefined ? Quickshell.primaryScreen : null
    focusable: false

    property bool barVisible: true

    anchors.top: true
    anchors.right: true
    margins.top: 6
    margins.right: 6

    ListModel {
        id: notificationModel
    }

    property int maxVisible: 5
    property int spacing: 5

    function addNotification(notification) {
        notificationModel.insert(0, {
            id: notification.id,
            appName: notification.appName || "Notification",
            summary: notification.summary || "",
            body: notification.body || "",
            urgency: notification.urgency || 0,
            rawNotification: notification,
            appeared: false,
            dismissed: false
        });

        while (notificationModel.count > maxVisible) {
            notificationModel.remove(notificationModel.count - 1);
        }
    }

    function dismissNotificationById(id) {
        for (var i = 0; i < notificationModel.count; i++) {
            if (notificationModel.get(i).id === id) {
                dismissNotificationByIndex(i);
                break;
            }
        }
    }

    function dismissNotificationByIndex(index) {
        if (index >= 0 && index < notificationModel.count) {
            var notif = notificationModel.get(index);
            if (!notif.dismissed) {
                notificationModel.set(index, {
                    id: notif.id,
                    appName: notif.appName,
                    summary: notif.summary,
                    body: notif.body,
                    rawNotification: notif.rawNotification,
                    appeared: notif.appeared,
                    dismissed: true
                });
            }
        }
    }

    Column {
        id: notificationColumn
        anchors.right: parent.right
        spacing: window.spacing
        width: parent.width
        clip: false

        Repeater {
            id: notificationRepeater
            model: notificationModel

            delegate: Rectangle {
                id: notificationDelegate
                width: parent.width
                color: Theme.backgroundPrimary
                radius: 20
                border.color: model.urgency == 2 ? Theme.warning : Theme.outline
                border.width: 1

                property bool appeared: model.appeared
                property bool dismissed: model.dismissed
                property var rawNotification: model.rawNotification

                x: appeared ? 0 : width
                opacity: dismissed ? 0 : 1
                height: dismissed ? 0 : contentRow.height + 20

                Row {
                    id: contentRow
                    anchors.centerIn: parent
                    spacing: 10
                    width: parent.width - 20

                    // Circular Icon container with border
                    Rectangle {
                        id: iconBackground
                        width: 36
                        height: 36
                        radius: width / 2   // Circular
                        color: Theme.accentPrimary
                        anchors.verticalCenter: parent.verticalCenter
                        border.color: Qt.darker(Theme.accentPrimary, 1.2)
                        border.width: 1.5

                        // Get all possible icon sources from notification
                        property var iconSources: [rawNotification?.image || "", rawNotification?.appIcon || "", rawNotification?.icon || ""]

                        // Try to load notification icon
                        Image {
                            id: iconImage
                            anchors.fill: parent
                            anchors.margins: 4
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            cache: false
                            asynchronous: true
                            sourceSize.width: 36
                            sourceSize.height: 36
                            source: {
                                for (var i = 0; i < iconBackground.iconSources.length; i++) {
                                    var icon = iconBackground.iconSources[i];
                                    if (!icon)
                                        continue;

                                    if (icon.includes("?path=")) {
                                        const [name, path] = icon.split("?path=");
                                        const fileName = name.substring(name.lastIndexOf("/") + 1);
                                        return `file://${path}/${fileName}`;
                                    }

                                    if (icon.startsWith('/')) {
                                        return "file://" + icon;
                                    }

                                    return icon;
                                }
                                return "";
                            }
                            visible: status === Image.Ready && source.toString() !== ""
                        }

                        // Fallback to first letter of app name
                        Text {
                            anchors.centerIn: parent
                            visible: !iconImage.visible
                            text: model.appName ? model.appName.charAt(0).toUpperCase() : "?"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeBody
                            font.bold: true
                            color: Theme.backgroundPrimary
                        }
                    }

                    Column {
                        width: contentRow.width - iconBackground.width - 10
                        spacing: 5

                        Text {
                            text: model.appName
                            width: parent.width
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.bold: true
                            font.pixelSize: Theme.fontSizeSmall
                            elide: Text.ElideRight
                        }
                        Text {
                            text: model.summary
                            width: parent.width
                            color: "#eeeeee"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.Wrap
                            visible: text !== ""
                        }
                        Text {
                            text: model.body
                            width: parent.width
                            color: "#cccccc"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeCaption
                            wrapMode: Text.Wrap
                            visible: text !== ""
                        }
                    }
                }

                Timer {
                    interval: 4000
                    running: !dismissed
                    repeat: false
                    onTriggered: {
                        dismissAnimation.start();
                        if (rawNotification)
                            rawNotification.expire();
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        dismissAnimation.start();
                        if (rawNotification)
                            rawNotification.dismiss();
                    }
                }

                ParallelAnimation {
                    id: dismissAnimation
                    NumberAnimation {
                        target: notificationDelegate
                        property: "opacity"
                        to: 0
                        duration: 150
                    }
                    NumberAnimation {
                        target: notificationDelegate
                        property: "height"
                        to: 0
                        duration: 150
                    }
                    NumberAnimation {
                        target: notificationDelegate
                        property: "x"
                        to: width
                        duration: 150
                        easing.type: Easing.InQuad
                    }
                    onFinished: {
                        for (let i = 0; i < notificationModel.count; i++) {
                            if (notificationModel.get(i).id === notificationDelegate.id) {
                                notificationModel.remove(i);
                                break;
                            }
                        }
                    }
                }

                ParallelAnimation {
                    id: appearAnimation
                    NumberAnimation {
                        target: notificationDelegate
                        property: "opacity"
                        to: 1
                        duration: 150
                    }
                    NumberAnimation {
                        target: notificationDelegate
                        property: "height"
                        to: contentRow.height + 20
                        duration: 150
                    }
                    NumberAnimation {
                        target: notificationDelegate
                        property: "x"
                        to: 0
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                Component.onCompleted: {
                    if (!appeared) {
                        opacity = 0;
                        height = 0;
                        x = width;
                        appearAnimation.start();
                        for (let i = 0; i < notificationModel.count; i++) {
                            if (notificationModel.get(i).id === notificationDelegate.id) {
                                var oldItem = notificationModel.get(i);
                                notificationModel.set(i, {
                                    id: oldItem.id,
                                    appName: oldItem.appName,
                                    summary: oldItem.summary,
                                    body: oldItem.body,
                                    rawNotification: oldItem.rawNotification,
                                    appeared: true,
                                    read: oldItem.read,
                                    dismissed: oldItem.dismissed
                                });
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (window.screen) {
                x = window.screen.width - width - 20;
            }
        }
    }
}

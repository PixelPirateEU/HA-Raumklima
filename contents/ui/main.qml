pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

import "HomeAssistantClient.js" as HAClient

PlasmoidItem {
    id: root

    readonly property bool inPanel: [
        PlasmaCore.Types.TopEdge,
        PlasmaCore.Types.RightEdge,
        PlasmaCore.Types.BottomEdge,
        PlasmaCore.Types.LeftEdge
    ].includes(Plasmoid.location)

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: inPanel ? compactRepresentation : fullRepresentation

    switchWidth: Kirigami.Units.gridUnit * 14
    switchHeight: Kirigami.Units.gridUnit * 10

    property var roomDataList: []
    property bool isLoading: false
    property bool isConnected: false
    property string errorMessage: ""
    property string lastUpdatedText: "Noch nicht aktualisiert"
    property real averageTemp: 0.0
    property bool hasAverageTemp: false
    property real averageHumidity: 0.0
    property bool hasAverageHumidity: false

    readonly property bool hasCredentials: String(Plasmoid.configuration.haUrl || "").trim().length > 0
        && String(Plasmoid.configuration.haToken || "").trim().length > 0

    ThemeManager {
        id: activeTheme
        useCustomTheme: Plasmoid.configuration.useCustomTheme
        customBgColor: Plasmoid.configuration.bgColor || "#1e1e2e"
        customBgOpacity: Plasmoid.configuration.bgOpacity
        customCardBgColor: Plasmoid.configuration.cardBgColor || "#313244"
        customCardOpacity: Plasmoid.configuration.cardOpacity
        customCardBorderColor: Plasmoid.configuration.cardBorderColor || "#45475a"
        customCardBorderWidth: Plasmoid.configuration.cardBorderWidth
        customCardCornerRadius: Plasmoid.configuration.cardCornerRadius
        customTextColor: Plasmoid.configuration.textColor || "#cdd6f4"
        customSecondaryTextColor: Plasmoid.configuration.secondaryTextColor || "#a6adc8"
        customTempAccentColor: Plasmoid.configuration.tempAccentColor || "#fab387"
        customHumidityAccentColor: Plasmoid.configuration.humidityAccentColor || "#89b4fa"
    }

    function parseRoomsConfig() {
        var raw = Plasmoid.configuration.roomsJson || "[]";
        try {
            var parsed = JSON.parse(raw);
            if (Array.isArray(parsed)) {
                return parsed;
            }
        } catch (e) {
            console.warn("Fehler beim Parsen von roomsJson:", e);
        }
        return [];
    }

    function updateAverages(rooms) {
        var tempSum = 0.0;
        var tempCount = 0;
        var humSum = 0.0;
        var humCount = 0;

        for (var i = 0; i < rooms.length; i++) {
            var r = rooms[i];
            if (r.tempAvailable && typeof r.tempValue === "number") {
                tempSum += r.tempValue;
                tempCount++;
            }
            if (r.humidityAvailable && typeof r.humidityValue === "number") {
                humSum += r.humidityValue;
                humCount++;
            }
        }

        root.hasAverageTemp = tempCount > 0;
        root.averageTemp = tempCount > 0 ? (tempSum / tempCount) : 0.0;
        root.hasAverageHumidity = humCount > 0;
        root.averageHumidity = humCount > 0 ? (humSum / humCount) : 0.0;
    }

    function resolveIconSource(icon) {
        var norm = HAClient.normalizeRoomIcon(icon);
        if (norm.indexOf(".svg") === norm.length - 4) {
            return Qt.resolvedUrl("../svg/" + norm);
        }
        return norm;
    }

    function loadDemoData() {
        var configuredRooms = parseRoomsConfig();
        var demoTemps = [21.6, 19.2, 22.4, 23.8, 20.5, 18.4, 21.0, 22.1];
        var demoHums = [46, 52, 41, 62, 48, 55, 44, 50];
        var list = [];

        for (var i = 0; i < configuredRooms.length; i++) {
            var cfg = configuredRooms[i];
            list.push({
                name: cfg.name || ("Raum " + (i + 1)),
                icon: HAClient.normalizeRoomIcon(cfg.icon),
                tempAvailable: true,
                tempValue: demoTemps[i % demoTemps.length],
                tempUnit: "°C",
                hasTargetTemp: false,
                targetTempValue: 0.0,
                humidityAvailable: true,
                humidityValue: demoHums[i % demoHums.length],
                humidityUnit: "%"
            });
        }

        root.roomDataList = list;
        updateAverages(list);
        root.isConnected = true;
        root.isLoading = false;
        root.errorMessage = "";
        var now = new Date();
        root.lastUpdatedText = "Demo-Modus (" + Qt.formatTime(now, "HH:mm:ss") + ")";
    }

    function refreshData() {
        var configuredRooms = parseRoomsConfig();

        if (Plasmoid.configuration.demoMode) {
            loadDemoData();
            return;
        }

        if (!root.hasCredentials) {
            var emptyList = [];
            for (var i = 0; i < configuredRooms.length; i++) {
                var c = configuredRooms[i];
                emptyList.push({
                    name: c.name || ("Raum " + (i + 1)),
                    icon: HAClient.normalizeRoomIcon(c.icon),
                    tempAvailable: false,
                    tempValue: 0.0,
                    tempUnit: "°C",
                    hasTargetTemp: false,
                    targetTempValue: 0.0,
                    humidityAvailable: false,
                    humidityValue: 0.0,
                    humidityUnit: "%"
                });
            }
            root.roomDataList = emptyList;
            updateAverages(emptyList);
            root.isConnected = false;
            root.isLoading = false;
            root.errorMessage = "Keine Home Assistant Zugangsdaten hinterlegt.";
            return;
        }

        root.isLoading = true;
        HAClient.fetchStates(
            Plasmoid.configuration.haUrl,
            Plasmoid.configuration.haToken,
            function(result) {
                root.isLoading = false;
                if (!result.ok) {
                    root.isConnected = false;
                    root.errorMessage = result.error || "Verbindungsfehler";
                    return;
                }

                var statesMap = result.statesMap || {};
                var updatedRooms = [];

                for (var idx = 0; idx < configuredRooms.length; idx++) {
                    var roomCfg = configuredRooms[idx];
                    var tempEntityId = String(roomCfg.tempEntity || "").trim();
                    var humEntityId = String(roomCfg.humidityEntity || "").trim();

                    var tempObj = tempEntityId ? statesMap[tempEntityId] : null;
                    var humObj = humEntityId ? statesMap[humEntityId] : (tempEntityId.indexOf("climate.") === 0 ? tempObj : null);

                    var tempInfo = HAClient.extractEntityValue(tempObj, "temp");
                    var humInfo = HAClient.extractEntityValue(humObj, "humidity");

                    updatedRooms.push({
                        name: roomCfg.name || tempInfo.friendlyName || ("Raum " + (idx + 1)),
                        icon: HAClient.normalizeRoomIcon(roomCfg.icon),
                        tempAvailable: tempInfo.available,
                        tempValue: tempInfo.value !== null ? tempInfo.value : 0.0,
                        tempUnit: tempInfo.unit || "°C",
                        hasTargetTemp: tempInfo.targetTemp !== null,
                        targetTempValue: tempInfo.targetTemp !== null ? tempInfo.targetTemp : 0.0,
                        humidityAvailable: humInfo.available,
                        humidityValue: humInfo.value !== null ? humInfo.value : 0.0,
                        humidityUnit: humInfo.unit || "%"
                    });
                }

                root.roomDataList = updatedRooms;
                updateAverages(updatedRooms);
                root.isConnected = true;
                root.errorMessage = "";
                var now = new Date();
                root.lastUpdatedText = "Aktualisiert um " + Qt.formatTime(now, "HH:mm:ss");
            }
        );
    }

    Timer {
        id: pollTimer
        interval: Math.max(5, Plasmoid.configuration.refreshInterval || 30) * 1000
        running: true
        repeat: true
        onTriggered: root.refreshData()
    }

    readonly property string cfgHaUrl: Plasmoid.configuration.haUrl || ""
    readonly property string cfgHaToken: Plasmoid.configuration.haToken || ""
    readonly property string cfgRoomsJson: Plasmoid.configuration.roomsJson || "[]"
    readonly property bool cfgDemoMode: Boolean(Plasmoid.configuration.demoMode)

    onCfgHaUrlChanged: root.refreshData()
    onCfgHaTokenChanged: root.refreshData()
    onCfgRoomsJsonChanged: root.refreshData()
    onCfgDemoModeChanged: root.refreshData()

    PlasmaCore.Action {
        id: refreshAction
        text: "Jetzt von Home Assistant aktualisieren"
        icon.name: "view-refresh"
        onTriggered: root.refreshData()
    }

    Component.onCompleted: {
        Plasmoid.setInternalAction("refresh", refreshAction);
        root.refreshData();
    }

    // Compact Representation (Panel / System Tray)
    compactRepresentation: MouseArea {
        id: compactRoot
        acceptedButtons: Qt.LeftButton
        onClicked: root.expanded = !root.expanded

        readonly property real contentWidth: Math.ceil(
            Math.max(
                compactRow.implicitWidth,
                Kirigami.Units.iconSizes.small + compactRow.spacing + compactText.implicitWidth
            )
        ) + 16
        readonly property real contentHeight: Math.ceil(
            Math.max(compactRow.implicitHeight, compactText.implicitHeight)
        ) + 6

        implicitWidth: contentWidth
        implicitHeight: contentHeight

        Layout.minimumWidth: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? 0 : contentWidth
        Layout.preferredWidth: contentWidth
        Layout.minimumHeight: Plasmoid.formFactor === PlasmaCore.Types.Horizontal ? 0 : contentHeight
        Layout.preferredHeight: contentHeight

        readonly property var displayRoom: {
            if (Plasmoid.configuration.showAverageInCompact || root.roomDataList.length === 0) {
                return null;
            }
            var idx = Math.max(0, Math.min(root.roomDataList.length - 1, Plasmoid.configuration.compactRoomIndex || 0));
            return root.roomDataList[idx];
        }

        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: 5

            Kirigami.Icon {
                Layout.minimumWidth: Kirigami.Units.iconSizes.small
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.minimumHeight: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                source: compactRoot.displayRoom ? root.resolveIconSource(compactRoot.displayRoom.icon) : Qt.resolvedUrl("../svg/thermometer.svg")
                isMask: true
                color: activeTheme.primaryTextColor
            }

            Text {
                id: compactText
                Layout.minimumWidth: implicitWidth
                Layout.preferredWidth: implicitWidth
                color: activeTheme.primaryTextColor
                font.bold: true
                font.pixelSize: 12
                text: {
                    if (Plasmoid.configuration.showAverageInCompact) {
                        var t = root.hasAverageTemp ? root.averageTemp.toFixed(1).replace(".", ",") + "°C" : "--°C";
                        if (Plasmoid.configuration.showHumidityInCompact) {
                            var h = root.hasAverageHumidity ? " · " + Math.round(root.averageHumidity) + "%" : "";
                            return t + h;
                        }
                        return t;
                    }
                    if (!compactRoot.displayRoom) {
                        return "Raumklima";
                    }
                    var r = compactRoot.displayRoom;
                    var rt = r.tempAvailable ? r.tempValue.toFixed(1).replace(".", ",") + "°C" : "--°C";
                    if (Plasmoid.configuration.showHumidityInCompact) {
                        var rh = r.humidityAvailable ? " · " + Math.round(r.humidityValue) + "%" : "";
                        return rt + rh;
                    }
                    return rt;
                }
            }
        }
    }

    // Full Representation (Desktop Widget & Popup)
    fullRepresentation: Item {
        id: fullRoot

        readonly property int gridCols: Math.max(1, Math.min(4, Plasmoid.configuration.columns || 2))

        Layout.minimumWidth: gridCols === 1 ? 260 : 500
        Layout.minimumHeight: 230
        Layout.preferredWidth: gridCols * 250 + 40
        Layout.preferredHeight: {
            var rows = Math.max(1, Math.ceil(root.roomDataList.length / gridCols));
            return Math.min(540, 86 + rows * 108);
        }

        Rectangle {
            id: mainContainer
            anchors.fill: parent
            radius: activeTheme.cardCornerRadius + 4
            color: activeTheme.windowBgColor
            border.width: activeTheme.cardBorderWidth
            border.color: activeTheme.cardBorderColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Header Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 9
                        color: Qt.rgba(activeTheme.humidityAccentColor.r, activeTheme.humidityAccentColor.g, activeTheme.humidityAccentColor.b, 0.18)

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            source: Qt.resolvedUrl("../svg/thermometer.svg")
                            isMask: true
                            color: activeTheme.humidityAccentColor
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        RowLayout {
                            spacing: 6

                            Text {
                                text: Plasmoid.configuration.widgetTitle || "Raumklima"
                                color: activeTheme.primaryTextColor
                                font.pixelSize: 15
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            // Status Dot
                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: root.isConnected
                                    ? activeTheme.optimalColor
                                    : (root.isLoading ? activeTheme.warningColor : activeTheme.alertColor)
                            }
                        }

                        Text {
                            text: {
                                if (root.hasAverageTemp || root.hasAverageHumidity) {
                                    var parts = [];
                                    if (root.hasAverageTemp) {
                                        parts.push("Ø " + root.averageTemp.toFixed(1).replace(".", ",") + " °C");
                                    }
                                    if (root.hasAverageHumidity) {
                                        parts.push("Ø " + Math.round(root.averageHumidity) + " %");
                                    }
                                    return parts.join("  •  ");
                                }
                                return root.isConnected ? "Verbunden mit Home Assistant" : "Nicht verbunden";
                            }
                            color: activeTheme.secondaryTextColor
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    // Refresh Button
                    ToolButton {
                        icon.name: "view-refresh"
                        ToolTip.visible: hovered
                        ToolTip.text: "Sensordaten jetzt aktualisieren"
                        onClicked: root.refreshData()
                    }

                    // Settings Button
                    ToolButton {
                        icon.name: "configure"
                        ToolTip.visible: hovered
                        ToolTip.text: "Einstellungen öffnen"
                        onClicked: Plasmoid.internalAction("configure").trigger()
                    }
                }

                // Onboarding / Error Banner when not connected and not in Demo Mode
                Rectangle {
                    visible: !root.hasCredentials && !Plasmoid.configuration.demoMode
                    Layout.fillWidth: true
                    implicitHeight: onboardingLayout.implicitHeight + 18
                    radius: activeTheme.cardCornerRadius
                    color: Qt.rgba(activeTheme.humidityAccentColor.r, activeTheme.humidityAccentColor.g, activeTheme.humidityAccentColor.b, 0.14)
                    border.width: 1
                    border.color: Qt.rgba(activeTheme.humidityAccentColor.r, activeTheme.humidityAccentColor.g, activeTheme.humidityAccentColor.b, 0.4)

                    ColumnLayout {
                        id: onboardingLayout
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: "Willkommen! Verbinde das Widget in den Einstellungen mit deinem Home Assistant oder starte die Demo-Vorschau."
                            color: activeTheme.primaryTextColor
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            spacing: 8

                            Button {
                                text: "Verbindung einrichten"
                                icon.name: "network-connect"
                                onClicked: Plasmoid.internalAction("configure").trigger()
                            }

                            Button {
                                text: "Demo-Vorschau aktivieren"
                                icon.name: "view-preview"
                                onClicked: {
                                    Plasmoid.configuration.demoMode = true;
                                }
                            }
                        }
                    }
                }

                // Error Banner when credentials exist but connection failed
                Rectangle {
                    visible: root.hasCredentials && !Plasmoid.configuration.demoMode && root.errorMessage.length > 0
                    Layout.fillWidth: true
                    implicitHeight: errorRow.implicitHeight + 14
                    radius: activeTheme.cardCornerRadius
                    color: Qt.rgba(activeTheme.alertColor.r, activeTheme.alertColor.g, activeTheme.alertColor.b, 0.16)
                    border.width: 1
                    border.color: Qt.rgba(activeTheme.alertColor.r, activeTheme.alertColor.g, activeTheme.alertColor.b, 0.45)

                    RowLayout {
                        id: errorRow
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 6

                        Kirigami.Icon {
                            width: 16
                            height: 16
                            source: "dialog-error"
                            color: activeTheme.alertColor
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.errorMessage
                            color: activeTheme.primaryTextColor
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                // Scrollable Grid of Room Cards
                ScrollView {
                    id: roomsScrollView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    GridLayout {
                        width: roomsScrollView.availableWidth
                        columns: fullRoot.gridCols
                        columnSpacing: 10
                        rowSpacing: 10
                        uniformCellWidths: true

                        Repeater {
                            model: root.roomDataList

                            delegate: RoomCard {
                                required property var modelData

                                Layout.fillWidth: true
                                Layout.minimumWidth: 210
                                themeObj: activeTheme
                                roomName: modelData.name || "Raum"
                                roomIcon: modelData.icon || "sofa.svg"
                                tempAvailable: modelData.tempAvailable || false
                                tempValue: modelData.tempValue || 0.0
                                tempUnit: modelData.tempUnit || "°C"
                                hasTargetTemp: modelData.hasTargetTemp || false
                                targetTempValue: modelData.targetTempValue || 0.0
                                humidityAvailable: modelData.humidityAvailable || false
                                humidityValue: modelData.humidityValue || 0.0
                                humidityUnit: modelData.humidityUnit || "%"

                                showHumidityBar: Plasmoid.configuration.showHumidityBar
                                showComfortBadge: Plasmoid.configuration.showComfortBadge
                                enableThresholdColors: Plasmoid.configuration.enableThresholdColors
                                warningTempLow: Plasmoid.configuration.warningTempLow
                                warningTempHigh: Plasmoid.configuration.warningTempHigh
                                warningHumidityLow: Plasmoid.configuration.warningHumidityLow
                                warningHumidityHigh: Plasmoid.configuration.warningHumidityHigh
                            }
                        }
                    }
                }

                // Footer Bar (Last Updated & Demo Mode Indicator)
                RowLayout {
                    visible: Plasmoid.configuration.showLastUpdated || Plasmoid.configuration.demoMode
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: root.lastUpdatedText
                        color: activeTheme.secondaryTextColor
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    Button {
                        visible: Plasmoid.configuration.demoMode
                        flat: true
                        text: "Demo beenden"
                        font.pixelSize: 10
                        onClicked: {
                            Plasmoid.configuration.demoMode = false;
                        }
                    }
                }
            }
        }
    }
}

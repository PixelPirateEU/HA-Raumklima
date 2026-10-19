pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "HomeAssistantClient.js" as HAClient

KCM.SimpleKCM {
    id: connectionPage

    property alias cfg_haUrl: urlField.text
    property alias cfg_haToken: tokenField.text
    property alias cfg_refreshInterval: intervalSpin.value
    property alias cfg_demoMode: demoSwitch.checked
    property string cfg_roomsJson: "[]"

    property var discoveredTempSensors: []
    property var discoveredHumiditySensors: []
    property var discoveredRooms: []
    property bool isTesting: false
    property string statusMessage: ""
    property bool statusOk: false

    readonly property var iconOptions: [
        { label: "Haus / Wohnzimmer", icon: "sofa.svg" },
        { label: "Schlafzimmer / Nacht", icon: "bed.svg" },
        { label: "Kinderzimmer", icon: "teddy-bear.svg" },
        { label: "Büro / Arbeitszimmer", icon: "laptop.svg" },
        { label: "Badezimmer / Wasser", icon: "paper-roll.svg" },
        { label: "Küche / Haushalt", icon: "fridge.svg" },
        { label: "Außen / Balkon / Garten", icon: "balcony.svg" },
        { label: "Flur / Keller / Allgemein", icon: "texture-box.svg" }
    ]

    function resolveIconSource(icon) {
        var norm = HAClient.normalizeRoomIcon(icon);
        if (norm.indexOf(".svg") === norm.length - 4) {
            return Qt.resolvedUrl("../svg/" + norm);
        }
        return norm;
    }

    ListModel {
        id: roomsModel
    }

    property bool syncingModel: false

    function loadModelFromJson() {
        syncingModel = true;
        roomsModel.clear();
        try {
            var arr = JSON.parse(cfg_roomsJson || "[]");
            if (Array.isArray(arr)) {
                for (var i = 0; i < arr.length; i++) {
                    var item = arr[i];
                    roomsModel.append({
                        name: String(item.name || "Raum " + (i + 1)),
                        icon: HAClient.normalizeRoomIcon(item.icon),
                        tempEntity: String(item.tempEntity || ""),
                        humidityEntity: String(item.humidityEntity || "")
                    });
                }
            }
        } catch (e) {
            console.warn("Konnte cfg_roomsJson nicht parsen:", e);
        }
        syncingModel = false;
    }

    function saveModelToJson() {
        if (syncingModel) {
            return;
        }
        var arr = [];
        for (var i = 0; i < roomsModel.count; i++) {
            var item = roomsModel.get(i);
            arr.push({
                name: item.name,
                icon: item.icon,
                tempEntity: item.tempEntity,
                humidityEntity: item.humidityEntity
            });
        }
        cfg_roomsJson = JSON.stringify(arr);
    }

    function testAndDiscover(applyAutoRooms) {
        connectionPage.isTesting = true;
        connectionPage.statusMessage = "Verbinde mit Home Assistant...";
        connectionPage.statusOk = false;

        HAClient.testConnection(urlField.text, tokenField.text, function(testRes) {
            if (!testRes.ok) {
                connectionPage.isTesting = false;
                connectionPage.statusOk = false;
                connectionPage.statusMessage = testRes.error || "Verbindung fehlgeschlagen.";
                return;
            }

            HAClient.fetchStates(urlField.text, tokenField.text, function(statesRes) {
                connectionPage.isTesting = false;
                if (!statesRes.ok) {
                    connectionPage.statusOk = false;
                    connectionPage.statusMessage = statesRes.error || "Konnte Sensoren nicht abrufen.";
                    return;
                }

                var disc = HAClient.discoverSensorsAndRooms(statesRes.statesList);
                connectionPage.discoveredTempSensors = disc.tempSensors;
                connectionPage.discoveredHumiditySensors = disc.humiditySensors;
                connectionPage.discoveredRooms = disc.discoveredRooms;

                var verText = testRes.version ? (" (Version " + testRes.version + ")") : "";
                connectionPage.statusOk = true;
                connectionPage.statusMessage = "Verbindung erfolgreich" + verText + "! "
                    + disc.tempSensors.length + " Temperatur- und "
                    + disc.humiditySensors.length + " Luftfeuchtigkeits-Entitäten gefunden.";

                if (applyAutoRooms && disc.discoveredRooms.length > 0) {
                    syncingModel = true;
                    roomsModel.clear();
                    for (var i = 0; i < disc.discoveredRooms.length; i++) {
                        var r = disc.discoveredRooms[i];
                        roomsModel.append({
                            name: r.name,
                            icon: HAClient.normalizeRoomIcon(r.icon),
                            tempEntity: r.tempEntity || "",
                            humidityEntity: r.humidityEntity || ""
                        });
                    }
                    syncingModel = false;
                    saveModelToJson();
                }
            });
        });
    }

    Component.onCompleted: {
        loadModelFromJson();
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: connectionPage.statusMessage.length > 0
            type: connectionPage.statusOk ? Kirigami.MessageType.Positive : Kirigami.MessageType.Error
            text: connectionPage.statusMessage
        }

        // Section 1: Home Assistant Connection
        Kirigami.FormLayout {
            Layout.fillWidth: true

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "Home Assistant Verbindungsdaten"
            }

            TextField {
                id: urlField
                Kirigami.FormData.label: "Server-URL:"
                Layout.fillWidth: true
                placeholderText: "http://homeassistant.local:8123 oder https://ha.example.com"
            }

            RowLayout {
                Kirigami.FormData.label: "Access Token:"
                Layout.fillWidth: true
                spacing: 6

                TextField {
                    id: tokenField
                    Layout.fillWidth: true
                    echoMode: showTokenButton.checked ? TextInput.Normal : TextInput.Password
                    placeholderText: "Long-Lived Access Token (Profil -> Sicherheit -> Langlebige Zugriffstoken)"
                }

                ToolButton {
                    id: showTokenButton
                    checkable: true
                    icon.name: checked ? "view-hidden" : "view-visible"
                    ToolTip.visible: hovered
                    ToolTip.text: checked ? "Token verbergen" : "Token anzeigen"
                }
            }

            RowLayout {
                Kirigami.FormData.label: "Verbindungstest:"
                spacing: 8

                Button {
                    text: connectionPage.isTesting ? "Prüfe Verbindung..." : "Verbindung testen & Sensoren laden"
                    icon.name: "network-connect"
                    enabled: !connectionPage.isTesting
                    onClicked: connectionPage.testAndDiscover(false)
                }

                Button {
                    text: "Räume automatisch aus HA erkennen"
                    icon.name: "Find"
                    enabled: !connectionPage.isTesting
                    ToolTip.visible: hovered
                    ToolTip.text: "Erkennt Räume anhand der Sensornamen in Home Assistant und trägt sie unten ein"
                    onClicked: connectionPage.testAndDiscover(true)
                }
            }

            SpinBox {
                id: intervalSpin
                Kirigami.FormData.label: "Abfrage-Intervall (Sek.):"
                from: 5
                to: 3600
                stepSize: 5
            }

            CheckBox {
                id: demoSwitch
                Kirigami.FormData.label: "Vorschau:"
                text: "Demo-Modus aktivieren (simulierte Raumwerte ohne Home Assistant anzeigen)"
            }
        }

        // Section 2: Rooms & Sensor Entities Configuration
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: "Konfigurierte Räume & Sensoren (" + roomsModel.count + ")"
                    font.bold: true
                    font.pixelSize: 14
                    Layout.fillWidth: true
                }

                Button {
                    text: "Raum hinzufügen"
                    icon.name: "list-add"
                    onClicked: {
                        roomsModel.append({
                            name: "Neuer Raum",
                            icon: "sofa.svg",
                            tempEntity: "sensor.raum_temperatur",
                            humidityEntity: "sensor.raum_luftfeuchtigkeit"
                        });
                        connectionPage.saveModelToJson();
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                text: "Tipp: Unterstützt sowohl einzelne Sensoren (z. B. sensor.wohnzimmer_temperatur) als auch Klimageräte/Thermostate (z. B. climate.wohnzimmer)."
                opacity: 0.75
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: roomsModel

                delegate: Frame {
                    id: roomDelegate
                    required property int index
                    required property string name
                    required property string icon
                    required property string tempEntity
                    required property string humidityEntity

                    Layout.fillWidth: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Kirigami.Icon {
                                width: 20
                                height: 20
                                source: connectionPage.resolveIconSource(roomDelegate.icon)
                                isMask: true
                                color: Kirigami.Theme.textColor
                            }

                            TextField {
                                Layout.fillWidth: true
                                text: roomDelegate.name
                                placeholderText: "Raumname (z. B. Wohnzimmer)"
                                onTextEdited: {
                                    roomsModel.setProperty(roomDelegate.index, "name", text);
                                    connectionPage.saveModelToJson();
                                }
                            }

                            ComboBox {
                                id: iconCombo
                                Layout.preferredWidth: 200
                                model: connectionPage.iconOptions
                                textRole: "label"
                                currentIndex: {
                                    for (var i = 0; i < connectionPage.iconOptions.length; i++) {
                                        if (connectionPage.iconOptions[i].icon === roomDelegate.icon) {
                                            return i;
                                        }
                                    }
                                    return 0;
                                }
                                onActivated: function(idx) {
                                    roomsModel.setProperty(roomDelegate.index, "icon", connectionPage.iconOptions[idx].icon);
                                    connectionPage.saveModelToJson();
                                }
                            }

                            ToolButton {
                                icon.name: "go-up"
                                enabled: roomDelegate.index > 0
                                ToolTip.visible: hovered
                                ToolTip.text: "Nach oben verschieben"
                                onClicked: {
                                    roomsModel.move(roomDelegate.index, roomDelegate.index - 1, 1);
                                    connectionPage.saveModelToJson();
                                }
                            }

                            ToolButton {
                                icon.name: "go-down"
                                enabled: roomDelegate.index < roomsModel.count - 1
                                ToolTip.visible: hovered
                                ToolTip.text: "Nach unten verschieben"
                                onClicked: {
                                    roomsModel.move(roomDelegate.index, roomDelegate.index + 1, 1);
                                    connectionPage.saveModelToJson();
                                }
                            }

                            ToolButton {
                                icon.name: "edit-delete"
                                ToolTip.visible: hovered
                                ToolTip.text: "Raum entfernen"
                                onClicked: {
                                    roomsModel.remove(roomDelegate.index);
                                    connectionPage.saveModelToJson();
                                }
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: connectionPage.discoveredTempSensors.length > 0 ? 3 : 2
                            columnSpacing: 8
                            rowSpacing: 6

                            Label {
                                text: "Temperatur-Entität:"
                                font.pixelSize: 12
                            }

                            TextField {
                                Layout.fillWidth: true
                                text: roomDelegate.tempEntity
                                placeholderText: "sensor.wohnzimmer_temperatur oder climate.wohnzimmer"
                                onTextEdited: {
                                    roomsModel.setProperty(roomDelegate.index, "tempEntity", text);
                                    connectionPage.saveModelToJson();
                                }
                            }

                            ComboBox {
                                visible: connectionPage.discoveredTempSensors.length > 0
                                Layout.preferredWidth: 220
                                model: connectionPage.discoveredTempSensors
                                displayText: "Aus HA wählen..."
                                textRole: "friendlyName"
                                onActivated: function(idx) {
                                    var selected = connectionPage.discoveredTempSensors[idx];
                                    if (selected && selected.entityId) {
                                        roomsModel.setProperty(roomDelegate.index, "tempEntity", selected.entityId);
                                        connectionPage.saveModelToJson();
                                    }
                                }
                            }

                            Label {
                                text: "Luftfeuchte-Entität:"
                                font.pixelSize: 12
                            }

                            TextField {
                                Layout.fillWidth: true
                                text: roomDelegate.humidityEntity
                                placeholderText: "sensor.wohnzimmer_luftfeuchtigkeit"
                                onTextEdited: {
                                    roomsModel.setProperty(roomDelegate.index, "humidityEntity", text);
                                    connectionPage.saveModelToJson();
                                }
                            }

                            ComboBox {
                                visible: connectionPage.discoveredHumiditySensors.length > 0
                                Layout.preferredWidth: 220
                                model: connectionPage.discoveredHumiditySensors
                                displayText: "Aus HA wählen..."
                                textRole: "friendlyName"
                                onActivated: function(idx) {
                                    var selected = connectionPage.discoveredHumiditySensors[idx];
                                    if (selected && selected.entityId) {
                                        roomsModel.setProperty(roomDelegate.index, "humidityEntity", selected.entityId);
                                        connectionPage.saveModelToJson();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

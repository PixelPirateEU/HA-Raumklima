pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: themePage

    property bool cfg_useCustomTheme: false
    property string cfg_themePreset: "custom"
    property string cfg_bgColor: "#1e1e2e"
    property int cfg_bgOpacity: 92
    property string cfg_cardBgColor: "#313244"
    property int cfg_cardOpacity: 90
    property string cfg_cardBorderColor: "#45475a"
    property int cfg_cardBorderWidth: 1
    property int cfg_cardCornerRadius: 12
    property string cfg_textColor: "#cdd6f4"
    property string cfg_secondaryTextColor: "#a6adc8"
    property string cfg_tempAccentColor: "#fab387"
    property string cfg_humidityAccentColor: "#89b4fa"
    property string cfg_savedCustomThemesJson: "[]"

    property string activeColorProperty: ""
    property var userSavedThemes: []

    readonly property var builtInPresets: [
        {
            id: "catppuccin_mocha",
            name: "Catppuccin Mocha (Dunkel)",
            bgColor: "#1e1e2e",
            bgOpacity: 92,
            cardBgColor: "#313244",
            cardOpacity: 90,
            cardBorderColor: "#45475a",
            cardBorderWidth: 1,
            cardCornerRadius: 12,
            textColor: "#cdd6f4",
            secondaryTextColor: "#a6adc8",
            tempAccentColor: "#fab387",
            humidityAccentColor: "#89b4fa"
        },
        {
            id: "nord_frost",
            name: "Nord Frost (Arktisch Dunkel)",
            bgColor: "#2e3440",
            bgOpacity: 94,
            cardBgColor: "#3b4252",
            cardOpacity: 92,
            cardBorderColor: "#4c566a",
            cardBorderWidth: 1,
            cardCornerRadius: 10,
            textColor: "#eceff4",
            secondaryTextColor: "#d8dee9",
            tempAccentColor: "#ebcb8b",
            humidityAccentColor: "#88c0d0"
        },
        {
            id: "glass_dark",
            name: "Glassmorphism (Transparent Dunkel)",
            bgColor: "#0f172a",
            bgOpacity: 65,
            cardBgColor: "#1e293b",
            cardOpacity: 60,
            cardBorderColor: "#334155",
            cardBorderWidth: 1,
            cardCornerRadius: 16,
            textColor: "#f8fafc",
            secondaryTextColor: "#94a3b8",
            tempAccentColor: "#fb923c",
            humidityAccentColor: "#38bdf8"
        },
        {
            id: "breeze_light_custom",
            name: "Modern Hell (Clean Light)",
            bgColor: "#f8fafc",
            bgOpacity: 95,
            cardBgColor: "#ffffff",
            cardOpacity: 95,
            cardBorderColor: "#cbd5e1",
            cardBorderWidth: 1,
            cardCornerRadius: 12,
            textColor: "#0f172a",
            secondaryTextColor: "#475569",
            tempAccentColor: "#ea580c",
            humidityAccentColor: "#0284c7"
        },
        {
            id: "warm_home",
            name: "Warmes Zuhause (Cozy Amber)",
            bgColor: "#271c19",
            bgOpacity: 92,
            cardBgColor: "#382823",
            cardOpacity: 90,
            cardBorderColor: "#573f36",
            cardBorderWidth: 1,
            cardCornerRadius: 14,
            textColor: "#fff3ec",
            secondaryTextColor: "#d4b8ab",
            tempAccentColor: "#ffb703",
            humidityAccentColor: "#4ea8de"
        }
    ]

    ThemeManager {
        id: previewTheme
        useCustomTheme: themePage.cfg_useCustomTheme
        customBgColor: themePage.cfg_bgColor
        customBgOpacity: themePage.cfg_bgOpacity
        customCardBgColor: themePage.cfg_cardBgColor
        customCardOpacity: themePage.cfg_cardOpacity
        customCardBorderColor: themePage.cfg_cardBorderColor
        customCardBorderWidth: themePage.cfg_cardBorderWidth
        customCardCornerRadius: themePage.cfg_cardCornerRadius
        customTextColor: themePage.cfg_textColor
        customSecondaryTextColor: themePage.cfg_secondaryTextColor
        customTempAccentColor: themePage.cfg_tempAccentColor
        customHumidityAccentColor: themePage.cfg_humidityAccentColor
    }

    function applyThemeData(data) {
        if (!data) {
            return;
        }
        themePage.cfg_useCustomTheme = true;
        themePage.cfg_bgColor = data.bgColor || "#1e1e2e";
        themePage.cfg_bgOpacity = data.bgOpacity !== undefined ? data.bgOpacity : 92;
        themePage.cfg_cardBgColor = data.cardBgColor || "#313244";
        themePage.cfg_cardOpacity = data.cardOpacity !== undefined ? data.cardOpacity : 90;
        themePage.cfg_cardBorderColor = data.cardBorderColor || "#45475a";
        themePage.cfg_cardBorderWidth = data.cardBorderWidth !== undefined ? data.cardBorderWidth : 1;
        themePage.cfg_cardCornerRadius = data.cardCornerRadius !== undefined ? data.cardCornerRadius : 12;
        themePage.cfg_textColor = data.textColor || "#cdd6f4";
        themePage.cfg_secondaryTextColor = data.secondaryTextColor || "#a6adc8";
        themePage.cfg_tempAccentColor = data.tempAccentColor || "#fab387";
        themePage.cfg_humidityAccentColor = data.humidityAccentColor || "#89b4fa";
    }

    function loadSavedThemes() {
        try {
            var parsed = JSON.parse(themePage.cfg_savedCustomThemesJson || "[]");
            if (Array.isArray(parsed)) {
                themePage.userSavedThemes = parsed;
                return;
            }
        } catch (e) {
            console.warn("Konnte gespeicherte Themes nicht laden:", e);
        }
        themePage.userSavedThemes = [];
    }

    function saveCurrentAsCustomTheme(themeName) {
        var cleanName = String(themeName || "").trim();
        if (!cleanName) {
            cleanName = "Mein Theme " + (themePage.userSavedThemes.length + 1);
        }
        var currentObj = {
            name: cleanName,
            bgColor: themePage.cfg_bgColor,
            bgOpacity: themePage.cfg_bgOpacity,
            cardBgColor: themePage.cfg_cardBgColor,
            cardOpacity: themePage.cfg_cardOpacity,
            cardBorderColor: themePage.cfg_cardBorderColor,
            cardBorderWidth: themePage.cfg_cardBorderWidth,
            cardCornerRadius: themePage.cfg_cardCornerRadius,
            textColor: themePage.cfg_textColor,
            secondaryTextColor: themePage.cfg_secondaryTextColor,
            tempAccentColor: themePage.cfg_tempAccentColor,
            humidityAccentColor: themePage.cfg_humidityAccentColor
        };

        var updated = [];
        var replaced = false;
        for (var i = 0; i < themePage.userSavedThemes.length; i++) {
            if (themePage.userSavedThemes[i].name === cleanName) {
                updated.push(currentObj);
                replaced = true;
            } else {
                updated.push(themePage.userSavedThemes[i]);
            }
        }
        if (!replaced) {
            updated.push(currentObj);
        }
        themePage.userSavedThemes = updated;
        themePage.cfg_savedCustomThemesJson = JSON.stringify(updated);
    }

    function deleteSavedCustomTheme(index) {
        var updated = [];
        for (var i = 0; i < themePage.userSavedThemes.length; i++) {
            if (i !== index) {
                updated.push(themePage.userSavedThemes[i]);
            }
        }
        themePage.userSavedThemes = updated;
        themePage.cfg_savedCustomThemesJson = JSON.stringify(updated);
    }

    function openColorPicker(propName, currentColorHex) {
        themePage.activeColorProperty = propName;
        colorDialog.selectedColor = Qt.color(currentColorHex);
        colorDialog.open();
    }

    function colorToHex(c) {
        var r = Math.round(c.r * 255).toString(16).padStart(2, "0");
        var g = Math.round(c.g * 255).toString(16).padStart(2, "0");
        var b = Math.round(c.b * 255).toString(16).padStart(2, "0");
        return "#" + r + g + b;
    }

    ColorDialog {
        id: colorDialog
        title: "Farbe für das Theme auswählen"
        onAccepted: {
            var hex = themePage.colorToHex(selectedColor);
            if (themePage.activeColorProperty === "bgColor") {
                themePage.cfg_bgColor = hex;
            } else if (themePage.activeColorProperty === "cardBgColor") {
                themePage.cfg_cardBgColor = hex;
            } else if (themePage.activeColorProperty === "cardBorderColor") {
                themePage.cfg_cardBorderColor = hex;
            } else if (themePage.activeColorProperty === "textColor") {
                themePage.cfg_textColor = hex;
            } else if (themePage.activeColorProperty === "secondaryTextColor") {
                themePage.cfg_secondaryTextColor = hex;
            } else if (themePage.activeColorProperty === "tempAccentColor") {
                themePage.cfg_tempAccentColor = hex;
            } else if (themePage.activeColorProperty === "humidityAccentColor") {
                themePage.cfg_humidityAccentColor = hex;
            }
        }
    }

    Component.onCompleted: {
        loadSavedThemes();
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        // 1. Live Preview Card
        Frame {
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "Live-Vorschau (" + (themePage.cfg_useCustomTheme ? "Benutzerdefiniertes Theme" : "Linux-Desktop System-Theme") + ")"
                        font.bold: true
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 126
                    radius: previewTheme.cardCornerRadius + 4
                    color: previewTheme.windowBgColor
                    border.width: previewTheme.cardBorderWidth
                    border.color: previewTheme.cardBorderColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        RoomCard {
                            Layout.fillWidth: true
                            themeObj: previewTheme
                            roomName: "Wohnzimmer"
                            roomIcon: "sofa.svg"
                            tempAvailable: true
                            tempValue: 21.5
                            humidityAvailable: true
                            humidityValue: 48
                            showHumidityBar: true
                            showComfortBadge: true
                        }

                        RoomCard {
                            Layout.fillWidth: true
                            themeObj: previewTheme
                            roomName: "Badezimmer"
                            roomIcon: "paper-roll.svg"
                            tempAvailable: true
                            tempValue: 23.8
                            humidityAvailable: true
                            humidityValue: 58
                            showHumidityBar: true
                            showComfortBadge: true
                        }
                    }
                }
            }
        }

        // 2. Theme Mode Selection
        Kirigami.FormLayout {
            Layout.fillWidth: true

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "Theme-Modus"
            }

            RadioButton {
                Kirigami.FormData.label: "Standard:"
                text: "System-Theme des Linux-Desktops verwenden (Breeze / Plasma Farbschema)"
                checked: !themePage.cfg_useCustomTheme
                onToggled: {
                    if (checked) {
                        themePage.cfg_useCustomTheme = false;
                    }
                }
            }

            RadioButton {
                Kirigami.FormData.label: "Individuell:"
                text: "Benutzerdefiniertes Theme für das Widget verwenden"
                checked: themePage.cfg_useCustomTheme
                onToggled: {
                    if (checked) {
                        themePage.cfg_useCustomTheme = true;
                    }
                }
            }
        }

        // 3. Custom Theme Editor & Presets
        Kirigami.FormLayout {
            Layout.fillWidth: true
            enabled: themePage.cfg_useCustomTheme
            opacity: themePage.cfg_useCustomTheme ? 1.0 : 0.5

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "Vorlagen & Eigene Themes verwalten"
            }

            RowLayout {
                Kirigami.FormData.label: "Design-Vorlage laden:"
                spacing: 8

                ComboBox {
                    id: presetCombo
                    Layout.preferredWidth: 260
                    model: themePage.builtInPresets
                    textRole: "name"
                }

                Button {
                    text: "Vorlage anwenden"
                    icon.name: "color-profile"
                    onClicked: {
                        var p = themePage.builtInPresets[presetCombo.currentIndex];
                        if (p) {
                            themePage.cfg_themePreset = p.id;
                            themePage.applyThemeData(p);
                        }
                    }
                }
            }

            RowLayout {
                Kirigami.FormData.label: "Eigenes Theme speichern:"
                spacing: 8

                TextField {
                    id: customThemeNameField
                    Layout.preferredWidth: 200
                    placeholderText: "Name (z. B. Mein Cyber-Theme)"
                }

                Button {
                    text: "Speichern"
                    icon.name: "document-save"
                    onClicked: {
                        themePage.saveCurrentAsCustomTheme(customThemeNameField.text);
                        customThemeNameField.text = "";
                    }
                }
            }

            RowLayout {
                visible: themePage.userSavedThemes.length > 0
                Kirigami.FormData.label: "Gespeicherte Themes:"
                spacing: 8

                ComboBox {
                    id: savedThemesCombo
                    Layout.preferredWidth: 200
                    model: themePage.userSavedThemes
                    textRole: "name"
                }

                Button {
                    text: "Laden"
                    icon.name: "document-open"
                    onClicked: {
                        var t = themePage.userSavedThemes[savedThemesCombo.currentIndex];
                        if (t) {
                            themePage.applyThemeData(t);
                        }
                    }
                }

                Button {
                    text: "Löschen"
                    icon.name: "edit-delete"
                    onClicked: {
                        themePage.deleteSavedCustomTheme(savedThemesCombo.currentIndex);
                    }
                }
            }

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "Hintergrund & Karten-Stil"
            }

            // Widget Background Color
            RowLayout {
                Kirigami.FormData.label: "Widget-Hintergrund:"
                spacing: 8

                Button {
                    implicitWidth: 36
                    implicitHeight: 28
                    onClicked: themePage.openColorPicker("bgColor", themePage.cfg_bgColor)
                    background: Rectangle {
                        radius: 6
                        color: Qt.color(themePage.cfg_bgColor)
                        border.width: 1
                        border.color: Kirigami.Theme.textColor
                    }
                }

                TextField {
                    Layout.preferredWidth: 100
                    text: themePage.cfg_bgColor
                    onTextEdited: themePage.cfg_bgColor = text
                }

                Label { text: "Deckkraft:" }

                Slider {
                    from: 0
                    to: 100
                    stepSize: 1
                    value: themePage.cfg_bgOpacity
                    Layout.preferredWidth: 120
                    onMoved: themePage.cfg_bgOpacity = Math.round(value)
                }

                Label { text: themePage.cfg_bgOpacity + " %" }
            }

            // Card Background Color
            RowLayout {
                Kirigami.FormData.label: "Raumkarten-Hintergrund:"
                spacing: 8

                Button {
                    implicitWidth: 36
                    implicitHeight: 28
                    onClicked: themePage.openColorPicker("cardBgColor", themePage.cfg_cardBgColor)
                    background: Rectangle {
                        radius: 6
                        color: Qt.color(themePage.cfg_cardBgColor)
                        border.width: 1
                        border.color: Kirigami.Theme.textColor
                    }
                }

                TextField {
                    Layout.preferredWidth: 100
                    text: themePage.cfg_cardBgColor
                    onTextEdited: themePage.cfg_cardBgColor = text
                }

                Label { text: "Deckkraft:" }

                Slider {
                    from: 0
                    to: 100
                    stepSize: 1
                    value: themePage.cfg_cardOpacity
                    Layout.preferredWidth: 120
                    onMoved: themePage.cfg_cardOpacity = Math.round(value)
                }

                Label { text: themePage.cfg_cardOpacity + " %" }
            }

            // Card Border & Corner Radius
            RowLayout {
                Kirigami.FormData.label: "Karten-Rahmenfarbe:"
                spacing: 8

                Button {
                    implicitWidth: 36
                    implicitHeight: 28
                    onClicked: themePage.openColorPicker("cardBorderColor", themePage.cfg_cardBorderColor)
                    background: Rectangle {
                        radius: 6
                        color: Qt.color(themePage.cfg_cardBorderColor)
                        border.width: 1
                        border.color: Kirigami.Theme.textColor
                    }
                }

                TextField {
                    Layout.preferredWidth: 100
                    text: themePage.cfg_cardBorderColor
                    onTextEdited: themePage.cfg_cardBorderColor = text
                }

                Label { text: "Rahmenbreite (px):" }

                SpinBox {
                    from: 0
                    to: 6
                    value: themePage.cfg_cardBorderWidth
                    onValueModified: themePage.cfg_cardBorderWidth = value
                }
            }

            RowLayout {
                Kirigami.FormData.label: "Eckenradius (Abrundung):"
                spacing: 8

                Slider {
                    from: 0
                    to: 28
                    stepSize: 1
                    value: themePage.cfg_cardCornerRadius
                    Layout.preferredWidth: 160
                    onMoved: themePage.cfg_cardCornerRadius = Math.round(value)
                }

                Label { text: themePage.cfg_cardCornerRadius + " px" }
            }

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "Schrift- & Akzentfarben"
            }

            // Primary Text Color
            RowLayout {
                Kirigami.FormData.label: "Primäre Textfarbe:"
                spacing: 8

                Button {
                    implicitWidth: 36
                    implicitHeight: 28
                    onClicked: themePage.openColorPicker("textColor", themePage.cfg_textColor)
                    background: Rectangle {
                        radius: 6
                        color: Qt.color(themePage.cfg_textColor)
                        border.width: 1
                        border.color: Kirigami.Theme.textColor
                    }
                }

                TextField {
                    Layout.preferredWidth: 100
                    text: themePage.cfg_textColor
                    onTextEdited: themePage.cfg_textColor = text
                }
            }

            // Secondary Text Color
            RowLayout {
                Kirigami.FormData.label: "Sekundäre Textfarbe:"
                spacing: 8

                Button {
                    implicitWidth: 36
                    implicitHeight: 28
                    onClicked: themePage.openColorPicker("secondaryTextColor", themePage.cfg_secondaryTextColor)
                    background: Rectangle {
                        radius: 6
                        color: Qt.color(themePage.cfg_secondaryTextColor)
                        border.width: 1
                        border.color: Kirigami.Theme.textColor
                    }
                }

                TextField {
                    Layout.preferredWidth: 100
                    text: themePage.cfg_secondaryTextColor
                    onTextEdited: themePage.cfg_secondaryTextColor = text
                }
            }

            // Temperature Accent Color
            RowLayout {
                Kirigami.FormData.label: "Temperatur-Akzentfarbe:"
                spacing: 8

                Button {
                    implicitWidth: 36
                    implicitHeight: 28
                    onClicked: themePage.openColorPicker("tempAccentColor", themePage.cfg_tempAccentColor)
                    background: Rectangle {
                        radius: 6
                        color: Qt.color(themePage.cfg_tempAccentColor)
                        border.width: 1
                        border.color: Kirigami.Theme.textColor
                    }
                }

                TextField {
                    Layout.preferredWidth: 100
                    text: themePage.cfg_tempAccentColor
                    onTextEdited: themePage.cfg_tempAccentColor = text
                }
            }

            // Humidity Accent Color
            RowLayout {
                Kirigami.FormData.label: "Luftfeuchte-Akzentfarbe:"
                spacing: 8

                Button {
                    implicitWidth: 36
                    implicitHeight: 28
                    onClicked: themePage.openColorPicker("humidityAccentColor", themePage.cfg_humidityAccentColor)
                    background: Rectangle {
                        radius: 6
                        color: Qt.color(themePage.cfg_humidityAccentColor)
                        border.width: 1
                        border.color: Kirigami.Theme.textColor
                    }
                }

                TextField {
                    Layout.preferredWidth: 100
                    text: themePage.cfg_humidityAccentColor
                    onTextEdited: themePage.cfg_humidityAccentColor = text
                }
            }
        }
    }
}

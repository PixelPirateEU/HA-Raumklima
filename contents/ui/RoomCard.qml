import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: card

    property var themeObj
    property string roomName: "Raum"
    property string roomIcon: "sofa.svg"
    property bool tempAvailable: false
    property real tempValue: 0.0
    property string tempUnit: "°C"
    property bool hasTargetTemp: false
    property real targetTempValue: 0.0
    property bool humidityAvailable: false
    property real humidityValue: 0.0
    property string humidityUnit: "%"

    property bool showHumidityBar: true
    property bool showComfortBadge: true
    property bool enableThresholdColors: true
    property real warningTempLow: 18.0
    property real warningTempHigh: 25.0
    property real warningHumidityLow: 35.0
    property real warningHumidityHigh: 60.0

    function resolveIconSource(icon) {
        var raw = String(icon || "sofa.svg").trim();
        var legacyMap = {
            "user-home": "sofa.svg",
            "weather-clear-night": "bed.svg",
            "applications-games": "teddy-bear.svg",
            "computer": "laptop.svg",
            "weather-showers-scattered": "paper-roll.svg",
            "applications-utilities": "fridge.svg",
            "weather-Few-clouds": "balcony.svg",
            "folder-home": "texture-box.svg"
        };
        var norm = legacyMap[raw] || raw || "sofa.svg";
        if (norm.indexOf(".svg") === norm.length - 4) {
            return Qt.resolvedUrl("../svg/" + norm);
        }
        return norm;
    }

    readonly property bool isHovered: hoverHandler.hovered

    readonly property string comfortStatus: {
        if (!tempAvailable && !humidityAvailable) {
            return "Offline";
        }
        if (tempAvailable && tempValue > warningTempHigh) {
            return "Warm";
        }
        if (tempAvailable && tempValue < warningTempLow) {
            return "Kühl";
        }
        if (humidityAvailable && humidityValue > warningHumidityHigh) {
            return "Feucht";
        }
        if (humidityAvailable && humidityValue < warningHumidityLow) {
            return "Trocken";
        }
        return "Optimal";
    }

    readonly property color comfortBadgeColor: {
        if (!themeObj) {
            return "#22c55e";
        }
        if (!tempAvailable && !humidityAvailable) {
            return themeObj.secondaryTextColor;
        }
        if (!enableThresholdColors || comfortStatus === "Optimal") {
            return themeObj.optimalColor;
        }
        if (comfortStatus === "Warm" || comfortStatus === "Feucht") {
            return themeObj.alertColor;
        }
        return themeObj.warningColor;
    }

    readonly property color effectiveTempColor: {
        if (!themeObj) {
            return "#f59e0b";
        }
        if (!tempAvailable) {
            return themeObj.secondaryTextColor;
        }
        if (enableThresholdColors) {
            if (tempValue > warningTempHigh) {
                return themeObj.alertColor;
            }
            if (tempValue < warningTempLow) {
                return Qt.color("#38bdf8");
            }
        }
        return themeObj.tempAccentColor;
    }

    readonly property color effectiveHumidityColor: {
        if (!themeObj) {
            return "#3b82f6";
        }
        if (!humidityAvailable) {
            return themeObj.secondaryTextColor;
        }
        if (enableThresholdColors) {
            if (humidityValue > warningHumidityHigh) {
                return themeObj.alertColor;
            }
            if (humidityValue < warningHumidityLow) {
                return themeObj.warningColor;
            }
        }
        return themeObj.humidityAccentColor;
    }

    implicitWidth: 235
    implicitHeight: showHumidityBar ? 98 : 82

    radius: themeObj ? themeObj.cardCornerRadius : 12
    color: themeObj ? (isHovered ? themeObj.cardHoverBgColor : themeObj.cardBgColor) : "#313244"
    border.width: themeObj ? themeObj.cardBorderWidth : 1
    border.color: isHovered && themeObj
        ? Qt.rgba(themeObj.humidityAccentColor.r, themeObj.humidityAccentColor.g, themeObj.humidityAccentColor.b, 0.55)
        : (themeObj ? themeObj.cardBorderColor : "#45475a")

    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    Behavior on border.color {
        ColorAnimation { duration: 150 }
    }

    HoverHandler {
        id: hoverHandler
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        // Top Row: Icon + Room Name + Comfort Status Pill
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 7
                color: card.themeObj
                    ? Qt.rgba(card.themeObj.humidityAccentColor.r, card.themeObj.humidityAccentColor.g, card.themeObj.humidityAccentColor.b, 0.16)
                    : Qt.rgba(0.5, 0.7, 1.0, 0.16)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: card.resolveIconSource(card.roomIcon)
                    isMask: true
                    color: card.themeObj ? card.themeObj.primaryTextColor : "#ffffff"
                }
            }

            Text {
                Layout.fillWidth: true
                text: card.roomName
                color: card.themeObj ? card.themeObj.primaryTextColor : "#ffffff"
                font.bold: true
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Rectangle {
                visible: card.showComfortBadge
                Layout.preferredHeight: 18
                implicitWidth: badgeText.implicitWidth + 12
                radius: 9
                color: Qt.rgba(card.comfortBadgeColor.r, card.comfortBadgeColor.g, card.comfortBadgeColor.b, 0.18)
                border.width: 1
                border.color: Qt.rgba(card.comfortBadgeColor.r, card.comfortBadgeColor.g, card.comfortBadgeColor.b, 0.45)

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: card.comfortStatus
                    color: card.comfortBadgeColor
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }
        }

        // Middle Row: Temperature & Humidity Values
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Temperature Value
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Kirigami.Icon {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignVCenter
                    source: Qt.resolvedUrl("../svg/thermometer.svg")
                    isMask: true
                    color: card.effectiveTempColor
                }

                Text {
                    text: card.tempAvailable
                        ? card.tempValue.toFixed(1).replace(".", ",") + " " + card.tempUnit
                        : "--,- " + card.tempUnit
                    color: card.effectiveTempColor
                    font.pixelSize: 19
                    font.bold: true
                }
            }

            // Vertical Divider
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.topMargin: 3
                Layout.bottomMargin: 3
                color: card.themeObj ? card.themeObj.cardBorderColor : "#45475a"
            }

            // Humidity Value
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 4

                Kirigami.Icon {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignVCenter
                    source: Qt.resolvedUrl("../svg/water-percent.svg")
                    isMask: true
                    color: card.effectiveHumidityColor
                }

                Text {
                    text: card.humidityAvailable
                        ? Math.round(card.humidityValue) + " " + card.humidityUnit
                        : "-- " + card.humidityUnit
                    color: card.effectiveHumidityColor
                    font.pixelSize: 17
                    font.bold: true
                }
            }
        }

        // Bottom Row: Humidity Comfort Progress Bar
        Item {
            visible: card.showHumidityBar
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            Layout.topMargin: 2

            Rectangle {
                id: barTrack
                anchors.fill: parent
                radius: 3
                color: card.themeObj
                    ? Qt.rgba(card.themeObj.secondaryTextColor.r, card.themeObj.secondaryTextColor.g, card.themeObj.secondaryTextColor.b, 0.2)
                    : Qt.rgba(1, 1, 1, 0.15)

                // Optimal zone highlight (e.g. 35% - 60%)
                Rectangle {
                    x: parent.width * Math.max(0, Math.min(1, card.warningHumidityLow / 100.0))
                    width: parent.width * Math.max(0, Math.min(1, (card.warningHumidityHigh - card.warningHumidityLow) / 100.0))
                    height: parent.height
                    radius: 3
                    color: card.themeObj
                        ? Qt.rgba(card.themeObj.optimalColor.r, card.themeObj.optimalColor.g, card.themeObj.optimalColor.b, 0.22)
                        : Qt.rgba(0.2, 0.8, 0.4, 0.22)
                }

                // Current humidity fill
                Rectangle {
                    width: card.humidityAvailable
                        ? parent.width * Math.max(0.04, Math.min(1.0, card.humidityValue / 100.0))
                        : 0
                    height: parent.height
                    radius: 3
                    color: card.effectiveHumidityColor

                    Behavior on width {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}

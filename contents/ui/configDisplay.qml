pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: displayPage

    property alias cfg_widgetTitle: titleField.text
    property alias cfg_columns: columnsSpin.value
    property alias cfg_compactRoomIndex: compactRoomSpin.value
    property alias cfg_showAverageInCompact: avgCompactCheck.checked
    property alias cfg_showHumidityInCompact: humCompactCheck.checked
    property alias cfg_showHumidityBar: humBarCheck.checked
    property alias cfg_showComfortBadge: comfortBadgeCheck.checked
    property alias cfg_showLastUpdated: lastUpdatedCheck.checked
    property alias cfg_enableThresholdColors: thresholdColorCheck.checked

    property double cfg_warningTempLow: 18.0
    property double cfg_warningTempHigh: 25.0
    property double cfg_warningHumidityLow: 35.0
    property double cfg_warningHumidityHigh: 60.0

    Kirigami.FormLayout {
        Layout.fillWidth: true

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Layout & Darstellung"
        }

        TextField {
            id: titleField
            Kirigami.FormData.label: "Widget-Titel:"
            placeholderText: "Raumklima"
        }

        SpinBox {
            id: columnsSpin
            Kirigami.FormData.label: "Spaltenanzahl (Grid):"
            from: 1
            to: 4
        }

        CheckBox {
            id: humBarCheck
            Kirigami.FormData.label: "Raum-Karten:"
            text: "Fortschrittsbalken für Luftfeuchtigkeit anzeigen"
        }

        CheckBox {
            id: comfortBadgeCheck
            text: "Komfort-Status-Badge (Optimal / Warm / Kühl / Feucht / Trocken) anzeigen"
        }

        CheckBox {
            id: lastUpdatedCheck
            text: "Zeitstempel der letzten Aktualisierung in der Fußzeile anzeigen"
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Kompaktansicht (Kontrollleiste / Panel)"
        }

        CheckBox {
            id: avgCompactCheck
            Kirigami.FormData.label: "Modus:"
            text: "Durchschnittswert aller Räume in der Kontrollleiste anzeigen"
        }

        SpinBox {
            id: compactRoomSpin
            Kirigami.FormData.label: "Raum-Index (0 = 1. Raum):"
            enabled: !avgCompactCheck.checked
            from: 0
            to: 20
        }

        CheckBox {
            id: humCompactCheck
            Kirigami.FormData.label: "Zusatzinfo:"
            text: "Luftfeuchtigkeit neben der Temperatur in der Kontrollleiste anzeigen"
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Komfort-Schwellenwerte"
        }

        CheckBox {
            id: thresholdColorCheck
            Kirigami.FormData.label: "Warnfarben:"
            text: "Werte bei Unter-/Überschreitung der Komfortgrenzen farblich hervorheben"
        }

        SpinBox {
            Kirigami.FormData.label: "Min. Komfort-Temperatur (°C):"
            from: 5
            to: 30
            value: Math.round(displayPage.cfg_warningTempLow)
            onValueModified: displayPage.cfg_warningTempLow = value
        }

        SpinBox {
            Kirigami.FormData.label: "Max. Komfort-Temperatur (°C):"
            from: 15
            to: 40
            value: Math.round(displayPage.cfg_warningTempHigh)
            onValueModified: displayPage.cfg_warningTempHigh = value
        }

        SpinBox {
            Kirigami.FormData.label: "Min. Komfort-Luftfeuchte (%):"
            from: 10
            to: 70
            value: Math.round(displayPage.cfg_warningHumidityLow)
            onValueModified: displayPage.cfg_warningHumidityLow = value
        }

        SpinBox {
            Kirigami.FormData.label: "Max. Komfort-Luftfeuchte (%):"
            from: 30
            to: 95
            value: Math.round(displayPage.cfg_warningHumidityHigh)
            onValueModified: displayPage.cfg_warningHumidityHigh = value
        }
    }
}

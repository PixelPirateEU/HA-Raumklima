import QtQuick
import org.kde.kirigami as Kirigami

QtObject {
    id: theme

    property bool useCustomTheme: false
    property string customBgColor: "#1e1e2e"
    property int customBgOpacity: 92
    property string customCardBgColor: "#313244"
    property int customCardOpacity: 90
    property string customCardBorderColor: "#45475a"
    property int customCardBorderWidth: 1
    property int customCardCornerRadius: 12
    property string customTextColor: "#cdd6f4"
    property string customSecondaryTextColor: "#a6adc8"
    property string customTempAccentColor: "#fab387"
    property string customHumidityAccentColor: "#89b4fa"

    function applyOpacity(baseColor, opacityPercent) {
        var c = Qt.color(baseColor);
        var alpha = Math.max(0.0, Math.min(1.0, opacityPercent / 100.0));
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    readonly property color windowBgColor: useCustomTheme
        ? applyOpacity(customBgColor, customBgOpacity)
        : Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.94)

    readonly property color cardBgColor: useCustomTheme
        ? applyOpacity(customCardBgColor, customCardOpacity)
        : Qt.rgba(
            (Kirigami.Theme.alternateBackgroundColor.r + Kirigami.Theme.backgroundColor.r) * 0.5,
            (Kirigami.Theme.alternateBackgroundColor.g + Kirigami.Theme.backgroundColor.g) * 0.5,
            (Kirigami.Theme.alternateBackgroundColor.b + Kirigami.Theme.backgroundColor.b) * 0.5,
            0.85
        )

    readonly property color cardHoverBgColor: useCustomTheme
        ? Qt.lighter(applyOpacity(customCardBgColor, Math.min(100, customCardOpacity + 8)), 1.08)
        : Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.14)

    readonly property color cardBorderColor: useCustomTheme
        ? Qt.color(customCardBorderColor)
        : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14)

    readonly property int cardBorderWidth: useCustomTheme
        ? customCardBorderWidth
        : 1

    readonly property int cardCornerRadius: useCustomTheme
        ? customCardCornerRadius
        : 12

    readonly property color primaryTextColor: useCustomTheme
        ? Qt.color(customTextColor)
        : Kirigami.Theme.textColor

    readonly property color secondaryTextColor: useCustomTheme
        ? Qt.color(customSecondaryTextColor)
        : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.68)

    readonly property color tempAccentColor: useCustomTheme
        ? Qt.color(customTempAccentColor)
        : (Kirigami.Theme.neutralTextColor ? Kirigami.Theme.neutralTextColor : "#f59e0b")

    readonly property color humidityAccentColor: useCustomTheme
        ? Qt.color(customHumidityAccentColor)
        : Kirigami.Theme.highlightColor

    readonly property color optimalColor: Kirigami.Theme.positiveTextColor
    readonly property color warningColor: Kirigami.Theme.neutralTextColor
    readonly property color alertColor: Kirigami.Theme.negativeTextColor
}

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "Verbindung & Räume"
        icon: "network-connect"
        source: "configConnection.qml"
    }
    ConfigCategory {
        name: "Design & Theme"
        icon: "preferences-desktop-color"
        source: "configTheme.qml"
    }
    ConfigCategory {
        name: "Anzeige & Komfort"
        icon: "view-grid"
        source: "configDisplay.qml"
    }
}

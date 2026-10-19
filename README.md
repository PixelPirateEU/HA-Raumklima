# Home Assistant Raumklima – KDE Plasma 6 Widget

Ein modernes **KDE Plasma 6 Widget (Plasmoid)** zur übersichtlichen Anzeige von **Raumtemperaturen** und **Luftfeuchtigkeit** deiner Räume über die **Home Assistant REST-API**.

---

## ✨ Funktionen

- **Live-Daten aus Home Assistant**: Ruft Temperatur- und Luftfeuchtigkeitswerte über die offizielle Home Assistant REST-API (`/api/states`) ab.
- **Unterstützung für Sensoren & Thermostate**: Funktioniert sowohl mit einzelnen Sensoren (`sensor.wohnzimmer_temperatur`, `sensor.wohnzimmer_luftfeuchtigkeit`) als auch mit kombinierten Klimageräten (`climate.wohnzimmer` inkl. Zieltemperatur-Anzeige).
- **Eigene SVG-Raum- & Messwert-Icons**: Integrierte Vektor-Icons (`contents/svg/`) für Raumkategorien (*Haus / Wohnzimmer*, *Schlafzimmer / Nacht*, *Kinderzimmer*, *Büro / Arbeitszimmer*, *Badezimmer / Wasser*, *Küche / Haushalt*, *Außen / Balkon / Garten*, *Flur / Keller / Allgemein*) sowie für Temperatur (`thermometer.svg`) und Luftfeuchtigkeit (`water-percent.svg`), die sich automatisch passend zum Theme und Komfort-Status einfärben.
- **Komfortables Einstellungsfenster**:
  - **Verbindung & Räume**: Eingabe von Server-URL, Long-Lived Access Token, Abfrage-Intervall, Live-Verbindungstest, Raum-Icon-Auswahl und **automatische Raumerkennung** direkt aus Home Assistant.
  - **Design & Theme**: Standardmäßig passt sich das Widget automatisch an das **aktive Linux-Desktop-Theme (KDE Plasma / Breeze Farbschema)** an. Alternativ lässt sich ein **eigenes benutzerdefiniertes Theme** mit Farbwähler, Deckkraft-Reglern, Rahmenbreite, Eckenradius, Vorlagen und **Live-Vorschau** erstellen und dauerhaft speichern.
  - **Anzeige & Komfort**: Konfigurierbare Spaltenanzahl (1–4 Spalten), Komfort-Schwellenwerte (Optimal / Warm / Kühl / Feucht / Trocken), Fortschrittsbalken für die Luftfeuchtigkeit und Einstellungen für die Kompaktansicht in der Kontrollleiste.
- **Desktop- & Panel-Modus**: Kann direkt als Karten-Dashboard auf dem Desktop oder als kompakte Anzeige (Durchschnitt oder einzelner Raum, optional mit Luftfeuchtigkeit und dynamischer Breitenanpassung) in der KDE-Kontrollleiste platziert werden.
- **Integrierter Demo-Modus**: Ermöglicht das sofortige Testen von Layout und eigenen Themes auch ohne aktive Home Assistant Verbindung.

---

## 📁 Projektstruktur

```text
.
├── metadata.json                  # KDE Plasma 6 Plugin-Metadaten
├── install.sh                     # Installations-, Update- und Paket-Skript
├── README.md                      # Dokumentation
└── contents/
    ├── config/
    │   ├── config.qml             # Kategorien des Einstellungsfensters
    │   └── main.xml               # KConfigXT Konfigurationsschema
    ├── svg/                       # Vektor-Icons für Räume, Temperatur & Luftfeuchtigkeit
    │   ├── sofa.svg               # Haus / Wohnzimmer
    │   ├── bed.svg                # Schlafzimmer / Nacht
    │   ├── teddy-bear.svg         # Kinderzimmer
    │   ├── laptop.svg             # Büro / Arbeitszimmer
    │   ├── paper-roll.svg         # Badezimmer / Wasser
    │   ├── fridge.svg             # Küche / Haushalt
    │   ├── balcony.svg            # Außen / Balkon / Garten
    │   ├── texture-box.svg        # Flur / Keller / Allgemein
    │   ├── thermometer.svg        # Header- & Temperatur-Icon
    │   └── water-percent.svg      # Luftfeuchtigkeits-Icon
    └── ui/
        ├── main.qml               # Haupt-Plasmoid (Kompakt- & Vollansicht)
        ├── RoomCard.qml           # Moderne Raum-Karte mit Komfort-Anzeige
        ├── ThemeManager.qml       # Reaktives Theme-System (System-Theme & Custom-Theme)
        ├── HomeAssistantClient.js # Home Assistant REST-API Client & Auto-Discovery
        ├── configConnection.qml   # Einstellungen: Verbindung & Räume
        ├── configTheme.qml        # Einstellungen: Design & Theme-Editor mit Live-Vorschau
        └── configDisplay.qml      # Einstellungen: Layout & Komfort-Schwellenwerte
```

---

## 🚀 Installation

### Voraussetzungen
- **KDE Plasma 6** (`plasmashell >= 6.0`, `kpackagetool6`)
- Eine erreichbare **Home Assistant** Instanz im lokalen Netzwerk oder per HTTPS

### 1. Per Installations-Skript (Empfohlen)

```bash
chmod +x install.sh
./install.sh install
```

Um das Widget nach Änderungen zu aktualisieren, führe einfach erneut `./install.sh install` aus.
Zum Deinstallieren:

```bash
./install.sh remove
```

### 2. Manuell über `kpackagetool6`

```bash
# Erstinstallation
kpackagetool6 --type Plasma/Applet --install .

# Aktualisierung
kpackagetool6 --type Plasma/Applet --upgrade .
```

### 3. Widget zum Desktop oder zur Kontrollleiste hinzufügen
1. Rechtsklick auf den KDE-Desktop oder die Kontrollleiste → **„Miniprogramme hinzufügen…“** (bzw. *Add Widgets…*).
2. Nach **„Home Assistant Raumklima“** suchen.
3. Das Widget auf den Desktop oder in die Kontrollleiste ziehen.

---

## 🔑 Home Assistant Verbindung einrichten

### 1. Long-Lived Access Token in Home Assistant erstellen
1. Öffne deine Home Assistant Weboberfläche.
2. Klicke unten links auf dein **Benutzerprofil**.
3. Wechsle zum Reiter **„Sicherheit“** (*Security*).
4. Scrolle ganz nach unten zum Abschnitt **„Langlebige Zugriffstoken“** (*Long-Lived Access Tokens*).
5. Klicke auf **„Token erstellen“**, vergib einen Namen (z. B. `KDE Plasma Widget`) und kopiere das angezeigte Token.

### 2. Daten im Einstellungsfenster eingeben
1. Rechtsklick auf das Widget → **„Home Assistant Raumklima einrichten…“** (oder Klick auf das Zahnrad-Symbol oben rechts im Widget).
2. Im Tab **„Verbindung & Räume“**:
   - **Server-URL**: z. B. `http://homeassistant.local:8123` oder `http://192.168.178.50:8123`
   - **Access Token**: Das kopierte Long-Lived Access Token einfügen.
3. Klicke auf **„Verbindung testen & Sensoren laden“**:
   - Bei erfolgreicher Verbindung werden alle verfügbaren Temperatur- und Luftfeuchtigkeits-Entitäten aus Home Assistant geladen und können pro Raum bequem per Dropdown ausgewählt werden.
   - Alternativ kannst du auf **„Räume automatisch aus HA erkennen“** klicken, um deine Räume automatisch anhand der Sensornamen anlegen zu lassen.

---

## 🎨 Themes: Linux-Desktop-Theme & Benutzerdefiniertes Theme

Im Einstellungsfenster unter **„Design & Theme“** stehen zwei Modi zur Verfügung:

1. **System-Theme des Linux-Desktops verwenden (Standard)**:
   - Richtet sich automatisch nach deinem aktiven KDE Plasma Farbschema (z. B. *Breeze Hell*, *Breeze Dunkel*, System-Akzentfarben).
   - Wechselt dein Desktop-Theme zwischen Hell und Dunkel, passt sich das Widget nahtlos an.

2. **Benutzerdefiniertes Theme für das Widget verwenden**:
   - Wähle eine der mitgelieferten Vorlagen (*Catppuccin Mocha*, *Nord Frost*, *Glassmorphism*, *Modern Hell*, *Warmes Zuhause*) als Ausgangspunkt oder gestalte alle Parameter selbst:
     - **Widget-Hintergrundfarbe & Deckkraft (0–100 %)**
     - **Raumkarten-Hintergrundfarbe & Deckkraft (0–100 %)**
     - **Karten-Rahmenfarbe, Rahmenbreite (0–6 px) & Eckenradius (0–28 px)**
     - **Primäre & sekundäre Textfarbe**
     - **Akzentfarben für Temperatur & Luftfeuchtigkeit**
   - Über die integrierte **Live-Vorschau** siehst du alle Änderungen sofort im Einstellungsfenster.
   - Gib deinem Design unter **„Eigenes Theme speichern“** einen Namen und klicke auf **„Speichern“**, um beliebig viele eigene Themes anzulegen und jederzeit wieder zu laden.

---

## 🛠️ Fehlerbehebung

- **„Keine Verbindung zu http://...“**:
  - Prüfe, ob die URL im Browser erreichbar ist und ob Port `:8123` angegeben wurde.
  - Falls HTTPS mit einem selbstsignierten Zertifikat genutzt wird, verwende im lokalen Netz vorzugsweise die lokale HTTP-IP oder hinterlege das CA-Zertifikat im System-Truststore.
- **„Authentifizierung fehlgeschlagen (HTTP 401)“**:
  - Stelle sicher, dass das Long-Lived Access Token vollständig und ohne zusätzliche Leerzeichen kopiert wurde.
- **Ein Raum zeigt `--,- °C` oder `Offline`**:
  - Prüfe im Tab *Verbindung & Räume*, ob die `entity_id` (z. B. `sensor.wohnzimmer_temperatur`) exakt mit der Entitäts-ID in Home Assistant übereinstimmt. Nutze den Button *„Verbindung testen & Sensoren laden“*, um die Entität direkt aus der Dropdown-Liste auszuwählen.

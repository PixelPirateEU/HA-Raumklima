#!/usr/bin/env bash
set -euo pipefail

WIDGET_ID="org.kde.plasma.ha.roomclimate"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v kpackagetool6 >/dev/null 2>&1; then
    KPKG="kpackagetool6"
elif command -v kpackagetool5 >/dev/null 2>&1; then
    KPKG="kpackagetool5"
else
    echo "Fehler: Weder kpackagetool6 noch kpackagetool5 wurde gefunden." >&2
    exit 1
fi

case "${1:-install}" in
    install|--install|-i)
        if "$KPKG" --type Plasma/Applet --show "$WIDGET_ID" >/dev/null 2>&1; then
            echo "Aktualisiere bestehendes Widget '$WIDGET_ID'..."
            "$KPKG" --type Plasma/Applet --upgrade "$SCRIPT_DIR"
        else
            echo "Installiere Widget '$WIDGET_ID'..."
            "$KPKG" --type Plasma/Applet --install "$SCRIPT_DIR"
        fi
        echo "Fertig! Du kannst 'Home Assistant Raumklima' nun über 'Miniprogramme hinzufügen' auf dem Desktop oder in der Kontrollleiste platzieren."
        ;;
    remove|--remove|-r|uninstall)
        echo "Entferne Widget '$WIDGET_ID'..."
        "$KPKG" --type Plasma/Applet --remove "$WIDGET_ID"
        ;;
    package|--package|-p)
        OUT_FILE="${SCRIPT_DIR}/ha-roomclimate.plasmoid"
        rm -f "$OUT_FILE"
        (cd "$SCRIPT_DIR" && zip -r "$OUT_FILE" metadata.json contents/)
        echo "Plasmoid-Paket erstellt: $OUT_FILE"
        ;;
    *)
        echo "Verwendung: $0 [install|remove|package]"
        exit 1
        ;;
esac

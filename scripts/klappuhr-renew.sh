#!/bin/zsh
# Klappuhr automatisch erneuern.
#
# Kostenlose Apple-Accounts signieren Apps nur für 7 Tage. Dieses Skript wird
# von launchd stündlich gestartet und tut fast immer: nichts. Erst wenn das
# installierte Profil in weniger als RENEW_HOURS Stunden abläuft, baut es die
# App neu und installiert sie per WLAN auf dem iPhone.
#
# Aufruf von Hand:
#   scripts/klappuhr-renew.sh           normaler Lauf (wie launchd)
#   scripts/klappuhr-renew.sh --force   sofort neu bauen + installieren

set -u
setopt pipefail

# ---------------------------------------------------------------- Einstellungen
PROJECT_DIR="${0:A:h:h}"                       # Ordner über scripts/
DEVICE_ID=""                                   # kommt aus scripts/config.local (s. u.)
BUNDLE_ID="de.klappuhr.standby"
RENEW_HOURS=30                                 # so viele Stunden vor Ablauf erneuern
NOTIFY_PAUSE_HOURS=6                           # Fehler-Mitteilungen höchstens so oft

STATE_DIR="$HOME/Library/Application Support/Klappuhr"
LOG_DIR="$HOME/Library/Logs/Klappuhr"
LOG="$LOG_DIR/renew.log"
DERIVED="$PROJECT_DIR/build/auto"
APP="$DERIVED/Build/Products/Debug-iphoneos/Klappuhr.app"
PROFILES_DIR="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"

export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
mkdir -p "$STATE_DIR" "$LOG_DIR"

# Persönliche Werte (nicht im Git): scripts/config.local mit z. B.
#   DEVICE_ID="00008140-…"     # aus: xcrun devicectl list devices
[[ -f "${0:A:h}/config.local" ]] && source "${0:A:h}/config.local"

# ---------------------------------------------------------------- Hilfsfunktionen
log()    { print -r -- "$(date '+%Y-%m-%d %H:%M:%S')  $*" >> "$LOG"; }
now()    { date +%s; }
fmt()    { date -r "$1" '+%d.%m.%Y %H:%M'; }

notify() {  # notify "Titel" "Text"
    osascript -e "display notification \"${2//\"/\'}\" with title \"${1//\"/\'}\" sound name \"Basso\"" 2>/dev/null
}

notify_error() {
    log "FEHLER: $1"
    local last=$(cat "$STATE_DIR/last-error-notify" 2>/dev/null || echo 0)
    if (( $(now) - last > NOTIFY_PAUSE_HOURS * 3600 )); then
        notify "Klappuhr: Erneuerung fehlgeschlagen" "$1 Details: ~/Library/Logs/Klappuhr/renew.log"
        now > "$STATE_DIR/last-error-notify"
    fi
}

# Ablaufdatum (Unix-Zeit) eines Profils bzw. einer gebauten App lesen
profile_expiry() {
    local raw
    raw=$(security cms -D -i "$1" 2>/dev/null | plutil -extract ExpirationDate raw - 2>/dev/null) || return 1
    date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$raw" +%s
}

# ---------------------------------------------------------------- 1) Nötig?
FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

installed_expiry=$(cat "$STATE_DIR/installed-expiry" 2>/dev/null || echo 0)
remaining=$(( installed_expiry - $(now) ))

if (( FORCE == 0 && remaining > RENEW_HOURS * 3600 )); then
    exit 0   # alles gut, noch lange gültig
fi

log "---- Erneuerung startet (installiertes Profil gültig bis $(fmt $installed_expiry), force=$FORCE)"

# ---------------------------------------------------------------- 2) Alte Profile wegräumen
# Damit Xcode wirklich ein frisches 7-Tage-Profil holt und nicht das alte wiederverwendet.
for p in "$PROFILES_DIR"/*.mobileprovision(N); do
    if security cms -D -i "$p" 2>/dev/null | grep -q "$BUNDLE_ID"; then
        exp=$(profile_expiry "$p") || continue
        if (( exp <= installed_expiry )) || (( FORCE == 1 )); then
            log "Entferne altes Profil $(basename "$p") (gültig bis $(fmt $exp))"
            rm -f "$p"
        fi
    fi
done

# ---------------------------------------------------------------- 3) Bauen
build_app() {
    xcodebuild \
        -project "$PROJECT_DIR/Klappuhr.xcodeproj" \
        -scheme Klappuhr \
        -configuration Debug \
        -destination 'generic/platform=iOS' \
        -derivedDataPath "$DERIVED" \
        -allowProvisioningUpdates \
        build > "$LOG_DIR/last-build.log" 2>&1
}

# Zwei Versuche: Direkt nach dem Löschen der alten Profile verweist der erste
# Build manchmal noch auf sie. Beim zweiten Mal sind die neuen Profile da.
log "Baue App …"
if ! build_app; then
    log "Erster Build-Versuch fehlgeschlagen, zweiter Versuch …"
    sleep 5
    if ! build_app; then
        notify_error "Build fehlgeschlagen ($(grep -m1 'error:' "$LOG_DIR/last-build.log" | cut -c1-120))."
        exit 1
    fi
fi

new_expiry=$(profile_expiry "$APP/embedded.mobileprovision") || {
    notify_error "Gebaute App hat kein Profil."
    exit 1
}
log "Gebaut, neues Profil gültig bis $(fmt $new_expiry)"

if (( FORCE == 0 && new_expiry <= installed_expiry )); then
    # Apple hat (noch) kein neues Profil ausgestellt. Nächste Stunde erneut versuchen.
    if (( remaining > 0 )); then
        log "Noch kein neues Profil erhältlich, neuer Versuch in einer Stunde."
        exit 0
    fi
    notify_error "Profil abgelaufen und Apple stellt kein neues aus. In Xcode prüfen, ob der Account noch angemeldet ist."
    exit 1
fi

# ---------------------------------------------------------------- 4) Installieren (mit Wiederholung)
for attempt in 1 2 3; do
    log "Installiere auf dem iPhone (Versuch $attempt) …"
    if xcrun devicectl device install app --device "$DEVICE_ID" "$APP" >> "$LOG" 2>&1; then
        print -r -- "$new_expiry" > "$STATE_DIR/installed-expiry"
        rm -f "$STATE_DIR/last-error-notify"
        log "Fertig. Klappuhr gültig bis $(fmt $new_expiry)."
        notify "Klappuhr erneuert" "Gültig bis $(fmt $new_expiry)."
        exit 0
    fi
    sleep 60
done

notify_error "iPhone nicht erreichbar. Ist es im selben WLAN und entsperrt? Neuer Versuch in einer Stunde."
exit 1

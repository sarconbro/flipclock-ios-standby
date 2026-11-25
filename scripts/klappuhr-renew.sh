#!/bin/zsh
# Keep Klappuhr installed on a free Apple developer account.
#
# Free (Personal Team) accounts only sign apps for 7 days. launchd runs this
# script every hour, and almost always it does nothing. Only when the installed
# provisioning profile expires in less than RENEW_HOURS hours does it rebuild
# the app with a fresh profile and install it on the iPhone over Wi-Fi.
#
# Manual use:
#   scripts/klappuhr-renew.sh           regular run (same as launchd)
#   scripts/klappuhr-renew.sh --force   rebuild and install right now

set -u
setopt pipefail

# ---------------------------------------------------------------- Settings
PROJECT_DIR="${0:A:h:h}"                       # folder above scripts/
DEVICE_ID=""                                   # set in scripts/config.local (see below)
BUNDLE_ID="de.klappuhr.standby"
RENEW_HOURS=30                                 # renew this many hours before expiry
NOTIFY_PAUSE_HOURS=6                           # at most one error notification per this many hours

STATE_DIR="$HOME/Library/Application Support/Klappuhr"
LOG_DIR="$HOME/Library/Logs/Klappuhr"
LOG="$LOG_DIR/renew.log"
DERIVED="$PROJECT_DIR/build/auto"
APP="$DERIVED/Build/Products/Debug-iphoneos/Klappuhr.app"
PROFILES_DIR="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"

export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
mkdir -p "$STATE_DIR" "$LOG_DIR"

# Personal values (not in git): scripts/config.local, e.g.
#   DEVICE_ID="00008140-…"     # from: xcrun devicectl list devices
[[ -f "${0:A:h}/config.local" ]] && source "${0:A:h}/config.local"

# ---------------------------------------------------------------- Helpers
log()    { print -r -- "$(date '+%Y-%m-%d %H:%M:%S')  $*" >> "$LOG"; }
now()    { date +%s; }
fmt()    { date -r "$1" '+%Y-%m-%d %H:%M'; }

notify() {  # notify "Title" "Message"
    osascript -e "display notification \"${2//\"/\'}\" with title \"${1//\"/\'}\" sound name \"Basso\"" 2>/dev/null
}

notify_error() {
    log "ERROR: $1"
    local last=$(cat "$STATE_DIR/last-error-notify" 2>/dev/null || echo 0)
    if (( $(now) - last > NOTIFY_PAUSE_HOURS * 3600 )); then
        notify "Klappuhr: renewal failed" "$1 Details: ~/Library/Logs/Klappuhr/renew.log"
        now > "$STATE_DIR/last-error-notify"
    fi
}

# Read the expiry date (Unix time) of a profile or of a built app's embedded profile
profile_expiry() {
    local raw
    raw=$(security cms -D -i "$1" 2>/dev/null | plutil -extract ExpirationDate raw - 2>/dev/null) || return 1
    date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$raw" +%s
}

if [[ -z "$DEVICE_ID" ]]; then
    notify_error "No DEVICE_ID set. Copy scripts/config.local.example to scripts/config.local and fill it in."
    exit 1
fi

# ---------------------------------------------------------------- 1) Needed?
FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

installed_expiry=$(cat "$STATE_DIR/installed-expiry" 2>/dev/null || echo 0)
remaining=$(( installed_expiry - $(now) ))

if (( FORCE == 0 && remaining > RENEW_HOURS * 3600 )); then
    exit 0   # all good, still valid for a while
fi

log "---- Renewal started (installed profile valid until $(fmt $installed_expiry), force=$FORCE)"

# ---------------------------------------------------------------- 2) Remove old profiles
# So Xcode really fetches a fresh 7-day profile instead of reusing the old one.
for p in "$PROFILES_DIR"/*.mobileprovision(N); do
    if security cms -D -i "$p" 2>/dev/null | grep -q "$BUNDLE_ID"; then
        exp=$(profile_expiry "$p") || continue
        if (( exp <= installed_expiry )) || (( FORCE == 1 )); then
            log "Removing old profile $(basename "$p") (valid until $(fmt $exp))"
            rm -f "$p"
        fi
    fi
done

# ---------------------------------------------------------------- 3) Build
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

# Two attempts: right after the old profiles are deleted, the first build sometimes
# still refers to them. On the second attempt the new profiles are in place.
log "Building app …"
if ! build_app; then
    log "First build attempt failed, trying again …"
    sleep 5
    if ! build_app; then
        notify_error "Build failed ($(grep -m1 'error:' "$LOG_DIR/last-build.log" | cut -c1-120))."
        exit 1
    fi
fi

new_expiry=$(profile_expiry "$APP/embedded.mobileprovision") || {
    notify_error "The built app has no provisioning profile."
    exit 1
}
log "Built, new profile valid until $(fmt $new_expiry)"

if (( FORCE == 0 && new_expiry <= installed_expiry )); then
    # Apple has not issued a new profile (yet). Try again next hour.
    if (( remaining > 0 )); then
        log "No new profile available yet, retrying in an hour."
        exit 0
    fi
    notify_error "Profile expired and Apple issues no new one. Check in Xcode that your account is still signed in."
    exit 1
fi

# ---------------------------------------------------------------- 4) Install (with retries)
for attempt in 1 2 3; do
    log "Installing on the iPhone (attempt $attempt) …"
    if xcrun devicectl device install app --device "$DEVICE_ID" "$APP" >> "$LOG" 2>&1; then
        print -r -- "$new_expiry" > "$STATE_DIR/installed-expiry"
        rm -f "$STATE_DIR/last-error-notify"
        log "Done. Klappuhr valid until $(fmt $new_expiry)."
        notify "Klappuhr renewed" "Valid until $(fmt $new_expiry)."
        exit 0
    fi
    sleep 60
done

notify_error "iPhone not reachable. Is it on the same Wi-Fi and unlocked? Retrying in an hour."
exit 1

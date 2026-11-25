#!/bin/zsh
# Installs the launchd job that runs scripts/klappuhr-renew.sh every hour.
# Safe to run again (replaces the existing job).
#
# To remove it:
#   launchctl bootout gui/$(id -u)/de.klappuhr.renew
#   rm ~/Library/LaunchAgents/de.klappuhr.renew.plist

set -eu
LABEL="de.klappuhr.renew"
SCRIPT="${0:A:h}/klappuhr-renew.sh"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG_DIR="$HOME/Library/Logs/Klappuhr"

chmod +x "$SCRIPT"
mkdir -p "$HOME/Library/LaunchAgents" "$LOG_DIR"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>$SCRIPT</string>
    </array>
    <!-- check hourly; runs missed while the Mac was asleep are caught up on wake -->
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>ProcessType</key>
    <string>Background</string>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/launchd.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/launchd.log</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "launchd job $LABEL installed: $PLIST"

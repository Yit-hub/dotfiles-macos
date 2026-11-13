#!/usr/bin/env bash
#
# Update the sketchybar-app-font from the upstream GitHub releases.
#
#   ./update_app_font.sh                 # install the latest version (if needed)
#   ./update_app_font.sh --check         # report status, exit 10 if outdated
#   ./update_app_font.sh --force         # reinstall even if already current
#   ./update_app_font.sh --install-agent # check for updates once a day via launchd
#   ./update_app_font.sh --uninstall-agent
#
# The font is installed to ~/Library/Fonts/sketchybar-app-font.ttf and the
# icon lookup cache is invalidated automatically (see helpers/app_icon.py).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/helpers/app_icon.py"
FONT_DIR="$HOME/Library/Fonts"
FONT_PATH="$FONT_DIR/sketchybar-app-font.ttf"
LATEST_URL="https://github.com/kvndrsslr/sketchybar-app-font/releases/latest/download/sketchybar-app-font.ttf"

AGENT_LABEL="com.sketchybar.app-font-updater"
AGENT_PLIST="$HOME/Library/LaunchAgents/$AGENT_LABEL.plist"
AGENT_LOG="$HOME/Library/Logs/sketchybar-app-font-updater.log"

CHECK_ONLY=0
FORCE=0
QUIET=0
INSTALL_AGENT=0
UNINSTALL_AGENT=0

say() {
    [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"
}

error() {
    printf 'update_app_font: %s\n' "$*" >&2
}

usage() {
    sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
    case "$1" in
        --check) CHECK_ONLY=1 ;;
        --force) FORCE=1 ;;
        --quiet) QUIET=1 ;;
        --install-agent) INSTALL_AGENT=1 ;;
        --uninstall-agent) UNINSTALL_AGENT=1 ;;
        -h | --help) usage; exit 0 ;;
        *)
            error "unknown option: $1"
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if ! command -v python3 >/dev/null 2>&1; then
    error "python3 is required to read the font metadata"
    exit 1
fi

install_agent() {
    mkdir -p "$(dirname "$AGENT_PLIST")" "$(dirname "$AGENT_LOG")"

    cat >"$AGENT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$AGENT_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$SCRIPT_DIR/update_app_font.sh</string>
        <string>--quiet</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>12</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>$AGENT_LOG</string>
    <key>StandardErrorPath</key>
    <string>$AGENT_LOG</string>
</dict>
</plist>
EOF

    launchctl bootout "gui/$(id -u)" "$AGENT_PLIST" >/dev/null 2>&1 || true
    if launchctl bootstrap "gui/$(id -u)" "$AGENT_PLIST" 2>/dev/null; then
        say "Installed daily updater agent: $AGENT_PLIST"
    elif launchctl load -w "$AGENT_PLIST" 2>/dev/null; then
        say "Installed daily updater agent: $AGENT_PLIST"
    else
        error "could not load $AGENT_PLIST"
        exit 1
    fi
}

uninstall_agent() {
    launchctl bootout "gui/$(id -u)" "$AGENT_PLIST" >/dev/null 2>&1 || \
        launchctl unload -w "$AGENT_PLIST" >/dev/null 2>&1 || true
    rm -f "$AGENT_PLIST"
    say "Removed daily updater agent."
}

[ "$UNINSTALL_AGENT" -eq 1 ] && { uninstall_agent; exit 0; }
[ "$INSTALL_AGENT" -eq 1 ] && { install_agent; exit 0; }

installed_release="none"
if [ -f "$FONT_PATH" ]; then
    installed_release="$(python3 "$HELPER" --font "$FONT_PATH" --release 2>/dev/null || true)"
    [ -n "$installed_release" ] || installed_release="unknown"
fi

tmp_font="$(mktemp "${TMPDIR:-/tmp}/sketchybar-app-font.XXXXXX")"
trap 'rm -f "$tmp_font"' EXIT

say "Installed: $installed_release"
say "Fetching latest sketchybar-app-font..."

if ! curl --fail --location --silent --show-error \
    --output "$tmp_font" "$LATEST_URL"; then
    error "download failed (check your network connection)"
    exit 1
fi

latest_release="$(python3 "$HELPER" --font "$tmp_font" --release 2>/dev/null || true)"
if [ -z "$latest_release" ]; then
    error "downloaded file is not a valid sketchybar-app-font"
    exit 1
fi

say "Latest:    $latest_release"

if [ "$CHECK_ONLY" -eq 1 ]; then
    if [ "$installed_release" = "$latest_release" ] && [ "$FORCE" -eq 0 ]; then
        say "sketchybar-app-font is up to date."
        exit 0
    fi
    say "Update available. Run $SCRIPT_DIR/update_app_font.sh to install it."
    exit 10
fi

if [ "$installed_release" = "$latest_release" ] && [ "$FORCE" -eq 0 ]; then
    say "sketchybar-app-font is up to date."
    exit 0
fi

mkdir -p "$FONT_DIR"
if ! install -m 0644 "$tmp_font" "$FONT_PATH"; then
    error "could not write $FONT_PATH"
    exit 1
fi

# Cached lookups are keyed by font mtime/size, but clear explicitly as well.
python3 "$HELPER" --clear-cache >/dev/null 2>&1 || true

say "Installed sketchybar-app-font $latest_release."

if command -v sketchybar >/dev/null 2>&1; then
    if sketchybar --reload >/dev/null 2>&1; then
        say "Reloaded sketchybar."
    else
        say "Installed. Restart sketchybar to pick up the new font."
    fi
else
    say "Installed. Start sketchybar to use the new font."
fi

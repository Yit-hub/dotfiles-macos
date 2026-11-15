#!/bin/sh

# Clicking the item toggles the Wi-Fi name label on/off. The state is kept in
# a marker file so it survives script invocations (updates) and sketchybar
# restarts. The icon stays visible either way.
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/sketchybar"
STATE_FILE="$STATE_DIR/wifi_label_hidden"

case "$1" in
toggle)
  NAME="${2:-$NAME}"
  if [ -f "$STATE_FILE" ]; then
    rm -f "$STATE_FILE"
  else
    mkdir -p "$STATE_DIR"
    : >"$STATE_FILE"
  fi
  ;;
esac

# Get the current Wi-Fi SSID
wifi_name=$(networksetup -listpreferredwirelessnetworks en0 | sed -n '2 p' | tr -d '\t')

# If the Wi-Fi name is empty, set a default value (e.g., "No Wi-Fi")
if [ -z "$wifi_name" ]; then
    wifi_name="Offline"
fi

# Set the Wi-Fi name as the label in SketchyBar
if [ -f "$STATE_FILE" ]; then
    sketchybar --set "$NAME" label.drawing=off
else
    sketchybar --set "$NAME" label="$wifi_name" label.drawing=on
fi

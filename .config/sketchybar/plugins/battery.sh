#!/bin/sh

# Clicking the item toggles its label between the battery percentage and
# icon-only. The state is kept in a marker file so it survives script
# invocations (updates) and sketchybar restarts.
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/sketchybar"
STATE_FILE="$STATE_DIR/battery_label_hidden"

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

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

case "${PERCENTAGE}" in
9[0-9] | 100)
  ICON="􀛨"
  ;;
[6-8][0-9])
  ICON="􀺸"
  ;;
[3-5][0-9])
  ICON="􀺶"
  ;;
[1-2][0-9])
  ICON="􀛩"
  ;;
*) ICON="􀛪" ;;
esac

if [ "$CHARGING" != "" ]; then
  ICON="􀋦"
fi

# The item invoking this script (name $NAME) will get its icon and label
# updated with the current battery status
if [ -f "$STATE_FILE" ]; then
  sketchybar --set "$NAME" icon="$ICON" label.drawing=off
else
  sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%" label.drawing=on
fi

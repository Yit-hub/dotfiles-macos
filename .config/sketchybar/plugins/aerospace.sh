#!/usr/bin/env bash

source "$HOME/.config/sketchybar/helpers/icon_map.sh"

WORKSPACE="$1"

# Get unique app names in this workspace (up to 3)
APP_NAMES=$(aerospace list-windows --workspace "$WORKSPACE" --format "%{app-name}" 2>/dev/null \
  | sort -u | head -3)

# Build icon string from app names
ICON_STR=""
while IFS= read -r app; do
  [[ -z "$app" ]] && continue
  __icon_map "$app"
  ICON_STR+="$icon_result"
done <<< "$APP_NAMES"

if [[ "$WORKSPACE" = "$FOCUSED_WORKSPACE" ]]; then
  # Focused: rose color
  sketchybar --set "$NAME" \
    label.color=0xffebbcba \
    icon="$ICON_STR" \
    icon.color=0xffebbcba
elif [[ -n "$APP_NAMES" ]]; then
  # Occupied, not focused: lavender/purple
  sketchybar --set "$NAME" \
    label.color=0xffc4a7e7 \
    icon="$ICON_STR" \
    icon.color=0xffc4a7e7
else
  # Empty workspace: dim
  sketchybar --set "$NAME" \
    label.color=0xff6e6a86 \
    icon="" \
    icon.color=0xff6e6a86
fi

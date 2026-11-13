#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config/sketchybar"
APP_ICON="$CONFIG_DIR/helpers/app_icon.py"

WORKSPACE="$1"

# AeroSpace only exports FOCUSED_WORKSPACE for aerospace_workspace_change.
# Derive it when this script runs for other events (e.g. front_app_switched).
if [[ -z "${FOCUSED_WORKSPACE:-}" ]]; then
  FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null)
fi

# Get unique app names in this workspace (up to 3)
APP_NAMES=$(aerospace list-windows --workspace "$WORKSPACE" --format "%{app-name}" 2>/dev/null \
  | sort -u | head -3)

# Build icon string from app names (one batched font lookup)
ICON_STR=""
APPS=()
while IFS= read -r app; do
  [[ -z "$app" ]] && continue
  APPS+=("$app")
done <<< "$APP_NAMES"

if [[ ${#APPS[@]} -gt 0 ]]; then
  while IFS= read -r icon; do
    ICON_STR+="$icon"
  done < <(python3 "$APP_ICON" "${APPS[@]}" 2>/dev/null)
fi

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

#!/usr/bin/env bash

APP_ICON="$HOME/.config/sketchybar/helpers/app_icon.py"

if [ "$SENDER" = "front_app_switched" ]; then
  APP="$INFO"
  ICON=$(python3 "$APP_ICON" "$APP" 2>/dev/null)
  sketchybar --set "$NAME" icon="$ICON" label="$APP"
fi

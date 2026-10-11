#!/bin/sh

source "$HOME/.config/sketchybar/helpers/icon_map.sh"

if [ "$SENDER" = "front_app_switched" ]; then
  APP="$INFO"
  __icon_map "$APP"
  sketchybar --set "$NAME" icon="$icon_result" label="$APP"
fi

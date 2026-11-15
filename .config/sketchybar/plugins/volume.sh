#!/bin/sh

# Clicking the item toggles the output mute state.
case "$1" in
toggle)
  NAME="${2:-$NAME}"
  if [ "$(osascript -e 'output muted of (get volume settings)')" = "true" ]; then
    osascript -e 'set volume output muted false'
  else
    osascript -e 'set volume output muted true'
  fi
  ;;
esac

VOLUME="$(osascript -e 'output volume of (get volume settings)')"
MUTED="$(osascript -e 'output muted of (get volume settings)')"

if [ "$MUTED" = "true" ]; then
  ICON="􀊣"
  LABEL="Muted"
else
  case "$VOLUME" in
  [6-9][0-9] | 100)
    ICON="􀊩"
    ;;
  [3-5][0-9])
    ICON="􀊧"
    ;;
  [1-9] | [1-2][0-9])
    ICON="􀊥"
    ;;
  *) ICON="􀊣" ;;
  esac
  LABEL="$VOLUME%"
fi

sketchybar --set "$NAME" icon="$ICON" label="$LABEL"

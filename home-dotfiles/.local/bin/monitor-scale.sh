#!/usr/bin/env bash
# Change the scale of the focused monitor.
# Usage: monitor-scale.sh up|down|reset
# Keeps the monitor's current mode and position, only the scale changes.

set -euo pipefail

STEP=0.25
MIN=0.5
MAX=3

mon=$(hyprctl -j monitors | jq -r '.[] | select(.focused)')
name=$(jq -r '.name' <<<"$mon")
mode=$(jq -r '"\(.width)x\(.height)@\(.refreshRate)"' <<<"$mon")
pos=$(jq -r '"\(.x)x\(.y)"' <<<"$mon")
scale=$(jq -r '.scale' <<<"$mon")

case "${1:-}" in
    up)    new=$(awk -v s="$scale" -v d="$STEP" -v m="$MAX" 'BEGIN { n = s + d; if (n > m) n = m; print n }') ;;
    down)  new=$(awk -v s="$scale" -v d="$STEP" -v m="$MIN" 'BEGIN { n = s - d; if (n < m) n = m; print n }') ;;
    reset) new=1 ;;
    *)     echo "usage: $(basename "$0") up|down|reset" >&2; exit 1 ;;
esac

hyprctl eval "hl.monitor({ output = \"$name\", mode = \"$mode\", position = \"$pos\", scale = \"$new\" })" >/dev/null
hyprctl notify -1 1500 "rgb(88c0d0)" "$name scale: $new"

# The quickshell bar breaks on scale changes; restart it (a full Hyprland reload
# would reset the scale back to the config's value)
sleep 0.3
~/.local/bin/reload-shell --shell-only

#!/usr/bin/env bash
# Toggle the headless (virtual) monitor used for workspaces 7-10.
#
# Off: windows on 7-10 move to the main monitor's current workspace, then the
#      output is removed.
# On:  the output is created, 7-10 are moved onto it, and any other workspace
#      Hyprland put there (e.g. 1) goes back to the main monitor.
# Both: focus goes back to where you were on the main monitor, then Hyprland is
#       reloaded and quickshell restarted (the bar breaks when outputs change).

set -euo pipefail

NAME=HEADLESS-1
WS_FIRST=7
WS_LAST=10

dsp()  { hyprctl dispatch "$1" >/dev/null; }
note() { hyprctl notify -1 1500 "rgb(88c0d0)" "$1" >/dev/null; }
is_headless_ws() { (( $1 >= WS_FIRST && $1 <= WS_LAST )); }

exists() {
    hyprctl -j monitors all | jq -e --arg n "$NAME" 'any(.[]; .name == $n)' >/dev/null
}

main=$(hyprctl -j monitors | jq -r --arg n "$NAME" '[.[] | select(.name != $n)][0].name')
main_ws=$(hyprctl -j monitors | jq -r --arg m "$main" '.[] | select(.name == $m) | .activeWorkspace.id')
is_headless_ws "$main_ws" && main_ws=1

back_to_main() {
    dsp "hl.dsp.focus({ monitor = \"$main\" })"
    dsp "hl.dsp.focus({ workspace = $main_ws })"
}

if exists; then
    # Bring every window on 7-10 over to the main monitor
    hyprctl -j clients | jq -r --argjson a "$WS_FIRST" --argjson b "$WS_LAST" \
        '.[] | select(.workspace.id >= $a and .workspace.id <= $b) | .address' |
    while read -r addr; do
        dsp "hl.dsp.window.move({ workspace = $main_ws, follow = false, window = \"address:$addr\" })"
    done

    back_to_main
    hyprctl output remove "$NAME" >/dev/null
    sleep 0.2
    back_to_main
    note "$NAME off"
else
    hyprctl output create headless "$NAME" >/dev/null
    for _ in $(seq 20); do exists && break; sleep 0.1; done

    for ((i = WS_FIRST; i <= WS_LAST; i++)); do
        dsp "hl.dsp.workspace.move({ workspace = $i, monitor = \"$NAME\" })"
    done

    # Show 7 on the headless monitor
    dsp "hl.dsp.focus({ monitor = \"$NAME\" })"
    dsp "hl.dsp.focus({ workspace = $WS_FIRST })"

    # Send back anything else that landed on it
    hyprctl -j workspaces | jq -r --arg n "$NAME" '.[] | select(.monitor == $n) | .id' |
    while read -r id; do
        is_headless_ws "$id" || dsp "hl.dsp.workspace.move({ workspace = $id, monitor = \"$main\" })"
    done

    back_to_main
    note "$NAME on"
fi

# The quickshell bar breaks when outputs change; reload Hyprland + quickshell
sleep 0.3
~/.local/bin/reload-shell

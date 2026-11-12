#!/usr/bin/env bash
# webapp-wrapper.sh — create desktop web apps with a browser of your choice.
#
# Usage:
#   webapp-wrapper.sh                         # fully interactive
#   webapp-wrapper.sh -n WhatsApp -u web.whatsapp.com -b google-chrome-stable
#   webapp-wrapper.sh -i https://example.com/icon.png ...
#   webapp-wrapper.sh --list
#   webapp-wrapper.sh --remove

set -euo pipefail

APP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"

# "Display name|binary" — only the ones found in PATH are offered.
KNOWN_BROWSERS=(
    "Google Chrome (stable)|google-chrome-stable"
    "Google Chrome|google-chrome"
    "Google Chrome (beta)|google-chrome-beta"
    "Google Chrome (unstable)|google-chrome-unstable"
    "Chromium|chromium"
    "Brave|brave"
    "Brave|brave-browser"
    "Microsoft Edge|microsoft-edge-stable"
    "Microsoft Edge|microsoft-edge"
    "Vivaldi|vivaldi-stable"
    "Vivaldi|vivaldi"
    "Helium|helium-browser"
    "Thorium|thorium-browser"
    "Firefox|firefox"
    "Epiphany|epiphany"
)

ask() { # ask "Prompt" [default]
    local reply
    if [[ -n "${2:-}" ]]; then
        read -rp "$1 [$2]: " reply || true
        echo "${reply:-$2}"
    else
        read -rp "$1: " reply || true
        echo "$reply"
    fi
}

safe_name() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/_/g; s/^_+|_+$//g'
}

select_browser() {
    local found=() entry name bin choice i
    for entry in "${KNOWN_BROWSERS[@]}"; do
        bin="${entry#*|}"
        command -v "$bin" &>/dev/null && found+=("$entry")
    done

    echo >&2
    echo "Available browsers:" >&2
    for i in "${!found[@]}"; do
        name="${found[$i]%%|*}"; bin="${found[$i]#*|}"
        printf '  %d. %s  (%s)\n' "$((i + 1))" "$name" "$bin" >&2
    done
    printf '  %d. Custom command\n' "$(( ${#found[@]} + 1 ))" >&2

    while true; do
        choice=$(ask "Select a browser" 1)
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            if (( choice >= 1 && choice <= ${#found[@]} )); then
                echo "${found[$((choice - 1))]#*|}"
                return
            elif (( choice == ${#found[@]} + 1 )); then
                bin=$(ask "Browser command (e.g. google-chrome-stable)")
                [[ -n "$bin" ]] && { echo "$bin"; return; }
            fi
        fi
        echo "Invalid selection." >&2
    done
}

# download_icon <url> <dest> — succeeds only if we got a real image
download_icon() {
    local tmp
    tmp=$(mktemp)
    if curl -fsL -A "$UA" --max-time 15 -o "$tmp" "$1" \
        && [[ -s "$tmp" ]] \
        && file --mime-type -b "$tmp" | grep -q '^image/'; then
        mv "$tmp" "$2"
        return 0
    fi
    rm -f "$tmp"
    return 1
}

fetch_icon() { # fetch_icon <site-url> <dest>
    local domain="$1"
    domain="${domain#*://}"; domain="${domain%%/*}"
    local sources=(
        "https://${domain}/apple-touch-icon.png"
        "https://www.google.com/s2/favicons?domain=${domain}&sz=256"
        "https://icons.duckduckgo.com/ip3/${domain}.ico"
        "https://${domain}/favicon.ico"
    )
    local src
    for src in "${sources[@]}"; do
        download_icon "$src" "$2" && return 0
    done
    return 1
}

list_webapps() {
    local f
    shopt -s nullglob
    for f in "$APP_DIR"/webapp-*.desktop; do
        printf '%s\t%s\t%s\n' "$(grep -m1 '^Name=' "$f" | cut -d= -f2-)" \
            "$(grep -m1 '^Exec=' "$f" | cut -d= -f2-)" "$f"
    done
}

remove_webapp() {
    mapfile -t apps < <(list_webapps)
    if (( ${#apps[@]} == 0 )); then
        echo "No web apps found."
        return
    fi
    echo "Installed web apps:"
    local i
    for i in "${!apps[@]}"; do
        printf '  %d. %s\n' "$((i + 1))" "$(cut -f1 <<<"${apps[$i]}")"
    done
    local choice
    choice=$(ask "Number to remove (Enter to cancel)")
    [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#apps[@]} )) || return 0

    local name path icon
    name=$(cut -f1 <<<"${apps[$((choice - 1))]}")
    path=$(cut -f3 <<<"${apps[$((choice - 1))]}")
    icon=$(grep -m1 '^Icon=' "$path" | cut -d= -f2-)
    rm -f "$path"
    [[ "$icon" == "$ICON_DIR"/*_webapp.png ]] && rm -f "$icon"
    update-desktop-database "$APP_DIR" &>/dev/null || true
    echo "Removed '$name'."
}

usage() {
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
}

main() {
    local name="" url="" browser="" icon_url=""

    while (( $# )); do
        case "$1" in
            -n|--name)    name="$2"; shift 2 ;;
            -u|--url)     url="$2"; shift 2 ;;
            -b|--browser) browser="$2"; shift 2 ;;
            -i|--icon)    icon_url="$2"; shift 2 ;;
            -l|--list)    list_webapps | column -t -s $'\t'; exit 0 ;;
            -r|--remove)  remove_webapp; exit 0 ;;
            -h|--help)    usage; exit 0 ;;
            *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
        esac
    done

    echo "=== WebApp Creator ==="

    [[ -z "$name" ]] && name=$(ask "Name of the web app")
    [[ -z "$name" ]] && { echo "Error: name is required." >&2; exit 1; }

    [[ -z "$url" ]] && url=$(ask "URL (e.g. web.whatsapp.com)")
    [[ -z "$url" ]] && { echo "Error: URL is required." >&2; exit 1; }
    [[ "$url" =~ ^https?:// ]] || url="https://$url"

    [[ -z "$browser" ]] && browser=$(select_browser)
    if ! command -v "${browser%% *}" &>/dev/null; then
        echo "Warning: '${browser%% *}' not found in PATH; creating the entry anyway." >&2
    fi

    local safe icon_path desktop_file
    safe=$(safe_name "$name")
    mkdir -p "$APP_DIR" "$ICON_DIR"
    icon_path="$ICON_DIR/${safe}_webapp.png"
    desktop_file="$APP_DIR/webapp-${safe}.desktop"

    [[ -z "$icon_url" ]] && icon_url=$(ask "Icon URL (Enter to auto-fetch from the site)" "")
    if [[ -n "$icon_url" ]]; then
        echo "Downloading icon..."
        download_icon "$icon_url" "$icon_path" || { echo "Icon download failed." >&2; icon_path=""; }
    else
        echo "Fetching site icon..."
        fetch_icon "$url" "$icon_path" || { echo "Couldn't find an icon." >&2; icon_path=""; }
    fi

    local exec_cmd wm_class domain
    domain="${url#*://}"; domain="${domain%%/*}"
    case "$browser" in
        *firefox*)  exec_cmd="$browser --new-window $url"; wm_class="firefox" ;;
        *epiphany*) exec_cmd="$browser --application-mode $url"; wm_class="epiphany" ;;
        *)          exec_cmd="$browser --app=$url"; wm_class="$domain" ;;
    esac

    cat > "$desktop_file" <<EOF
[Desktop Entry]
Version=1.0
Name=$name
Comment=Web App for $name
Exec=$exec_cmd
StartupWMClass=$wm_class
Terminal=false
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
Icon=${icon_path:-web-browser}
EOF
    chmod 755 "$desktop_file"
    update-desktop-database "$APP_DIR" &>/dev/null || true

    echo
    echo "Created: $desktop_file"
    echo "  Exec: $exec_cmd"
    echo "  Icon: ${icon_path:-web-browser (fallback)}"
}

main "$@"

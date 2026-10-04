#!/usr/bin/env bash

# File to store state (last used directory and image)
STATE_FILE="$HOME/.cache/wp-rotate-state"
LOCK_FILE="$HOME/.cache/wp-rotate.lock"
PID_FILE="$HOME/.cache/wp-rotate.pid"

# Default values
MODE="next"
TIMER="10"
DURATION="2"
DEFAULT_WP_DIR="$HOME/.config/hypr/wallpapers"
WP_DIR="$DEFAULT_WP_DIR"
STOP=0
ORIGINAL_ARGS=("$@")

usage() {
    printf 'Usage: %s [-h] [-k] [-r | -n] [-l seconds] [-d seconds] [directory]\n' "$0"
    printf 'Cycle through wallpapers in a directory. The directory is remembered between runs.\n\n'
    printf 'Options:\n'
    printf '  -h          Show this help message\n'
    printf '  -r          Select a random wallpaper\n'
    printf '  -n          Select the next wallpaper (default)\n'
    printf '  -l seconds  Repeat in the background (default: 10)\n'
    printf '  -d seconds  Set the wallpaper fade duration (default: 2)\n'
    printf '  -k          Stop background rotation\n'
    printf 'Default directory: %s\n' "$DEFAULT_WP_DIR"
}

# Load previous state if it exists
if [ -f "$STATE_FILE" ]; then
    source "$STATE_FILE"
fi

# Parse flags
while getopts ":rnhkl:d:" opt; do
  case ${opt} in
    r )
      MODE="random"
      ;;
    n )
      MODE="next"
      ;;
    l )
      TIMER=$OPTARG
      ;;
        d )
            DURATION=$OPTARG
            ;;
        k )
            STOP=1
            ;;
        h )
            usage
            exit 0
            ;;
    \? )
      echo "Usage: $0 [-r (random)] [-n (next)] [-l timer_in_seconds] [directory]"
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

if [ -n "$DURATION" ] && [[ ! "$DURATION" =~ ^([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]]; then
    echo "Error: Transition duration must be a non-negative number of seconds."
    exit 1
fi

if [ "$STOP" -eq 1 ]; then
    mkdir -p "$(dirname "$LOCK_FILE")"
    exec 9>"$LOCK_FILE" || { echo "Error: Could not open rotation lock."; exit 1; }
    if flock -n 9; then
        rm -f "$PID_FILE"
        echo "No timed rotation is running."
    elif [ -r "$PID_FILE" ]; then
        read -r LOOP_PID < "$PID_FILE"
        if [[ "$LOOP_PID" =~ ^[0-9]+$ ]] && kill -0 "$LOOP_PID" 2>/dev/null; then
            if kill -TERM "$LOOP_PID" 2>/dev/null; then
                printf 'Stopping timed rotation (PID %s).\n' "$LOOP_PID"
            else
                printf 'Could not stop timed rotation (PID %s).\n' "$LOOP_PID"
                exit 1
            fi
        else
            echo "Timed rotation is starting; try again in a moment."
        fi
    else
        echo "Timed rotation is starting; try again in a moment."
    fi
    exit 0
fi

# Check for a directory argument
if [ -n "$1" ]; then
    WP_DIR="$(realpath "$1")"
elif [ ! -d "$WP_DIR" ] && [ -d "$DEFAULT_WP_DIR" ]; then
    WP_DIR="$DEFAULT_WP_DIR"
fi

# Validate directory
if [ -z "$WP_DIR" ] || [ ! -d "$WP_DIR" ]; then
    printf 'Error: No valid wallpaper directory found (default: %s).\n' "$DEFAULT_WP_DIR"
    echo "Usage: $0 [-r] [-n] [-l timer] /path/to/wallpapers"
    exit 1
fi

mapfile -d $'\0' -n 1 FIRST_IMAGE < <(find "$WP_DIR" -type f \( -iname \*.jpg -o -iname \*.jpeg -o -iname \*.png -o -iname \*.gif -o -iname \*.webp \) -print0)
if [ ${#FIRST_IMAGE[@]} -eq 0 ]; then
    printf 'Error: No supported images found in wallpaper directory: %s\n' "$WP_DIR"
    exit 1
fi

# Start at most one background worker for timed rotation.
if [[ -n "$TIMER" ]] && [[ "$TIMER" =~ ^[0-9]+$ ]] && [ "$TIMER" -gt 0 ] && [ "${WP_ROTATE_BACKGROUND:-0}" != "1" ]; then
    mkdir -p "$(dirname "$LOCK_FILE")"
    exec 9>"$LOCK_FILE" || { echo "Error: Could not open rotation lock."; exit 1; }
    if ! flock -n 9; then
        if [ -r "$PID_FILE" ]; then
            read -r LOOP_PID < "$PID_FILE"
            if [[ "$LOOP_PID" =~ ^[0-9]+$ ]]; then
                printf 'Timed rotation is already running (PID %s).\n' "$LOOP_PID"
            else
                echo "Timed rotation is already starting."
            fi
        else
            echo "Timed rotation is already starting."
        fi
        exit 0
    fi
    nohup env WP_ROTATE_BACKGROUND=1 "$0" "${ORIGINAL_ARGS[@]}" 9>&9 </dev/null >/dev/null 2>&1 &
    LOOP_PID=$!
    printf '%s\n' "$LOOP_PID" > "$PID_FILE"
    printf 'Wallpaper rotation started in the background (PID %s).\n' "$LOOP_PID"
    exit 0
fi

rotate_once() {
# Get all images in the directory and subdirectories safely
# Handles spaces in filenames using mapfile and find -print0
mapfile -d $'\0' IMAGES < <(find "$WP_DIR" -type f \( -iname \*.jpg -o -iname \*.jpeg -o -iname \*.png -o -iname \*.gif -o -iname \*.webp \) -print0 | sort -z)

if [ ${#IMAGES[@]} -eq 0 ]; then
    echo "Error: No images found in $WP_DIR"
    exit 1
fi

# Determine the next image to set
NEXT_IMG=""

if [ "$MODE" = "random" ]; then
    if [ ${#IMAGES[@]} -eq 1 ]; then
        NEXT_IMG="${IMAGES[0]}"
    else
        # Loop until we get a different image than the last one
        while true; do
            RAND_INDEX=$((RANDOM % ${#IMAGES[@]}))
            NEXT_IMG="${IMAGES[$RAND_INDEX]}"
            if [ "$NEXT_IMG" != "$LAST_IMG" ]; then
                break
            fi
        done
    fi
else
    # Sequential "next" mode
    NEXT_INDEX=0
    for i in "${!IMAGES[@]}"; do
        if [ "${IMAGES[$i]}" = "$LAST_IMG" ]; then
            NEXT_INDEX=$(( (i + 1) % ${#IMAGES[@]} ))
            break
        fi
    done
    NEXT_IMG="${IMAGES[$NEXT_INDEX]}"
fi

# Set the wallpaper
# Tries to find wp-set.sh in PATH or in the same directory as this script
WP_SET_SCRIPT="$(dirname "$(realpath "$0")")/wp-set.sh"
if command -v wp-set.sh &> /dev/null; then
    WP_SET_COMMAND=(wp-set.sh)
elif [ -x "$WP_SET_SCRIPT" ]; then
    WP_SET_COMMAND=("$WP_SET_SCRIPT")
else
    echo "Error: wp-set.sh not found."
    exit 1
fi

if [ -n "$DURATION" ]; then
    "${WP_SET_COMMAND[@]}" -d "$DURATION" "$NEXT_IMG"
else
    "${WP_SET_COMMAND[@]}" "$NEXT_IMG"
fi

# Save the new state
mkdir -p "$(dirname "$STATE_FILE")"
echo "WP_DIR=\"$WP_DIR\"" > "$STATE_FILE"
echo "LAST_IMG=\"$NEXT_IMG\"" >> "$STATE_FILE"
LAST_IMG="$NEXT_IMG"
}

if [[ -n "$TIMER" ]] && [[ "$TIMER" =~ ^[0-9]+$ ]] && [ "$TIMER" -gt 0 ]; then
    printf '%s\n' "$$" > "$PID_FILE"
    SLEEP_PID=""
    stop_rotation() {
        if [ -n "$SLEEP_PID" ]; then
            kill "$SLEEP_PID" 2>/dev/null || true
        fi
        exit 0
    }
    trap 'rm -f "$PID_FILE"' EXIT
    trap stop_rotation TERM INT
    while true; do
        rotate_once
        sleep "$TIMER" &
        SLEEP_PID=$!
        wait "$SLEEP_PID"
        SLEEP_PID=""
    done
fi

rotate_once

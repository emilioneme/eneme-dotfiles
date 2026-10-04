#!/usr/bin/env bash

usage() {
    printf 'Usage: %s [-d seconds] [path-to-image]\n' "$0"
    printf 'Defaults: duration 2 seconds; image %s\n' "$DEFAULT_IMAGE"
}

DEFAULT_IMAGE="$HOME/.config/hypr/wallpapers/00.jpg"
DURATION="2"
while getopts ":d:" opt; do
    case "$opt" in
        d) DURATION="$OPTARG" ;;
        \?) usage; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

if [ -n "$1" ]; then
    IMAGE_PATH="$1"
else
    if [ ! -f "$DEFAULT_IMAGE" ]; then
        printf 'Error: No image path given and the default image was not found: %s\n' "$DEFAULT_IMAGE"
        exit 1
    fi
    IMAGE_PATH="$DEFAULT_IMAGE"
fi

if [ -n "$DURATION" ] && [[ ! "$DURATION" =~ ^([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]]; then
    echo "Error: Transition duration must be a non-negative number of seconds."
    exit 1
fi

# Check if the file exists
if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: File not found: $IMAGE_PATH"
    exit 1
fi

if [ -n "$DURATION" ]; then
    awww img --transition-type fade --transition-duration "$DURATION" "$IMAGE_PATH"
else
    awww img "$IMAGE_PATH"
fi

#!/usr/bin/env bash
# Pick a systemd-boot entry (or firmware setup) and reboot into it once.
# Later boots go back to the default entry.
#
# Uses logind (systemctl reboot --boot-loader-entry / --firmware-setup), so it
# needs no root and no knowledge of the local entry names.

set -uo pipefail

LOADER_GUID="4a67b082-0a4c-41cf-b6c7-440b29bb8c4f"
FIRMWARE="@firmware"
DRY_RUN=0

usage() {
    printf 'Usage: %s [-h] [-l] [-n] [ENTRY]\n' "${0##*/}"
    printf 'Reboot once into a systemd-boot entry or the firmware setup.\n'
    printf 'With no ENTRY, shows a menu.\n\n'
    printf 'Options:\n'
    printf '  -h  Show this help message\n'
    printf '  -l  List the available targets and exit\n'
    printf '  -n  Dry run: show what would happen, do not reboot\n\n'
    printf 'ENTRY is an entry ID, "firmware", or any unique part of a name (e.g. "windows").\n'
}

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

# Read a systemd-boot EFI variable (UTF-16LE after a 4-byte attribute header).
efi_var() {
    local f="/sys/firmware/efi/efivars/$1-$LOADER_GUID"
    [ -r "$f" ] || return 0
    tail -c +5 "$f" | iconv -f UTF-16LE -t UTF-8 2>/dev/null | tr -d '\0'
}

logind_can() {
    busctl call org.freedesktop.login1 /org/freedesktop/login1 \
        org.freedesktop.login1.Manager "$1" 2>/dev/null | grep -qE '"(yes|challenge)"'
}

# Human-readable name for an entry ID: the entry file's title if readable,
# otherwise a guess from the ID.
entry_title() {
    local id="$1" dir title
    for dir in /boot /efi /boot/efi; do
        if [ -r "$dir/loader/entries/$id" ]; then
            title="$(sed -n 's/^title[[:space:]]\+//p' "$dir/loader/entries/$id" | head -n 1)"
            [ -n "$title" ] && { printf '%s' "$title"; return; }
        fi
    done
    case "$id" in
        auto-windows)                  printf 'Windows' ;;
        auto-osx)                      printf 'macOS' ;;
        auto-efi-shell)                printf 'EFI Shell' ;;
        auto-efi-default)              printf 'EFI default loader' ;;
        auto-reboot-to-firmware-setup) printf 'Firmware setup (UEFI/BIOS)' ;;
        *.conf|*.efi)                  printf '%s' "${id%.*}" ;;
        *)                             printf '%s' "$id" ;;
    esac
}

LIST_ONLY=0
while getopts ":hln" opt; do
    case "$opt" in
        h) usage; exit 0 ;;
        l) LIST_ONLY=1 ;;
        n) DRY_RUN=1 ;;
        \?) usage >&2; exit 1 ;;
    esac
done
shift $((OPTIND - 1))
QUERY="${1:-}"

# --- Collect targets --------------------------------------------------------

mapfile -t entries < <(systemctl reboot --boot-loader-entry=help 2>/dev/null)
[ "${#entries[@]}" -gt 0 ] || die "No boot loader entries found. Is this system booted with systemd-boot?"

current="$(efi_var LoaderEntrySelected)"
default="$(efi_var LoaderEntryDefault)"
firmware_ok=0
logind_can CanRebootToFirmwareSetup && firmware_ok=1

ids=()
labels=()
for id in "${entries[@]}"; do
    case "$id" in
        auto-reboot|auto-poweroff) continue ;;  # not useful as reboot targets
        auto-reboot-to-firmware-setup) [ "$firmware_ok" -eq 1 ] && continue ;;  # covered by @firmware
    esac
    label="$(entry_title "$id")"
    tags=()
    [ "$id" = "$current" ] && tags+=("current")
    [ "$id" = "$default" ] && tags+=("default")
    tagstr="${tags[*]}"
    [ -n "$tagstr" ] && label+=" (${tagstr// /, })"
    ids+=("$id")
    labels+=("$label")
done
if [ "$firmware_ok" -eq 1 ]; then
    ids+=("$FIRMWARE")
    labels+=("Firmware setup (UEFI/BIOS)")
fi

if [ "$LIST_ONLY" -eq 1 ]; then
    for i in "${!ids[@]}"; do
        printf '%-40s %s\n' "${ids[i]}" "${labels[i]}"
    done
    exit 0
fi

# --- Choose a target --------------------------------------------------------

choice=""
if [ -n "$QUERY" ]; then
    q="${QUERY,,}"
    [ "$q" = "firmware" ] || [ "$q" = "bios" ] || [ "$q" = "uefi" ] && q="firmware setup"
    matches=()
    for i in "${!ids[@]}"; do
        if [ "${ids[i],,}" = "$q" ]; then matches=("$i"); break; fi
        [[ "${ids[i],,}" == *"$q"* || "${labels[i],,}" == *"$q"* ]] && matches+=("$i")
    done
    case "${#matches[@]}" in
        0) die "No target matches '$QUERY'. Run with -l to list them." ;;
        1) choice="${ids[matches[0]]}" ;;
        *) printf "'%s' matches several targets:\n" "$QUERY" >&2
           for i in "${matches[@]}"; do printf '  %-40s %s\n' "${ids[i]}" "${labels[i]}" >&2; done
           exit 1 ;;
    esac
elif command -v fzf >/dev/null && [ -t 0 ] && [ -t 1 ]; then
    choice="$(for i in "${!ids[@]}"; do printf '%s\t%s\n' "${labels[i]}" "${ids[i]}"; done |
        fzf --delimiter=$'\t' --with-nth=1 --height=~40% --reverse --no-multi \
            --prompt='Reboot into > ' --header='Enter: reboot   Esc: cancel' |
        cut -f2)"
elif command -v whiptail >/dev/null && [ -t 0 ]; then
    menu=()
    for i in "${!ids[@]}"; do menu+=("$((i + 1))" "${labels[i]}"); done
    n="$(whiptail --title 'Smart reboot' --menu 'Reboot into:' 0 0 0 "${menu[@]}" 3>&1 1>&2 2>&3)" &&
        choice="${ids[n - 1]}"
else
    PS3='Reboot into (number, empty to cancel): '
    select picked in "${labels[@]}"; do
        [ -n "$REPLY" ] || break
        [ -n "$picked" ] && { choice="${ids[REPLY - 1]}"; break; }
    done
fi

[ -n "$choice" ] || { echo "Cancelled."; exit 0; }

# --- Reboot -----------------------------------------------------------------

if [ "$choice" = "$FIRMWARE" ]; then
    cmd=(systemctl reboot --firmware-setup)
    desc="firmware setup (UEFI/BIOS)"
else
    cmd=(systemctl reboot "--boot-loader-entry=$choice")
    desc="$(entry_title "$choice") [$choice]"
fi

echo "Next boot: $desc"
if [ "$DRY_RUN" -eq 1 ]; then
    printf 'Dry run, would run: %s\n' "${cmd[*]}"
    exit 0
fi

if ! "${cmd[@]}"; then
    # logind refused (e.g. remote session without polkit rights): set it with bootctl.
    [ "$choice" = "$FIRMWARE" ] && die "Could not request a reboot into firmware setup."
    echo "logind refused; trying bootctl with sudo."
    sudo bootctl set-oneshot "$choice" || die "Could not set the one-shot boot entry."
    systemctl reboot
fi

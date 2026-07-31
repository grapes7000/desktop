#!/usr/bin/env bash
set -euo pipefail

c_reset=$'\e[0m'; c_blue=$'\e[1;34m'; c_green=$'\e[1;32m'
c_yellow=$'\e[1;33m'; c_red=$'\e[1;31m'; c_dim=$'\e[2m'
info() { printf '%s==>%s %s\n' "$c_blue" "$c_reset" "$*"; }
ok()   { printf '%s  ✓%s %s\n' "$c_green" "$c_reset" "$*"; }
warn() { printf '%s  !%s %s\n' "$c_yellow" "$c_reset" "$*"; }
err()  { printf '%s  ✗%s %s\n' "$c_red" "$c_reset" "$*" >&2; }

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/linux-setup"
LOG_FILE="$STATE_DIR/install.log"
mkdir -p "$STATE_DIR/groups"

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }
log() { printf '[%s] %s\n' "$(timestamp)" "$*" >> "$LOG_FILE"; }

has() { command -v "$1" >/dev/null 2>&1; }

run() {
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        printf '%s[dry-run]%s ' "$c_dim" "$c_reset"
        printf '%q ' "$@"
        printf '\n'
        return 0
    fi
    log "RUN: $*"
    "$@"
}

confirm() {
    local prompt="$1"
    [ "${ASSUME_YES:-0}" -eq 1 ] && return 0
    [ -t 0 ] || return 1
    read -r -p "$prompt [y/N] " answer
    case "$answer" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

read_list() {
    local file="$1"
    [ -f "$file" ] || return 0
    sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$file"
}

mark_group() {
    local group="$1"
    [ "${DRY_RUN:-0}" -eq 1 ] && return 0
    printf '%s\n' "$(timestamp)" > "$STATE_DIR/groups/$group"
}

section() {
    printf '\n%s── %s ──%s\n' "$c_blue" "$*" "$c_reset"
}

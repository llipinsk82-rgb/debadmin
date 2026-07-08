#!/usr/bin/env bash

DAT_NAME="Debian Admin Toolkit"
DAT_VERSION_FILE="$DAT_HOME/VERSION"
DAT_VERSION="unknown"

if [[ -f "$DAT_VERSION_FILE" ]]; then
    DAT_VERSION="$(tr -d '[:space:]' < "$DAT_VERSION_FILE")"
fi

LIB_DIR="${LIB_DIR:-$DAT_HOME/lib}"
MODULE_DIR="${MODULE_DIR:-$DAT_HOME/modules}"

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

load_library() {
    local name="$1"
    local file="$LIB_DIR/$name.sh"

    [[ -f "$file" ]] || die "Library '$name' not found: $file"
    source "$file"
}

run_module() {
    local name="$1"
    shift || true

    local module="$MODULE_DIR/$name"

    if [[ ! -x "$module" ]]; then
        printf 'Unknown command: %s\n\n' "$name" >&2
        module="$MODULE_DIR/menu"
    fi

    exec "$module" "$@"
}

require_root() {
    [[ "${EUID:-$(id -u)}" -eq 0 ]] || die "Run this command as root."
}

dat_version() {
    printf '%s %s\n' "$DAT_NAME" "$DAT_VERSION"
}

dat_help() {
    cat <<EOF
$DAT_NAME $DAT_VERSION

Usage:
  deb [command]

Commands:
  menu       Show command panel
  health     Show health dashboard
  doctor     Run diagnostics and health checks
  services   Manage and inspect services
  ports      Inspect listening ports
  logs       Browse and filter system logs
  backup     Create and manage backups
  update     Run safe APT update workflow

Options:
  -h, --help       Show help
  -v, --version    Show version
EOF
}

clamp_percent() {
    local value="${1:-0}"

    [[ "$value" =~ ^[0-9]+$ ]] || value=0

    if (( value < 0 )); then
        value=0
    elif (( value > 100 )); then
        value=100
    fi

    printf '%s\n' "$value"
}

#!/usr/bin/env bash

DAT_VERSION="0.1.0"

LIB_DIR="$DAT_HOME/lib"
MODULE_DIR="$DAT_HOME/modules"
CONFIG_DIR="$DAT_HOME/config"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

load_library() {
    local file="$LIB_DIR/$1.sh"

    [[ -f "$file" ]] || die "Library '$1' not found."

    source "$file"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_root() {
    [[ $EUID -eq 0 ]] || die "Run as root."
}

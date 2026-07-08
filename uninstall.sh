#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-/opt/debian-admin-toolkit}"
BIN_DIR="${BIN_DIR:-/usr/local/bin}"
CONFIG_DIR="${CONFIG_DIR:-/etc/debian-admin-toolkit}"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Run uninstaller as root." >&2
    exit 1
fi

rm -f "$BIN_DIR/deb"
rm -rf "$PREFIX"
rm -rf "$CONFIG_DIR"

echo "Debian Admin Toolkit removed."

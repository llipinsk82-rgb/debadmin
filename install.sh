#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-/opt/debian-admin-toolkit}"
BIN_DIR="${BIN_DIR:-/usr/local/bin}"
CONFIG_DIR="${CONFIG_DIR:-/etc/debian-admin-toolkit}"
DEFAULT_SERVICES="ssh cron nginx oscam-panel blackserv oscam"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Run installer as root." >&2
    exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install -d "$PREFIX" "$PREFIX/bin" "$PREFIX/lib" "$PREFIX/modules" "$CONFIG_DIR" "$BIN_DIR"

cp -R "$ROOT_DIR/bin" "$ROOT_DIR/lib" "$ROOT_DIR/modules" "$ROOT_DIR/docs" "$PREFIX/" 2>/dev/null || true
cp "$ROOT_DIR/VERSION" "$ROOT_DIR/README.md" "$ROOT_DIR/LICENSE" "$PREFIX/" 2>/dev/null || true

cat > "$CONFIG_DIR/config" <<EOF
DAT_HOME="$PREFIX"
DAT_SERVICES="${DAT_SERVICES:-$DEFAULT_SERVICES}"
DAT_SHOW_MISSING_SERVICES="${DAT_SHOW_MISSING_SERVICES:-0}"
DAT_BACKUP_DIR="${DAT_BACKUP_DIR:-/var/backups/debian-admin-toolkit}"
EOF

chmod +x "$PREFIX/bin/deb" "$PREFIX/modules/"* 2>/dev/null || true
ln -sf "$PREFIX/bin/deb" "$BIN_DIR/deb"

echo "Debian Admin Toolkit installed."
echo "Run: deb health"

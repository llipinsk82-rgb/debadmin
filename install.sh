#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="/opt/debian-admin-toolkit"
CONFIG_DIR="/etc/debian-admin-toolkit"
CONFIG_FILE="$CONFIG_DIR/config"
BIN_LINK="/usr/local/bin/deb"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_root() {
    if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
        echo "Uruchom instalator jako root, np.: sudo bash install.sh" >&2
        exit 1
    fi
}

install_files() {
    echo "Instaluję Debian Admin Toolkit w $INSTALL_DIR..."

    mkdir -p "$INSTALL_DIR" "$CONFIG_DIR"

    rm -rf \
        "$INSTALL_DIR/bin" \
        "$INSTALL_DIR/lib" \
        "$INSTALL_DIR/modules" \
        "$INSTALL_DIR/scripts"

    cp -a "$SOURCE_DIR/bin" "$INSTALL_DIR/"
    cp -a "$SOURCE_DIR/lib" "$INSTALL_DIR/"
    cp -a "$SOURCE_DIR/modules" "$INSTALL_DIR/"
    cp -a "$SOURCE_DIR/scripts" "$INSTALL_DIR/"

    if [[ -f "$SOURCE_DIR/VERSION" ]]; then
        cp -a "$SOURCE_DIR/VERSION" "$INSTALL_DIR/VERSION"
    fi

    chmod 0755 "$INSTALL_DIR/bin/deb"
    find "$INSTALL_DIR/modules" "$INSTALL_DIR/scripts" -type f -exec chmod 0755 {} +
}

write_config() {
    cat > "$CONFIG_FILE" <<EOF
DAT_HOME="$INSTALL_DIR"
EOF

    chmod 0644 "$CONFIG_FILE"
}

install_launcher() {
    ln -sfn "$INSTALL_DIR/bin/deb" "$BIN_LINK"
}

configure_shell_colors() {
    echo "Ustawiam kolorowy prompt Bash dla roota i zwykłych użytkowników..."
    bash "$INSTALL_DIR/scripts/setup-shell-colors.sh"
}

main() {
    require_root
    install_files
    write_config
    install_launcher
    configure_shell_colors

    echo
    echo "Instalacja zakończona."
    echo "Polecenie panelu: deb"
    echo "Kolory pojawią się po ponownym zalogowaniu lub wykonaniu: source ~/.bashrc"
}

main "$@"

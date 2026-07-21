#!/usr/bin/env bash

set -euo pipefail

START_MARKER="# >>> debadmin colored prompt >>>"
END_MARKER="# <<< debadmin colored prompt <<<"

require_root() {
    if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
        echo "Uruchom skrypt jako root." >&2
        exit 1
    fi
}

prompt_for_user() {
    local username="$1"

    if [[ "$username" == "root" ]]; then
        # root@host: czerwony, ścieżka: niebieska
        printf '%s' "export PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\\$ '"
    else
        # user@host: zielony, ścieżka: niebieska
        printf '%s' "export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\\$ '"
    fi
}

configure_user() {
    local username="$1"
    local home_dir shell rc_file tmp_file prompt

    home_dir="$(getent passwd "$username" | cut -d: -f6)"
    shell="$(getent passwd "$username" | cut -d: -f7)"

    if [[ -z "$home_dir" || ! -d "$home_dir" ]]; then
        echo "Pomijam $username: brak katalogu domowego."
        return 0
    fi

    case "$shell" in
        */bash|*/sh) ;;
        *)
            echo "Pomijam $username: powłoka $shell nie używa .bashrc."
            return 0
            ;;
    esac

    rc_file="$home_dir/.bashrc"
    touch "$rc_file"

    tmp_file="$(mktemp)"
    awk -v start="$START_MARKER" -v end="$END_MARKER" '
        $0 == start {skip=1; next}
        $0 == end   {skip=0; next}
        !skip       {print}
    ' "$rc_file" > "$tmp_file"

    prompt="$(prompt_for_user "$username")"

    {
        cat "$tmp_file"
        printf '\n%s\n%s\n%s\n' "$START_MARKER" "$prompt" "$END_MARKER"
    } > "$rc_file"

    rm -f "$tmp_file"

    chown "$username:$(id -gn "$username")" "$rc_file"
    chmod 0644 "$rc_file"

    echo "Ustawiono kolorowy prompt dla: $username"
}

main() {
    require_root

    if (( $# > 0 )); then
        for username in "$@"; do
            if id "$username" >/dev/null 2>&1; then
                configure_user "$username"
            else
                echo "Pomijam $username: użytkownik nie istnieje." >&2
            fi
        done
        exit 0
    fi

    configure_user root

    while IFS=: read -r username _ uid _ _ home_dir shell; do
        if (( uid >= 1000 && uid < 65534 )) && [[ -d "$home_dir" ]]; then
            configure_user "$username"
        fi
    done < /etc/passwd
}

main "$@"

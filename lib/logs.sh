#!/usr/bin/env bash

logs_backend() {
    if command_exists journalctl; then
        printf 'journalctl\n'
    elif [[ -r /var/log/syslog ]]; then
        printf 'syslog\n'
    else
        printf 'none\n'
    fi
}

logs_default_lines() {
    printf '%s\n' "${DAT_LOG_LINES:-80}"
}

logs_validate_lines() {
    local lines="${1:-$(logs_default_lines)}"
    [[ "$lines" =~ ^[0-9]+$ ]] || lines="$(logs_default_lines)"
    (( lines < 1 )) && lines=40
    (( lines > 1000 )) && lines=1000
    printf '%s\n' "$lines"
}

logs_recent() {
    local lines
    lines="$(logs_validate_lines "${1:-$(logs_default_lines)}")"

    case "$(logs_backend)" in
        journalctl)
            journalctl -n "$lines" --no-pager 2>/dev/null || true
            ;;
        syslog)
            tail -n "$lines" /var/log/syslog 2>/dev/null || true
            ;;
        *)
            printf 'No readable log source found.\n'
            return 1
            ;;
    esac
}

logs_follow() {
    local lines
    lines="$(logs_validate_lines "${1:-40}")"

    case "$(logs_backend)" in
        journalctl)
            journalctl -n "$lines" -f 2>/dev/null
            ;;
        syslog)
            tail -n "$lines" -f /var/log/syslog 2>/dev/null
            ;;
        *)
            printf 'No readable log source found.\n'
            return 1
            ;;
    esac
}

logs_errors() {
    local lines
    lines="$(logs_validate_lines "${1:-$(logs_default_lines)}")"

    if command_exists journalctl; then
        journalctl -p warning..alert -n "$lines" --no-pager 2>/dev/null || true
    elif [[ -r /var/log/syslog ]]; then
        grep -Ei 'error|failed|warn|critical|panic|denied' /var/log/syslog 2>/dev/null | tail -n "$lines" || true
    else
        printf 'No readable log source found.\n'
        return 1
    fi
}

logs_service() {
    local service="$1"
    local lines
    lines="$(logs_validate_lines "${2:-$(logs_default_lines)}")"

    [[ -n "$service" ]] || { printf 'Service name required.\n' >&2; return 1; }

    if command_exists journalctl; then
        journalctl -u "$service" -n "$lines" --no-pager 2>/dev/null || true
    elif [[ -r /var/log/syslog ]]; then
        grep -i "$service" /var/log/syslog 2>/dev/null | tail -n "$lines" || true
    else
        printf 'No readable log source found.\n'
        return 1
    fi
}

logs_search() {
    local query="$1"
    local lines
    lines="$(logs_validate_lines "${2:-200}")"

    [[ -n "$query" ]] || { printf 'Search query required.\n' >&2; return 1; }

    if command_exists journalctl; then
        journalctl -n "$lines" --no-pager 2>/dev/null | grep -i -- "$query" || true
    elif [[ -r /var/log/syslog ]]; then
        tail -n "$lines" /var/log/syslog 2>/dev/null | grep -i -- "$query" || true
    else
        printf 'No readable log source found.\n'
        return 1
    fi
}

logs_boots() {
    if command_exists journalctl; then
        journalctl --list-boots --no-pager 2>/dev/null || true
    else
        printf 'Boot history requires journalctl.\n'
        return 1
    fi
}

logs_kernel() {
    local lines
    lines="$(logs_validate_lines "${1:-$(logs_default_lines)}")"

    if command_exists journalctl; then
        journalctl -k -n "$lines" --no-pager 2>/dev/null || true
    elif command_exists dmesg; then
        dmesg 2>/dev/null | tail -n "$lines" || true
    else
        printf 'No kernel log source found.\n'
        return 1
    fi
}

logs_summary() {
    kv "Backend" "$(logs_backend)"
    kv "Default lines" "$(logs_default_lines)"

    if command_exists journalctl; then
        kv "Boots" "$(journalctl --list-boots --no-pager 2>/dev/null | wc -l | awk '{print $1}')"
        kv "Warnings" "$(journalctl -p warning..alert -n 200 --no-pager 2>/dev/null | wc -l | awk '{print $1}')"
    elif [[ -r /var/log/syslog ]]; then
        kv "Syslog" "/var/log/syslog"
        kv "Warnings" "$(grep -Ei 'error|failed|warn|critical|panic|denied' /var/log/syslog 2>/dev/null | tail -n 200 | wc -l | awk '{print $1}')"
    fi
}

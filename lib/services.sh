#!/usr/bin/env bash

default_services() {
    if [[ -n "${DAT_SERVICES:-}" ]]; then
        printf '%s\n' $DAT_SERVICES
        return
    fi

    printf '%s\n' ssh cron nginx oscam-panel blackserv oscam
    discovered_wireguard_services
}

discovered_wireguard_services() {
    if ! command_exists systemctl; then
        return 0
    fi

    {
        systemctl list-unit-files 'wg-quick@*.service' --no-legend 2>/dev/null | awk '{print $1}'
        systemctl list-units 'wg-quick@*.service' --all --no-legend 2>/dev/null | awk '{print $1}'
    } | sed 's/\.service$//' | sort -u
}

service_exists() {
    local service="$1"

    if ! command_exists systemctl; then
        return 1
    fi

    systemctl list-unit-files "$service.service" --no-legend 2>/dev/null | grep -q . && return 0
    systemctl status "$service" >/dev/null 2>&1 && return 0

    return 1
}

service_state() {
    local service="$1"

    if ! command_exists systemctl; then
        printf 'unknown\n'
        return
    fi

    if systemctl is-active --quiet "$service" 2>/dev/null; then
        printf 'active\n'
    elif service_exists "$service"; then
        printf 'inactive\n'
    else
        printf 'not-installed\n'
    fi
}

service_enabled_state() {
    local service="$1"

    if ! command_exists systemctl; then
        printf 'unknown\n'
        return
    fi

    if ! service_exists "$service"; then
        printf 'n/a\n'
        return
    fi

    systemctl is-enabled "$service" 2>/dev/null || printf 'disabled\n'
}

service_visual_state() {
    local state="$1"

    case "$state" in
        active) status_text active ;;
        inactive) status_text inactive ;;
        not-installed) status_text not-installed ;;
        *) status_text unknown ;;
    esac
}

services_for_dashboard() {
    local service state

    default_services | sort -u | while read -r service; do
        [[ -n "$service" ]] || continue
        state="$(service_state "$service")"

        if [[ "${DAT_SHOW_MISSING_SERVICES:-0}" == "1" || "$state" != "not-installed" ]]; then
            printf '%s\n' "$service"
        fi
    done
}

service_summary() {
    local total=0
    local active=0
    local inactive=0
    local other=0
    local service state

    while read -r service; do
        [[ -n "$service" ]] || continue
        state="$(service_state "$service")"
        total=$((total + 1))

        case "$state" in
            active) active=$((active + 1)) ;;
            inactive) inactive=$((inactive + 1)) ;;
            *) other=$((other + 1)) ;;
        esac
    done < <(services_for_dashboard)

    printf '%s/%s active' "$active" "$total"

    if (( inactive > 0 || other > 0 )); then
        printf '  issues:%s' $((inactive + other))
    fi

    printf '\n'
}

service_row() {
    local service="$1"
    local state enabled visual

    state="$(service_state "$service")"
    enabled="$(service_enabled_state "$service")"
    visual="$(service_visual_state "$state")"

    printf '%-20s %-18b %s\n' "$service" "$visual" "$enabled"
}

service_detail() {
    local service="$1"

    if ! command_exists systemctl; then
        printf 'systemctl is not available.\n'
        return 1
    fi

    printf 'Name:    %s\n' "$service"
    printf 'State:   %s\n' "$(service_state "$service")"
    printf 'Enabled: %s\n' "$(service_enabled_state "$service")"
    printf '\n'

    systemctl status "$service" --no-pager -l 2>/dev/null || true
}

service_logs() {
    local service="$1"
    local lines="${2:-40}"

    if ! command_exists journalctl; then
        printf 'journalctl is not available.\n'
        return 1
    fi

    journalctl -u "$service" -n "$lines" --no-pager 2>/dev/null || true
}

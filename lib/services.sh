#!/usr/bin/env bash

default_services() {
    if [[ -n "${DAT_SERVICES:-}" ]]; then
        printf '%s\n' $DAT_SERVICES
        return
    fi

    printf '%s\n' ssh cron nginx oscam-panel blackserv oscam
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

    default_services | while read -r service; do
        [[ -n "$service" ]] || continue
        state="$(service_state "$service")"

        if [[ "${DAT_SHOW_MISSING_SERVICES:-0}" == "1" || "$state" != "not-installed" ]]; then
            printf '%s\n' "$service"
        fi
    done
}

#!/usr/bin/env bash

default_services() {
    if [[ -n "${DAT_SERVICES:-}" ]]; then
        printf '%s\n' $DAT_SERVICES
        return
    fi

    printf '%s\n' ssh sshd cron nginx oscam oscam-panel blackserv apache2 mysql mariadb postgresql docker fail2ban ufw
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

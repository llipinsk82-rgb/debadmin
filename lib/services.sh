#!/usr/bin/env bash

default_services() {
    if [[ -n "${DAT_SERVICES:-}" ]]; then
        printf '%s\n' $DAT_SERVICES
        return
    fi

    printf '%s\n' ssh sshd cron nginx apache2 mysql mariadb postgresql docker fail2ban ufw
}

service_exists() {
    systemctl list-unit-files "$1.service" >/dev/null 2>&1 || systemctl status "$1" >/dev/null 2>&1
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
        printf 'unknown\n'
    fi
}

service_enabled_state() {
    local service="$1"

    if ! command_exists systemctl; then
        printf 'unknown\n'
        return
    fi

    systemctl is-enabled "$service" 2>/dev/null || printf 'unknown\n'
}

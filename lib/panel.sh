#!/usr/bin/env bash

panel_commands() {
    cat <<EOF
health|System dashboard|deb health
services|Service panel and actions|deb services
ports|Ports overview and lookup|deb ports
logs|Log browser and filters|deb logs summary
backup|Backup profiles and archives|deb backup list
doctor|Diagnostics and health checks|deb doctor
update|Safe APT update workflow|deb update dry-run
EOF
}

panel_command_status() {
    local command="$1"
    local module="$MODULE_DIR/$command"

    if [[ -x "$module" ]]; then
        printf 'ready\n'
    else
        printf 'missing\n'
    fi
}

panel_table() {
    local name desc example state

    table_header "Command" "Status" "Description"
    while IFS='|' read -r name desc example; do
        [[ -n "$name" ]] || continue
        state="$(panel_command_status "$name")"
        printf '%-20s %-10s %s\n' "$name" "$state" "$desc"
    done < <(panel_commands)
}

panel_examples() {
    local name desc example

    section "Examples"
    while IFS='|' read -r name desc example; do
        [[ -n "$name" ]] || continue
        printf '%s%-12s%s %s\n' "$CYAN" "$name" "$RESET" "$example"
    done < <(panel_commands)
}

panel_quick_status() {
    local host uptime version
    host="$(hostname 2>/dev/null || printf 'unknown')"
    uptime="$(uptime -p 2>/dev/null || printf 'unknown')"
    version="${DAT_VERSION:-unknown}"

    section "Panel"
    kv "Version" "$version"
    kv "Host" "$host"
    kv "Uptime" "$uptime"
    kv "Home" "$DAT_HOME"
}

panel_help() {
    cat <<EOF
DebAdmin Panel $DAT_VERSION

Usage:
  deb              Show command panel
  deb menu         Show command panel
  deb menu run     Open interactive command picker
  deb menu help    Show this help
EOF
}

panel_run() {
    local choice

    while true; do
        header "DebAdmin Panel $DAT_VERSION"
        printf '1) health\n'
        printf '2) services\n'
        printf '3) ports\n'
        printf '4) logs\n'
        printf '5) backup\n'
        printf '6) doctor\n'
        printf '7) update\n'
        printf 'q) quit\n\n'
        printf 'Select: '
        read -r choice || return 0

        case "$choice" in
            1|health) "$MODULE_DIR/health" ;;
            2|services) "$MODULE_DIR/services" ;;
            3|ports) "$MODULE_DIR/ports" ;;
            4|logs) "$MODULE_DIR/logs" summary ;;
            5|backup) "$MODULE_DIR/backup" list ;;
            6|doctor) "$MODULE_DIR/doctor" ;;
            7|update) "$MODULE_DIR/update" dry-run ;;
            q|Q|quit|exit) return 0 ;;
            *) printf 'Unknown choice: %s\n' "$choice" ;;
        esac

        printf '\nPress Enter to return to panel...'
        read -r _ || return 0
    done
}

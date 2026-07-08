#!/usr/bin/env bash

panel_commands() {
    cat <<EOF
commands|Full command and subcommand reference|deb commands
health|System dashboard|deb health
services|Service panel and actions|deb services
wireguard|WireGuard and WGDashboard checks|deb wireguard
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

    if [[ -f "$module" ]]; then
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
  deb commands     Show all commands and subcommands
EOF
}

panel_run_module() {
    local module="$1"
    shift || true

    if [[ -x "$module" ]]; then
        "$module" "$@"
    else
        bash "$module" "$@"
    fi
}

panel_run() {
    local choice

    while true; do
        header "DebAdmin Panel $DAT_VERSION"
        printf '1) commands\n'
        printf '2) health\n'
        printf '3) services\n'
        printf '4) wireguard\n'
        printf '5) ports\n'
        printf '6) logs\n'
        printf '7) backup\n'
        printf '8) doctor\n'
        printf '9) update\n'
        printf 'q) quit\n\n'
        printf 'Select: '
        read -r choice || return 0

        case "$choice" in
            1|commands) panel_run_module "$MODULE_DIR/commands" ;;
            2|health) panel_run_module "$MODULE_DIR/health" ;;
            3|services) panel_run_module "$MODULE_DIR/services" ;;
            4|wireguard) panel_run_module "$MODULE_DIR/wireguard" ;;
            5|ports) panel_run_module "$MODULE_DIR/ports" ;;
            6|logs) panel_run_module "$MODULE_DIR/logs" summary ;;
            7|backup) panel_run_module "$MODULE_DIR/backup" list ;;
            8|doctor) panel_run_module "$MODULE_DIR/doctor" ;;
            9|update) panel_run_module "$MODULE_DIR/update" dry-run ;;
            q|Q|quit|exit) return 0 ;;
            *) printf 'Unknown choice: %s\n' "$choice" ;;
        esac

        printf '\nPress Enter to return to panel...'
        read -r _ || return 0
    done
}

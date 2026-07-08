#!/usr/bin/env bash

doctor_pass=0
doctor_warn=0
doctor_fail=0

doctor_reset() {
    doctor_pass=0
    doctor_warn=0
    doctor_fail=0
}

doctor_record() {
    local state="$1"
    local label="$2"

    case "$state" in
        ok)
            doctor_pass=$((doctor_pass + 1))
            ;;
        warn)
            doctor_warn=$((doctor_warn + 1))
            ;;
        fail)
            doctor_fail=$((doctor_fail + 1))
            ;;
    esac

    status_line "$state" "$label"
}

doctor_summary() {
    printf 'ok:%s warn:%s fail:%s\n' "$doctor_pass" "$doctor_warn" "$doctor_fail"
}

doctor_check_file_readable() {
    local file="$1"
    local label="${2:-$file readable}"

    if [[ -r "$file" ]]; then
        doctor_record ok "$label"
    else
        doctor_record fail "$label"
    fi
}

doctor_check_command() {
    local command="$1"
    local required="${2:-warn}"

    if command_exists "$command"; then
        doctor_record ok "$command available"
    elif [[ "$required" == "required" ]]; then
        doctor_record fail "$command available"
    else
        doctor_record warn "$command available"
    fi
}

doctor_check_root() {
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        doctor_record ok "running as root"
    else
        doctor_record warn "running as root"
    fi
}

doctor_check_debian() {
    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        if [[ "${ID:-}" == "debian" ]]; then
            doctor_record ok "Debian detected"
        else
            doctor_record warn "Debian detected"
        fi
    else
        doctor_record fail "Debian detected"
    fi
}

doctor_check_resource() {
    local name="$1"
    local value="$2"
    local warn_at="${3:-80}"
    local fail_at="${4:-90}"

    if (( value >= fail_at )); then
        doctor_record fail "$name ${value}%"
    elif (( value >= warn_at )); then
        doctor_record warn "$name ${value}%"
    else
        doctor_record ok "$name ${value}%"
    fi
}

doctor_system_checks() {
    section "System checks"
    doctor_check_debian
    doctor_check_root
    doctor_check_file_readable /etc/os-release
    doctor_check_file_readable /proc/loadavg
    doctor_check_file_readable /proc/meminfo
    doctor_check_file_readable /proc/stat
    doctor_check_file_readable /proc/cpuinfo
}

doctor_dependency_checks() {
    section "Tool checks"
    doctor_check_command bash required
    doctor_check_command awk required
    doctor_check_command sed required
    doctor_check_command grep required
    doctor_check_command systemctl required
    doctor_check_command journalctl
    doctor_check_command ss
    doctor_check_command netstat
    doctor_check_command curl
    doctor_check_command wget
    doctor_check_command tar
}

doctor_resource_checks() {
    local cpu ram disk

    section "Resource checks"
    cpu="$(get_cpu_usage)"
    ram="$(get_ram_percent)"
    disk="$(get_disk_percent)"

    doctor_check_resource CPU "$cpu" 80 90
    doctor_check_resource RAM "$ram" 80 90
    doctor_check_resource Disk "$disk" 80 90
}

doctor_service_checks() {
    local service state

    section "Configured services"
    services_for_dashboard | while read -r service; do
        [[ -n "$service" ]] || continue
        state="$(service_state "$service")"

        case "$state" in
            active) doctor_record ok "$service active" ;;
            inactive) doctor_record fail "$service active" ;;
            not-installed) doctor_record warn "$service installed" ;;
            *) doctor_record warn "$service state known" ;;
        esac
    done
}

doctor_network_checks() {
    local local_ip public_ip

    section "Network checks"
    local_ip="$(get_local_ip || true)"
    public_ip="$(get_public_ip || true)"

    [[ -n "$local_ip" && "$local_ip" != "n/a" ]] && doctor_record ok "local IP detected" || doctor_record warn "local IP detected"
    [[ -n "$public_ip" && "$public_ip" != "n/a" ]] && doctor_record ok "public IP detected" || doctor_record warn "public IP detected"
}

doctor_port_checks() {
    section "Port checks"

    if [[ "$(ports_backend)" == "none" ]]; then
        doctor_record warn "port backend available"
    else
        doctor_record ok "port backend: $(ports_backend)"
        kv "Ports" "$(ports_summary)"
    fi
}

doctor_run_all() {
    doctor_reset
    doctor_system_checks
    doctor_dependency_checks
    doctor_resource_checks
    doctor_network_checks
    doctor_port_checks
    doctor_service_checks
    section "Summary"
    kv "Result" "$(doctor_summary)"
}

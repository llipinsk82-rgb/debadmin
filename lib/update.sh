#!/usr/bin/env bash

update_log_dir() {
    printf '%s\n' "${DAT_UPDATE_LOG_DIR:-/var/log/debian-admin-toolkit}"
}

update_timestamp() {
    date +%Y%m%d-%H%M%S
}

update_log_file() {
    printf '%s/update-%s.log\n' "$(update_log_dir)" "$(update_timestamp)"
}

apt_available() {
    command_exists apt-get && command_exists apt
}

update_require_apt() {
    apt_available || die "APT tools are not available."
}

update_run_logged() {
    local logfile="$1"
    shift

    mkdir -p "$(dirname "$logfile")"
    printf '>>> %s\n' "$*" | tee -a "$logfile"
    "$@" 2>&1 | tee -a "$logfile"
}

update_refresh() {
    local logfile="${1:-$(update_log_file)}"

    require_root
    update_require_apt
    update_run_logged "$logfile" apt-get update
    kv "Log" "$logfile"
}

update_list_upgradable() {
    update_require_apt
    apt list --upgradable 2>/dev/null | sed -n '1,80p'
}

update_count_upgradable() {
    update_require_apt
    apt list --upgradable 2>/dev/null | awk 'NR>1 {count++} END {print count+0}'
}

update_dry_run() {
    update_require_apt
    apt-get -s upgrade
}

update_upgrade() {
    local logfile="${1:-$(update_log_file)}"

    require_root
    update_require_apt
    update_run_logged "$logfile" apt-get upgrade -y
    kv "Log" "$logfile"
}

update_full_upgrade() {
    local logfile="${1:-$(update_log_file)}"

    require_root
    update_require_apt
    update_run_logged "$logfile" apt-get full-upgrade -y
    kv "Log" "$logfile"
}

update_autoremove() {
    local logfile="${1:-$(update_log_file)}"

    require_root
    update_require_apt
    update_run_logged "$logfile" apt-get autoremove -y
    kv "Log" "$logfile"
}

update_clean() {
    local logfile="${1:-$(update_log_file)}"

    require_root
    update_require_apt
    update_run_logged "$logfile" apt-get autoclean
    kv "Log" "$logfile"
}

update_safe() {
    local logfile="${1:-$(update_log_file)}"

    require_root
    update_require_apt
    update_run_logged "$logfile" apt-get update
    update_run_logged "$logfile" apt-get upgrade -y
    update_run_logged "$logfile" apt-get autoremove -y
    kv "Log" "$logfile"
}

update_security_list() {
    update_require_apt
    apt list --upgradable 2>/dev/null | grep -Ei 'security|debian-security' || true
}

update_log_list() {
    local dir
    dir="$(update_log_dir)"

    if [[ ! -d "$dir" ]]; then
        status_line warn "update log directory does not exist"
        kv "Directory" "$dir"
        return 0
    fi

    find "$dir" -maxdepth 1 -type f -name 'update-*.log' -printf '%TY-%Tm-%Td %TH:%TM  %s bytes  %f\n' 2>/dev/null | sort -r
}

update_latest_log() {
    local dir
    dir="$(update_log_dir)"
    find "$dir" -maxdepth 1 -type f -name 'update-*.log' -printf '%T@ %p\n' 2>/dev/null | sort -nr | awk 'NR==1 {print $2}'
}

update_show_log() {
    local logfile="${1:-latest}"
    local lines="${2:-120}"

    [[ "$lines" =~ ^[0-9]+$ ]] || lines=120

    if [[ -z "$logfile" || "$logfile" == "latest" ]]; then
        logfile="$(update_latest_log)"
    fi

    [[ -n "$logfile" ]] || { status_line warn "no update log found"; return 1; }
    [[ -r "$logfile" ]] || { status_line fail "log not readable: $logfile"; return 1; }

    kv "Log" "$logfile"
    tail -n "$lines" "$logfile"
}

update_summary() {
    kv "APT" "$(apt_available && printf 'available' || printf 'missing')"
    kv "Upgradable" "$(update_count_upgradable 2>/dev/null || printf 'n/a')"
    kv "Log dir" "$(update_log_dir)"
}

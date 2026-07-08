#!/usr/bin/env bash

wg_tunnels() {
    if ! command_exists systemctl; then
        return 0
    fi

    systemctl list-units 'wg-quick@*.service' --all --no-legend 2>/dev/null \
        | awk '{print $1}' \
        | sed 's/^wg-quick@//; s/\.service$//' \
        | awk '$0 != ""' \
        | sort -u
}

wg_dashboard_service() {
    local service

    for service in ${DAT_WG_DASHBOARD_SERVICE:-} wg-dashboard wgdashboard; do
        [[ -n "$service" ]] || continue
        if service_exists "$service"; then
            printf '%s\n' "$service"
            return 0
        fi
    done

    printf '%s\n' "${DAT_WG_DASHBOARD_SERVICE:-wg-dashboard}"
}

wg_dashboard_port() {
    printf '%s\n' "${DAT_WG_DASHBOARD_PORT:-10086}"
}

wg_dashboard_url() {
    printf '%s\n' "${DAT_WG_DASHBOARD_URL:-http://127.0.0.1:$(wg_dashboard_port)/}"
}

wg_dashboard_public_url() {
    printf '%s\n' "${DAT_WG_DASHBOARD_PUBLIC_URL:-}"
}

wg_dashboard_base_dir() {
    local service="${1:-$(wg_dashboard_service)}"
    local workdir=""
    local base=""

    if command_exists systemctl; then
        workdir="$(systemctl show "$service" -p WorkingDirectory --value 2>/dev/null || true)"
    fi

    if [[ -n "$workdir" && "$workdir" != "/" ]]; then
        if [[ "$(basename "$workdir")" == "src" ]]; then
            base="$(dirname "$workdir")"
        else
            base="$workdir"
        fi
    elif [[ -d /root/WGDashboard ]]; then
        base="/root/WGDashboard"
    else
        base="$(find /opt /root /srv /home -maxdepth 3 -type d -iname 'WGDashboard' 2>/dev/null | head -n 1 || true)"
    fi

    printf '%s\n' "$base"
}

wg_dashboard_python() {
    local base="${1:-$(wg_dashboard_base_dir)}"

    if [[ -x "$base/src/venv/bin/python3" ]]; then
        "$base/src/venv/bin/python3" --version 2>&1
    elif command_exists python3; then
        python3 --version 2>&1
    else
        printf 'python3 not found\n'
    fi
}

wg_dashboard_python_major_minor() {
    wg_dashboard_python "$1" | awk '{print $2}' | awk -F. '{print $1"."$2}'
}

wg_dashboard_local_version() {
    local base="${1:-$(wg_dashboard_base_dir)}"
    local file version

    if [[ -n "${DAT_WG_DASHBOARD_VERSION:-}" ]]; then
        printf '%s\n' "$DAT_WG_DASHBOARD_VERSION"
        return 0
    fi

    if [[ -z "$base" || ! -d "$base" ]]; then
        printf 'unknown\n'
        return 0
    fi

    if [[ -d "$base/.git" ]] && command_exists git; then
        git -C "$base" describe --tags --always 2>/dev/null && return 0
    fi

    for file in "$base/VERSION" "$base/version" "$base/src/VERSION" "$base/src/version" "$base/src/.version" "$base/src/package.json" "$base/package.json"; do
        if [[ -r "$file" ]]; then
            version="$(grep -Eo 'v?[0-9]+\.[0-9]+\.[0-9]+' "$file" 2>/dev/null | head -n 1 || true)"
            if [[ -z "$version" ]]; then
                version="$(head -n 1 "$file" | tr -d '[:space:]')"
            fi
            [[ -n "$version" ]] && printf '%s\n' "$version" && return 0
        fi
    done

    printf 'unknown\n'
}

wg_dashboard_latest_version() {
    if ! command_exists curl; then
        printf 'unknown (curl missing)\n'
        return 0
    fi

    curl -fsSL --max-time 8 https://api.github.com/repos/WGDashboard/WGDashboard/releases/latest 2>/dev/null \
        | awk -F '"' '/"tag_name"/ {print $4; exit}'
}

wg_dashboard_port_open() {
    local port="${1:-$(wg_dashboard_port)}"

    if command_exists ss && ss -tulpen 2>/dev/null | grep -q ":$port "; then
        return 0
    fi

    return 1
}

wg_dashboard_http_ok() {
    local url="${1:-$(wg_dashboard_url)}"

    if command_exists curl && curl -fsS -I --max-time 5 "$url" >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

wg_dashboard_public_http_ok() {
    local url="${1:-$(wg_dashboard_public_url)}"

    [[ -n "$url" ]] || return 1

    if command_exists curl && curl -fsS -I --max-time 8 "$url" >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

wg_dashboard_version_status() {
    local local_version="$1"
    local latest_version="$2"

    if [[ -z "$latest_version" || "$latest_version" == unknown* || "$local_version" == unknown* ]]; then
        printf 'unknown\n'
    elif [[ "$local_version" == "$latest_version" ]]; then
        printf 'ok\n'
    else
        printf 'warn\n'
    fi
}

wg_dashboard_python_status() {
    local base="$1"
    local py

    py="$(wg_dashboard_python_major_minor "$base")"
    case "$py" in
        3.12|3.13|3.14|3.15|3.16|3.17|3.18|3.19) printf 'ok\n' ;;
        *) printf 'warn\n' ;;
    esac
}

wg_print_overview() {
    local service state enabled port url base python local_version latest_version public_url

    service="$(wg_dashboard_service)"
    state="$(service_state "$service")"
    enabled="$(service_enabled_state "$service")"
    port="$(wg_dashboard_port)"
    url="$(wg_dashboard_url)"
    public_url="$(wg_dashboard_public_url)"
    base="$(wg_dashboard_base_dir "$service")"
    python="$(wg_dashboard_python "$base")"
    local_version="$(wg_dashboard_local_version "$base")"
    latest_version="$(wg_dashboard_latest_version)"

    section "WireGuard tunnels"
    if [[ -n "$(wg_tunnels)" ]]; then
        wg_tunnels | while read -r iface; do
            [[ -n "$iface" ]] || continue
            status_line "$(service_state "wg-quick@$iface")" "wg-quick@$iface"
        done
    else
        status_line "missing" "Tunnels"
    fi

    section "WGDashboard"
    kv "Service" "$service"
    status_line "$state" "State"
    kv "Enabled" "$enabled"
    kv "Port" "$port"
    kv "URL" "$url"
    [[ -n "$public_url" ]] && kv "Public URL" "$public_url"
    kv "Path" "${base:-unknown}"
    kv "Python" "$python"
    status_line "$(wg_dashboard_python_status "$base")" "Python req"
    kv "Local ver" "$local_version"
    kv "Latest ver" "${latest_version:-unknown}"
    status_line "$(wg_dashboard_version_status "$local_version" "${latest_version:-unknown}")" "Update"

    if wg_dashboard_port_open "$port"; then
        status_line "ok" "Port check"
    else
        status_line "fail" "Port check"
    fi

    if wg_dashboard_http_ok "$url"; then
        status_line "ok" "HTTP check"
    else
        status_line "fail" "HTTP check"
    fi
}

wg_public_check() {
    local url

    url="$(wg_dashboard_public_url)"

    section "WGDashboard public URL"
    if [[ -z "$url" ]]; then
        kv "URL" "not configured"
        status_line "missing" "Public URL"
        printf '\nSet DAT_WG_DASHBOARD_PUBLIC_URL in /etc/debian-admin-toolkit/config.\n'
        return 0
    fi

    kv "URL" "$url"
    if wg_dashboard_public_http_ok "$url"; then
        status_line "ok" "HTTP public"
    else
        status_line "fail" "HTTP public"
        printf '\nLocal checks can still pass when public hairpin/DNS/firewall blocks this request.\n'
    fi
}

wg_config_check() {
    local iface="${1:-wg0}"
    local cfg="/etc/wireguard/$iface.conf"
    local peer_count="n/a"

    section "WireGuard config: $iface"
    kv "Config" "$cfg"

    if [[ -r "$cfg" ]]; then
        status_line "ok" "Config file"
    else
        status_line "fail" "Config file"
    fi

    if command_exists ip && ip link show "$iface" >/dev/null 2>&1; then
        status_line "ok" "Interface"
    else
        status_line "fail" "Interface"
    fi

    if command_exists wg && wg show "$iface" >/dev/null 2>&1; then
        status_line "ok" "WG state"
        peer_count="$(wg show "$iface" peers 2>/dev/null | wc -l | tr -d ' ')"
    else
        status_line "fail" "WG state"
    fi

    if command_exists wg-quick && wg-quick strip "$iface" >/dev/null 2>&1; then
        status_line "ok" "Syntax"
    else
        status_line "fail" "Syntax"
    fi

    kv "Peers" "$peer_count"
}

wg_backup_paths() {
    find /root -maxdepth 1 \( \
        -name 'WGDashboard.backup.*' -o \
        -name 'WGDashboard.before-v*' -o \
        -name 'WGDashboard.old-*' -o \
        -name 'wireguard.backup.*' -o \
        -name 'wg-dashboard.service.backup.*' \
    \) -print 2>/dev/null | sort -r
}

wg_backups_list() {
    local found=0
    local path size

    section "WGDashboard backups"
    while read -r path; do
        [[ -n "$path" ]] || continue
        found=1
        if command_exists du; then
            size="$(du -sh "$path" 2>/dev/null | awk '{print $1}')"
        else
            size="n/a"
        fi
        printf '%-8s %s\n' "${size:-n/a}" "$path"
    done < <(wg_backup_paths)

    if [[ "$found" -eq 0 ]]; then
        status_line "missing" "Backups"
    fi
}

wg_cleanup_info() {
    section "Cleanup info"
    printf 'Review backups manually before deleting anything.\n'
    printf 'Keep at least one known-good WGDashboard backup and one WireGuard backup.\n'
    printf 'Suggested wait time before cleanup: 1-2 days of stable service.\n'
    wg_backups_list
}

wg_dashboard_restart() {
    local service="$(wg_dashboard_service)"

    require_root
    service_exists "$service" || die "WGDashboard service not found: $service"
    systemctl restart "$service"
    service_detail "$service"
}

wg_tunnel_restart() {
    local iface="${1:-wg0}"

    require_root
    service_exists "wg-quick@$iface" || die "WireGuard tunnel not found: wg-quick@$iface"
    systemctl restart "wg-quick@$iface"
    service_detail "wg-quick@$iface"
}

wg_dashboard_logs() {
    local lines="${1:-80}"
    local service="$(wg_dashboard_service)"

    service_logs "$service" "$lines"
}

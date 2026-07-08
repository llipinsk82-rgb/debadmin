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

wg_dashboard_local_version() {
    local base="${1:-$(wg_dashboard_base_dir)}"
    local file version

    if [[ -z "$base" || ! -d "$base" ]]; then
        printf 'unknown\n'
        return 0
    fi

    if [[ -d "$base/.git" ]] && command_exists git; then
        git -C "$base" describe --tags --always 2>/dev/null && return 0
    fi

    for file in "$base/VERSION" "$base/version" "$base/src/VERSION" "$base/src/version" "$base/src/.version"; do
        if [[ -r "$file" ]]; then
            version="$(head -n 1 "$file" | tr -d '[:space:]')"
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

wg_print_overview() {
    local service state enabled port url base python local_version latest_version

    service="$(wg_dashboard_service)"
    state="$(service_state "$service")"
    enabled="$(service_enabled_state "$service")"
    port="$(wg_dashboard_port)"
    url="$(wg_dashboard_url)"
    base="$(wg_dashboard_base_dir "$service")"
    python="$(wg_dashboard_python "$base")"
    local_version="$(wg_dashboard_local_version "$base")"
    latest_version="$(wg_dashboard_latest_version)"

    section "WireGuard tunnels"
    if [[ -n "$(wg_tunnels)" ]]; then
        wg_tunnels | while read -r iface; do
            [[ -n "$iface" ]] || continue
            status_line "wg-quick@$iface" "$(service_state "wg-quick@$iface")"
        done
    else
        status_line "Tunnels" "missing"
    fi

    section "WGDashboard"
    kv "Service" "$service"
    status_line "State" "$state"
    kv "Enabled" "$enabled"
    kv "Port" "$port"
    kv "URL" "$url"
    kv "Path" "${base:-unknown}"
    kv "Python" "$python"
    kv "Local ver" "$local_version"
    kv "Latest ver" "${latest_version:-unknown}"

    if wg_dashboard_port_open "$port"; then
        status_line "Port check" "ok"
    else
        status_line "Port check" "fail"
    fi

    if wg_dashboard_http_ok "$url"; then
        status_line "HTTP check" "ok"
    else
        status_line "HTTP check" "fail"
    fi
}

wg_config_check() {
    local iface="${1:-wg0}"
    local cfg="/etc/wireguard/$iface.conf"
    local peer_count="n/a"

    section "WireGuard config: $iface"
    kv "Config" "$cfg"

    if [[ -r "$cfg" ]]; then
        status_line "Config file" "ok"
    else
        status_line "Config file" "fail"
    fi

    if command_exists ip && ip link show "$iface" >/dev/null 2>&1; then
        status_line "Interface" "ok"
    else
        status_line "Interface" "fail"
    fi

    if command_exists wg && wg show "$iface" >/dev/null 2>&1; then
        status_line "WG state" "ok"
        peer_count="$(wg show "$iface" peers 2>/dev/null | wc -l | tr -d ' ')"
    else
        status_line "WG state" "fail"
    fi

    if command_exists wg-quick && wg-quick strip "$iface" >/dev/null 2>&1; then
        status_line "Syntax" "ok"
    else
        status_line "Syntax" "fail"
    fi

    kv "Peers" "$peer_count"
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

#!/usr/bin/env bash

get_hostname() {
    hostname 2>/dev/null || printf 'unknown\n'
}

get_os() {
    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        printf '%s\n' "${PRETTY_NAME:-Unknown Linux}"
    else
        printf 'Unknown Linux\n'
    fi
}

get_kernel() {
    uname -r 2>/dev/null || printf 'unknown\n'
}

get_uptime() {
    uptime -p 2>/dev/null || uptime 2>/dev/null || printf 'unknown\n'
}

get_load() {
    awk '{print $1" "$2" "$3}' /proc/loadavg 2>/dev/null || printf 'unknown\n'
}

get_cpu_model() {
    awk -F: '/model name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo 2>/dev/null
}

get_cpu_cores() {
    nproc 2>/dev/null || awk -F: '/^processor/ {count++} END {print count+0}' /proc/cpuinfo 2>/dev/null
}

_get_cpu_times() {
    awk '/^cpu / {
        idle=$5+$6
        total=$2+$3+$4+$5+$6+$7+$8+$9
        print idle, total
    }' /proc/stat
}

get_cpu_usage() {
    local idle1 total1 idle2 total2 diff_idle diff_total usage

    read -r idle1 total1 < <(_get_cpu_times)
    sleep 0.3
    read -r idle2 total2 < <(_get_cpu_times)

    diff_idle=$((idle2 - idle1))
    diff_total=$((total2 - total1))

    if (( diff_total <= 0 )); then
        printf '0\n'
        return
    fi

    usage=$((100 * (diff_total - diff_idle) / diff_total))
    clamp_percent "$usage"
}

get_ram_percent() {
    awk '/MemTotal:/ {total=$2} /MemAvailable:/ {available=$2}
         END {
             if (total > 0) printf "%.0f\n", (total-available)/total*100;
             else print 0;
         }' /proc/meminfo 2>/dev/null
}

get_ram_summary() {
    free -h 2>/dev/null | awk '/Mem:/ {print $3 " / " $2}' || printf 'unknown\n'
}

get_disk_percent() {
    df -P / 2>/dev/null | awk 'NR==2 {gsub("%","",$5); print $5}' || printf '0\n'
}

get_disk_summary() {
    df -hP / 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}' || printf 'unknown\n'
}

get_cpu_temp() {
    local file value

    for file in /sys/class/thermal/thermal_zone*/temp; do
        [[ -r "$file" ]] || continue
        value="$(cat "$file" 2>/dev/null || true)"
        [[ "$value" =~ ^[0-9]+$ ]] || continue
        if (( value > 1000 )); then
            printf '%d°C\n' $((value / 1000))
        else
            printf '%d°C\n' "$value"
        fi
        return
    done

    printf 'n/a\n'
}

get_local_ip() {
    if command_exists ip; then
        ip route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}'
        return
    fi

    hostname -I 2>/dev/null | awk '{print $1}'
}

get_public_ip() {
    if command_exists curl; then
        curl -fsS --max-time 2 https://api.ipify.org 2>/dev/null || true
    elif command_exists wget; then
        wget -qO- --timeout=2 https://api.ipify.org 2>/dev/null || true
    else
        printf 'n/a'
    fi
}

listening_ports() {
    if command_exists ss; then
        ss -tulpen 2>/dev/null
    elif command_exists netstat; then
        netstat -tulpen 2>/dev/null
    else
        printf 'Neither ss nor netstat is available.\n'
    fi
}

#!/usr/bin/env bash

ports_backend() {
    if command_exists ss; then
        printf 'ss\n'
    elif command_exists netstat; then
        printf 'netstat\n'
    else
        printf 'none\n'
    fi
}

ports_raw() {
    case "$(ports_backend)" in
        ss)
            ss -H -tulpen 2>/dev/null || true
            ;;
        netstat)
            netstat -tulpen 2>/dev/null | awk 'NR>2'
            ;;
        *)
            printf 'Neither ss nor netstat is available.\n'
            return 1
            ;;
    esac
}

ports_list() {
    ports_raw | awk '
        BEGIN {
            printf "%-6s %-22s %-24s %s\n", "Proto", "Local", "Process", "State"
            printf "----------------------------------------------------------\n"
        }
        {
            proto=$1
            state=$2
            local=$5
            process="-"
            for (i=1; i<=NF; i++) {
                if ($i ~ /users:/) {
                    process=$i
                }
            }
            gsub(/^users:\(\(/, "", process)
            gsub(/\)\)$/, "", process)
            gsub(/pid=/, "pid:", process)
            gsub(/,fd=.*/, "", process)
            printf "%-6s %-22s %-24s %s\n", proto, local, process, state
        }
    '
}

ports_list_all() {
    ports_raw
}

ports_filter() {
    local query="$1"
    ports_list | awk -v q="$query" 'NR<=2 || index(tolower($0), tolower(q))'
}

ports_summary() {
    local tcp=0
    local udp=0
    local total=0
    local line proto

    while read -r line; do
        [[ -n "$line" ]] || continue
        proto="${line%% *}"
        total=$((total + 1))
        case "$proto" in
            tcp*) tcp=$((tcp + 1)) ;;
            udp*) udp=$((udp + 1)) ;;
        esac
    done < <(ports_raw)

    printf 'total:%s tcp:%s udp:%s\n' "$total" "$tcp" "$udp"
}

port_lookup() {
    local port="$1"

    if [[ -z "$port" ]]; then
        printf 'Port required.\n' >&2
        return 1
    fi

    ports_filter ":$port"
}

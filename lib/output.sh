#!/usr/bin/env bash

term_width() {
    local width
    width="$(tput cols 2>/dev/null || printf '80')"
    [[ "$width" =~ ^[0-9]+$ ]] || width=80
    (( width < 60 )) && width=60
    (( width > 100 )) && width=100
    printf '%s\n' "$width"
}

hr() {
    local width="${1:-$(term_width)}"
    printf '%s' "${GRAY}"
    printf '%*s\n' "$width" '' | tr ' ' '─'
    printf '%s' "${RESET}"
}

header() {
    local title="${1:-DebAdmin}"
    local width
    width="$(term_width)"

    clear 2>/dev/null || true
    printf '\n'
    printf '%s╔' "$CYAN"
    printf '%*s' $((width - 2)) '' | tr ' ' '═'
    printf '╗%s\n' "$RESET"
    printf '%s║%s %-*s %s║%s\n' "$CYAN" "$WHITE" $((width - 4)) "$title" "$CYAN" "$RESET"
    printf '%s╚' "$CYAN"
    printf '%*s' $((width - 2)) '' | tr ' ' '═'
    printf '╝%s\n\n' "$RESET"
}

section() {
    printf '\n%s%s%s\n' "$BOLD" "$1" "$RESET"
    hr
}

kv() {
    printf '%s%-18s%s %s\n' "$CYAN" "$1" "$RESET" "${2:-}"
}

status_text() {
    local state="${1:-unknown}"

    case "$state" in
        ok|active|running|enabled|healthy)
            printf '%s● OK%s' "$GREEN" "$RESET"
            ;;
        warn|warning|degraded)
            printf '%s● WARN%s' "$YELLOW" "$RESET"
            ;;
        fail|failed|inactive|error)
            printf '%s● FAIL%s' "$RED" "$RESET"
            ;;
        *)
            printf '%s● UNKNOWN%s' "$GRAY" "$RESET"
            ;;
    esac
}

status_line() {
    local state="$1"
    local label="$2"
    printf '%-28s %s\n' "$label" "$(status_text "$state")"
}

bar() {
    local percent
    percent="$(clamp_percent "${1:-0}")"
    local width="${2:-30}"
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    local color="$GREEN"

    if (( percent >= 85 )); then
        color="$RED"
    elif (( percent >= 70 )); then
        color="$YELLOW"
    fi

    printf '%s[' "$GRAY"
    printf '%s' "$color"
    for ((i = 0; i < filled; i++)); do printf '█'; done
    printf '%s' "$GRAY"
    for ((i = 0; i < empty; i++)); do printf '░'; done
    printf ']%s %3d%%' "$RESET" "$percent"
}

metric_bar() {
    local label="$1"
    local value="${2:-0}"
    printf '%-10s ' "$label"
    bar "$value" 34
    printf '\n'
}

table_header() {
    printf '%s%-28s %-14s %s%s\n' "$BOLD" "$1" "$2" "$3" "$RESET"
    hr
}

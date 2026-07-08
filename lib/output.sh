#!/usr/bin/env bash

term_width() {
    local width
    width="$(tput cols 2>/dev/null || printf '80')"
    [[ "$width" =~ ^[0-9]+$ ]] || width=80
    (( width < 60 )) && width=60
    (( width > 86 )) && width=86
    printf '%s\n' "$width"
}

hr() {
    local width="${1:-42}"
    printf '%s' "${GRAY}"
    printf '%*s\n' "$width" '' | tr ' ' '-'
    printf '%s' "${RESET}"
}

header() {
    local title="${1:-DebAdmin}"
    local line="========================================================"

    clear 2>/dev/null || true
    printf '\n%s%s%s\n' "$CYAN" "$line" "$RESET"
    printf '%s  %s%s\n' "$WHITE" "$title" "$RESET"
    printf '%s%s%s\n' "$CYAN" "$line" "$RESET"
}

section() {
    printf '\n%s%s%s\n' "$BOLD" "$1" "$RESET"
    hr
}

kv() {
    printf '%s%-14s%s %s\n' "$CYAN" "$1" "$RESET" "${2:-}"
}

status_text() {
    local state="${1:-unknown}"

    case "$state" in
        ok|active|running|enabled|healthy)
            printf '%sOK%s' "$GREEN" "$RESET"
            ;;
        warn|warning|degraded|disabled)
            printf '%sWARN%s' "$YELLOW" "$RESET"
            ;;
        fail|failed|inactive|error)
            printf '%sFAIL%s' "$RED" "$RESET"
            ;;
        not-installed|missing)
            printf '%sNOT INST%s' "$GRAY" "$RESET"
            ;;
        *)
            printf '%sUNKNOWN%s' "$GRAY" "$RESET"
            ;;
    esac
}

status_line() {
    local state="$1"
    local label="$2"
    printf '%-28s %b\n' "$label" "$(status_text "$state")"
}

bar() {
    local percent
    percent="$(clamp_percent "${1:-0}")"
    local width="${2:-24}"
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
    for ((i = 0; i < filled; i++)); do printf '#'; done
    printf '%s' "$GRAY"
    for ((i = 0; i < empty; i++)); do printf '.'; done
    printf ']%s %3d%%' "$RESET" "$percent"
}

metric_bar() {
    local label="$1"
    local value="${2:-0}"
    printf '%s%-8s%s ' "$CYAN" "$label" "$RESET"
    bar "$value" 24
    printf '\n'
}

table_header() {
    printf '%s%-20s %-14s %s%s\n' "$BOLD" "$1" "$2" "$3" "$RESET"
    hr
}

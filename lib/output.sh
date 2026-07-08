#!/usr/bin/env bash

term_width() {
    local width
    width="$(tput cols 2>/dev/null || printf '80')"
    [[ "$width" =~ ^[0-9]+$ ]] || width=80
    (( width < 60 )) && width=60
    (( width > 86 )) && width=86
    printf '%s\n' "$width"
}

ui_width() {
    printf '%s\n' "${DAT_UI_WIDTH:-58}"
}

repeat_char() {
    local char="$1"
    local count="$2"
    local i
    for ((i = 0; i < count; i++)); do
        printf '%s' "$char"
    done
}

hr() {
    local width="${1:-$(ui_width)}"
    printf '%s' "${GRAY}"
    repeat_char '-' "$width"
    printf '%s\n' "${RESET}"
}

header() {
    local title="${1:-DebAdmin}"
    local width
    width="$(ui_width)"

    clear 2>/dev/null || true
    printf '\n%s+' "$CYAN"
    repeat_char '-' $((width - 2))
    printf '+%s\n' "$RESET"
    printf '%s|%s %-*s %s|%s\n' "$CYAN" "$WHITE" $((width - 4)) "$title" "$CYAN" "$RESET"
    printf '%s+' "$CYAN"
    repeat_char '-' $((width - 2))
    printf '+%s\n' "$RESET"
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
            printf '%s[ OK ]%s' "$GREEN" "$RESET"
            ;;
        warn|warning|degraded|disabled)
            printf '%s[WARN]%s' "$YELLOW" "$RESET"
            ;;
        fail|failed|inactive|error)
            printf '%s[FAIL]%s' "$RED" "$RESET"
            ;;
        not-installed|missing)
            printf '%s[MISS]%s' "$GRAY" "$RESET"
            ;;
        *)
            printf '%s[UNKN]%s' "$GRAY" "$RESET"
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
    repeat_char '#' "$filled"
    printf '%s' "$GRAY"
    repeat_char '.' "$empty"
    printf ']%s %3d%%' "$RESET" "$percent"
}

metric_bar() {
    local label="$1"
    local value="${2:-0}"
    printf '%s%-8s%s ' "$CYAN" "$label" "$RESET"
    bar "$value" 24
    printf '\n'
}

summary_bar() {
    local label="$1"
    local value="${2:-0}"
    printf '%s%-8s%s ' "$CYAN" "$label" "$RESET"
    bar "$value" 32
    printf '\n'
}

table_header() {
    printf '%s%-20s %-10s %s%s\n' "$BOLD" "$1" "$2" "$3" "$RESET"
    hr
}

footer_hint() {
    printf '\n%sTip:%s %s\n' "$GRAY" "$RESET" "$1"
}

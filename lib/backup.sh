#!/usr/bin/env bash

backup_dir() {
    printf '%s\n' "${DAT_BACKUP_DIR:-/var/backups/debian-admin-toolkit}"
}

backup_profile_items() {
    local profile="${1:-default}"

    if [[ -n "${DAT_BACKUP_ITEMS:-}" ]]; then
        printf '%s\n' $DAT_BACKUP_ITEMS
        return
    fi

    case "$profile" in
        default|system)
            printf '%s\n' /etc/debian-admin-toolkit /etc/ssh /etc/apt/sources.list /etc/apt/sources.list.d
            ;;
        dat|toolkit)
            printf '%s\n' /etc/debian-admin-toolkit
            ;;
        apt)
            printf '%s\n' /etc/apt/sources.list /etc/apt/sources.list.d
            ;;
        ssh)
            printf '%s\n' /etc/ssh
            ;;
        *)
            printf 'Unknown backup profile: %s\n' "$profile" >&2
            return 2
            ;;
    esac
}

backup_timestamp() {
    date +%Y%m%d-%H%M%S
}

backup_archive_path() {
    local profile="${1:-default}"
    printf '%s/debadmin-%s-%s.tar.gz\n' "$(backup_dir)" "$profile" "$(backup_timestamp)"
}

backup_create() {
    local profile="${1:-default}"
    local target
    local missing=0
    local item
    local items=()

    require_root

    target="$(backup_archive_path "$profile")"
    mkdir -p "$(backup_dir)"

    while read -r item; do
        [[ -n "$item" ]] || continue
        if [[ -e "$item" ]]; then
            items+=("$item")
        else
            status_line warn "missing $item"
            missing=$((missing + 1))
        fi
    done < <(backup_profile_items "$profile")

    if (( ${#items[@]} == 0 )); then
        status_line fail "no backup items found"
        return 1
    fi

    tar -czf "$target" "${items[@]}" 2>/dev/null

    if [[ -s "$target" ]]; then
        status_line ok "created $target"
        kv "Profile" "$profile"
        kv "Items" "${#items[@]}"
        kv "Missing" "$missing"
        kv "Size" "$(du -h "$target" 2>/dev/null | awk '{print $1}')"
    else
        status_line fail "backup archive was not created"
        return 1
    fi
}

backup_list() {
    local dir
    dir="$(backup_dir)"

    if [[ ! -d "$dir" ]]; then
        status_line warn "backup directory does not exist"
        kv "Directory" "$dir"
        return 0
    fi

    find "$dir" -maxdepth 1 -type f -name 'debadmin-*.tar.gz' -printf '%TY-%Tm-%Td %TH:%TM  %s bytes  %f\n' 2>/dev/null | sort -r
}

backup_latest() {
    local dir
    dir="$(backup_dir)"
    find "$dir" -maxdepth 1 -type f -name 'debadmin-*.tar.gz' -printf '%T@ %p\n' 2>/dev/null | sort -nr | awk 'NR==1 {print $2}'
}

backup_contents() {
    local archive="${1:-}"

    if [[ -z "$archive" || "$archive" == "latest" ]]; then
        archive="$(backup_latest)"
    fi

    [[ -n "$archive" ]] || { status_line warn "no backup archive found"; return 1; }
    [[ -r "$archive" ]] || { status_line fail "archive not readable: $archive"; return 1; }

    kv "Archive" "$archive"
    tar -tzf "$archive" 2>/dev/null | sed -n '1,80p'
}

backup_verify() {
    local archive="${1:-}"

    if [[ -z "$archive" || "$archive" == "latest" ]]; then
        archive="$(backup_latest)"
    fi

    [[ -n "$archive" ]] || { status_line warn "no backup archive found"; return 1; }
    [[ -r "$archive" ]] || { status_line fail "archive not readable: $archive"; return 1; }

    if tar -tzf "$archive" >/dev/null 2>&1; then
        status_line ok "archive verified"
        kv "Archive" "$archive"
        kv "Size" "$(du -h "$archive" 2>/dev/null | awk '{print $1}')"
    else
        status_line fail "archive verification failed"
        return 1
    fi
}

backup_prune() {
    local keep="${1:-5}"
    local dir
    local count=0
    local file

    require_root
    [[ "$keep" =~ ^[0-9]+$ ]] || keep=5
    dir="$(backup_dir)"

    [[ -d "$dir" ]] || return 0

    while read -r file; do
        count=$((count + 1))
        if (( count > keep )); then
            rm -f "$file"
            status_line ok "removed $file"
        fi
    done < <(find "$dir" -maxdepth 1 -type f -name 'debadmin-*.tar.gz' -printf '%T@ %p\n' 2>/dev/null | sort -nr | awk '{print $2}')
}

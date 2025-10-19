#!/usr/bin/env bash

set -euo pipefail
shopt -s extglob

read_tmux_option() {
    local option="$1"
    local default_value="$2"
    if command -v tmux >/dev/null 2>&1 && [[ -n "${TMUX:-}" ]]; then
        local value
        value="$(tmux show-option -gqv "$option" 2>/dev/null || true)"
        if [[ -n "$value" ]]; then
            printf '%s' "$value"
            return 0
        fi
    fi
    printf '%s' "$default_value"
}

require_command() {
    local binary="$1"
    if ! command -v "$binary" >/dev/null 2>&1; then
        if command -v tmux >/dev/null 2>&1; then
            tmux display-message "tmux-vault: missing dependency '$binary'"
        fi
        printf 'tmux-vault: missing dependency "%s"\n' "$binary" >&2
        printf 'Press Enter to close... ' >&2
        read -r _ 2>/dev/null || true
        exit 1
    fi
}

ensure_vault_login() {
    if vault token lookup >/dev/null 2>&1; then
        return 0
    fi

    local message="tmux-vault: Vault CLI not authenticated. Run 'vault login'."
    if command -v tmux >/dev/null 2>&1; then
        tmux display-message "$message"
    fi
    printf '%s\n' "$message" >&2
    printf 'Press Enter to close... ' >&2
    read -r _ 2>/dev/null || true
    exit 1
}

vault_kv_walk() {
    local base="$1"
    local relative="${2:-}"
    local target="$base"
    if [[ -n "$relative" ]]; then
        target="${base%/}/${relative}"
    fi

    local raw_list
    if ! raw_list="$(vault kv list "$target" 2>/dev/null)"; then
        return 0
    fi

    raw_list="$(printf '%s\n' "$raw_list" | tail -n +3)"
    if [[ -z "$raw_list" ]]; then
        return 0
    fi

    while IFS= read -r entry; do
        entry="${entry//$'\r'/}"
        entry="${entry##+([[:space:]])}"
        entry="${entry%%+([[:space:]])}"
        [[ -z "$entry" ]] && continue

        if [[ "$entry" == */ ]]; then
            local child="${entry%/}"
            local next_relative
            if [[ -n "$relative" ]]; then
                next_relative="${relative}/${child}"
            else
                next_relative="$child"
            fi
            vault_kv_walk "$base" "$next_relative"
        else
            if [[ -n "$relative" ]]; then
                printf '%s/%s\n' "$relative" "$entry"
            else
                printf '%s\n' "$entry"
            fi
        fi
    done <<<"$raw_list"
}

main() {
    require_command vault
    require_command fzf
    ensure_vault_login

    local kv_path
    kv_path="$(read_tmux_option '@tmux-vault:kv-path' 'kv')"
    kv_path="${kv_path%/}"
    [[ -z "$kv_path" ]] && kv_path="kv"

    mapfile -t relative_keys < <(vault_kv_walk "$kv_path" || true)

    if [[ "${#relative_keys[@]}" -eq 0 ]]; then
        printf 'No secrets found under "%s".\n' "$kv_path"
        printf 'Press Enter to close... '
        read -r _ 2>/dev/null || true
        exit 0
    fi

    export TMUX_VAULT_BASE_PATH="$kv_path"

    local fzf_preview
    fzf_preview='vault kv get "$TMUX_VAULT_BASE_PATH/{}"'

    local selection
    set +e
    selection="$(printf '%s\n' "${relative_keys[@]}" | sort -u | fzf \
        --prompt="vault(${kv_path})> " \
        --preview="$fzf_preview" \
        --preview-window=right:60%:wrap \
        --no-multi \
        --height=100% \
        --border)"
    local fzf_status=$?
    set -e
    if [[ $fzf_status -ne 0 ]]; then
        selection=""
    fi

    if [[ -n "$selection" ]]; then
        if command -v tmux >/dev/null 2>&1; then
            tmux display-message "tmux-vault: selected ${kv_path}/${selection}"
        fi
    fi
}

main "$@"

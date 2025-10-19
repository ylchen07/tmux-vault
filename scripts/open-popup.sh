#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

ensure_option() {
    local option="$1"
    local default_value="$2"
    local current_value
    current_value="$(tmux show-option -gqv "$option" 2>/dev/null || true)"
    if [[ -z "$current_value" ]]; then
        tmux set-option -gq "$option" "$default_value"
    fi
}

get_option() {
    local option="$1"
    local default_value="$2"
    local current_value
    current_value="$(tmux show-option -gqv "$option" 2>/dev/null || true)"
    if [[ -z "$current_value" ]]; then
        printf '%s' "$default_value"
    else
        printf '%s' "$current_value"
    fi
}

if [[ "${1:-}" == "--install" ]]; then
    ensure_option '@tmux-vault:popup-width' '80%'
    ensure_option '@tmux-vault:popup-height' '80%'
    ensure_option '@tmux-vault:kv-path' 'kv'
    exit 0
fi

popup_width="$(get_option '@tmux-vault:popup-width' '80%')"
popup_height="$(get_option '@tmux-vault:popup-height' '80%')"

tmux display-popup -E -w "$popup_width" -h "$popup_height" "${PLUGIN_DIR}/scripts/tmux-vault-popup.sh"

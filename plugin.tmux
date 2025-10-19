#!/usr/bin/env bash

run-shell -b "TMUX_VAULT_PLUGIN_DIR=\$(dirname \"#{script_path}\"); \"\$TMUX_VAULT_PLUGIN_DIR/scripts/open-popup.sh\" --install"

bind-key -T prefix V run-shell -b "TMUX_VAULT_PLUGIN_DIR=\$(dirname \"#{script_path}\"); \"\$TMUX_VAULT_PLUGIN_DIR/scripts/open-popup.sh\""

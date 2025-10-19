# tmux-vault

A tmux plugin that surfaces HashiCorp Vault KV secrets inside a tmux popup.
Secrets are browsed with `fzf`, and the selected entry is previewed on the right
hand side using `vault kv get`.

## Installation

Use the [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm):

```
set -g @plugin 'ylchen/tmux-vault'
```

Press `prefix + I` to install the plugin.

## Usage

After installation the plugin registers the key binding `prefix + V` that opens a
popup listing every secret found under the configured Vault KV path (defaults to
`kv`). Use the arrow keys or typing to narrow down the list; the secret
content is visible in the preview pane.

Hit <kbd>Enter</kbd> to close the popup and show the selected path in the tmux
status line, or <kbd>Esc</kbd> to cancel.

Ensure the `vault` CLI is authenticated (`vault login`) before triggering the
popup; the plugin exits early with a helpful message if no token is present.

## Configuration

All options can be customised from your `tmux.conf`:

```
# Base path to explore within Vault (defaults to "kv")
set -g @tmux-vault:kv-path 'kv/app'

# Popup size (defaults to 80% × 80%)
set -g @tmux-vault:popup-width '85%'
set -g @tmux-vault:popup-height '85%'
```

The plugin expects the `vault` CLI to be authenticated and able to list and read
the configured path. It also requires `fzf` to be installed on the host.

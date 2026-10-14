#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
install -Dm755 cproj "$HOME/.local/bin/cproj"
install -Dm644 shell/cproj.bash "$HOME/.config/cproj/cproj.bash"
if [[ ! -e "$HOME/.config/cproj/cproj.conf" ]]; then
    install -Dm600 cproj.conf "$HOME/.config/cproj/cproj.conf"
else
    printf 'Preserving existing configuration: ~/.config/cproj/cproj.conf\n'
fi
cat <<'MESSAGE'
CPROJ installed.

Add this line to ~/.bashrc (once):
  source "$HOME/.config/cproj/cproj.bash"

Reload Bash:
  source ~/.bashrc

Required: fzf (Arch: sudo pacman -S fzf)
Check indexing: cproj --refresh
Start the navigator: cproj
MESSAGE

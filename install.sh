#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
[[ -f "$root/cproj" && -f "$root/shell/cproj.bash" ]] || { echo 'CPROJ: incomplete package' >&2; exit 1; }
[[ ${EUID:-999} != 0 ]] || { echo 'CPROJ: run this installer as your normal user, not root' >&2; exit 1; }
install -Dm755 "$root/cproj" "$HOME/.local/bin/cproj"
install -Dm644 "$root/shell/cproj.bash" "$HOME/.config/cproj/cproj.bash"
if [[ ! -f "$HOME/.config/cproj/cproj.conf" ]]; then
    install -Dm600 "$root/cproj.conf" "$HOME/.config/cproj/cproj.conf"
else
    printf 'Existing CPROJ configuration preserved.\n'
fi
printf 'Installed CPROJ v%s to %s\n' "$("$HOME/.local/bin/cproj" --version)" "$HOME/.local/bin/cproj"
printf 'Make sure your ~/.bashrc has this line:\n'
printf '  source "$HOME/.config/cproj/cproj.bash"\n'
printf 'Usage: cproj --pull-all --dry-run ; cproj --pull-all\n'

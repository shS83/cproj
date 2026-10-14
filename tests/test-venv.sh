#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export PATH="$HOME/.local/bin:$PATH"
mkdir -p "$HOME/.local/bin" "$HOME/.config/cproj" "$HOME/Code/Alpha" \
    "$HOME/Code/Beta" "$HOME/Code/Plain" "$HOME/Code/Incomplete"
cp "$ROOT/cproj" "$HOME/.local/bin/cproj"
cp "$ROOT/shell/cproj.bash" "$HOME/.config/cproj/cproj.bash"
cat > "$HOME/.config/cproj/cproj.conf" <<'CONFIG'
CPROJ_ROOTS=("$HOME/Code")
CPROJ_MAX_DEPTH=4
CPROJ_CACHE_TTL=3600
CPROJ_PREVIEW_LINES=10
CPROJ_AUTO_VENV=1
CONFIG
for name in Alpha Beta Plain Incomplete; do
    : > "$HOME/Code/$name/pyproject.toml"
done
python3 -m venv "$HOME/Code/Alpha/.venv"
python3 -m venv "$HOME/Code/Beta/.venv"
mkdir -p "$HOME/Code/Incomplete/.venv"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
source "$HOME/.config/cproj/cproj.bash"
cproj --refresh >/dev/null
PS1='PROMETHEAN> '
unset VIRTUAL_ENV_DISABLE_PROMPT || true
cd "$HOME"
cproj Alpha
[[ $PWD == "$HOME/Code/Alpha" ]] || fail 'Cannot navigate to Alpha'
[[ ${VIRTUAL_ENV:-} == "$HOME/Code/Alpha/.venv" ]] || fail 'Alpha venv not activated'
[[ $PATH == "$HOME/Code/Alpha/.venv/bin:"* ]] || fail 'Alpha bin not prepended to PATH'
[[ $PS1 == 'PROMETHEAN> ' ]] || fail 'Activation changed the custom prompt'
[[ ! ${VIRTUAL_ENV_DISABLE_PROMPT+x} ]] || fail 'Activation leaked VIRTUAL_ENV_DISABLE_PROMPT'

# Same environment must not repeatedly add a PATH component.
old_path=$PATH
cproj Alpha
[[ $PATH == "$old_path" ]] || fail 'Same project re-activation changed PATH'

# Python venv to another Python venv: replace rather than stack.
cproj Beta
[[ ${VIRTUAL_ENV:-} == "$HOME/Code/Beta/.venv" ]] || fail 'Beta venv not activated'
[[ $PATH == "$HOME/Code/Beta/.venv/bin:"* ]] || fail 'Beta path not prepended'
[[ $PATH != *"$HOME/Code/Alpha/.venv/bin"* ]] || fail 'Old Alpha venv still on PATH'
[[ $PS1 == 'PROMETHEAN> ' ]] || fail 'Prompt changed during venv swap'

# Python venv to non-venv project: deactivate.
cproj Plain
[[ -z ${VIRTUAL_ENV:-} ]] || fail 'Old virtualenv not deactivated'
[[ $PATH != *"$HOME/Code/Beta/.venv/bin"* ]] || fail 'Old Beta venv remained in PATH'

# Incomplete .venv is not activated.
cproj Alpha
cproj Incomplete
[[ -z ${VIRTUAL_ENV:-} ]] || fail 'Incomplete .venv accidentally activated'

# With auto switching disabled, maintain current environment unchanged.
cproj Alpha
sed -i 's/CPROJ_AUTO_VENV=1/CPROJ_AUTO_VENV=0/' "$HOME/.config/cproj/cproj.conf"
prev_path=$PATH
cproj Plain
[[ ${VIRTUAL_ENV:-} == "$HOME/Code/Alpha/.venv" ]] || fail 'Disabled auto venv should leave existing environment unchanged'
[[ $PATH == "$prev_path" ]] || fail 'Disabled auto venv changed PATH'

# Failure to find project must not affect PWD or venv.
before=$PWD
if cproj NoSuchProject >/dev/null 2>&1; then fail 'Missing project should fail'; fi
[[ $PWD == "$before" && ${VIRTUAL_ENV:-} == "$HOME/Code/Alpha/.venv" ]] || fail 'Failed navigation changed shell'

# Config enabled again; leaving the project must deactivate it.
sed -i 's/CPROJ_AUTO_VENV=0/CPROJ_AUTO_VENV=1/' "$HOME/.config/cproj/cproj.conf"
cproj Plain
[[ -z ${VIRTUAL_ENV:-} ]] || fail 'Enabling auto venv did not restore deactivation'
printf 'PASS: auto activation, switching, deactivation, missing env, disabling, PS1, cancellation safety\n'

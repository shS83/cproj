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
mkdir -p "$HOME/.local/bin" "$HOME/.config/cproj" "$HOME/Code/DarkVoid2" \
    "$HOME/Code/Colors" "$HOME/Code/DarkVoid2/node_modules/vendor" \
    "$HOME/Extra Tools/NADAR" "$HOME/Code/Extra Project" \
    "$HOME/other/Manual App"
cp "$ROOT/cproj" "$HOME/.local/bin/cproj"
cp "$ROOT/shell/cproj.bash" "$HOME/.config/cproj/cproj.bash"
cat > "$HOME/.config/cproj/cproj.conf" <<'CONFIG'
CPROJ_ROOTS=("$HOME/Code" "$HOME/Extra Tools")
CPROJ_MAX_DEPTH=5
CPROJ_CACHE_TTL=3600
CPROJ_PREVIEW_LINES=5
CONFIG
: > "$HOME/Code/DarkVoid2/pyproject.toml"
: > "$HOME/Code/Colors/Makefile"
: > "$HOME/Code/DarkVoid2/node_modules/vendor/package.json"
: > "$HOME/Code/Extra Project/package.json"
: > "$HOME/Extra Tools/NADAR/go.mod"
: > "$HOME/other/Manual App/pyproject.toml"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_has() { grep -Fqx -- "$2" <<< "$1" || fail "Missing project: $2"; }
assert_lacks() { if grep -Fqx -- "$2" <<< "$1"; then fail "Unexpected project: $2"; fi; }

cproj --refresh >/dev/null
result=$(cproj --list)
assert_has "$result" "$HOME/Code/DarkVoid2"
assert_has "$result" "$HOME/Code/Colors"
assert_has "$result" "$HOME/Code/Extra Project"
assert_has "$result" "$HOME/Extra Tools/NADAR"
assert_lacks "$result" "$HOME/Code/DarkVoid2/node_modules/vendor"
[[ $(wc -l <<< "$result") == 4 ]] || fail 'Incorrect project count'
[[ $(cproj darkvoid2) == "$HOME/Code/DarkVoid2" ]] || fail 'Case-insensitive exact name lookup'
[[ $(cproj nad) == "$HOME/Extra Tools/NADAR" ]] || fail 'Unique partial name lookup'
if cproj nope >/dev/null 2>&1; then fail 'Missing project must fail'; fi

# Explicit project path and whitespace handling.
cproj --add "$HOME/other/Manual App" >/dev/null
result=$(cproj --list)
assert_has "$result" "$HOME/other/Manual App"
[[ $(cproj 'Manual App') == "$HOME/other/Manual App" ]] || fail 'Name with spaces'

# Source the integration and verify directory changes take place in same shell.
source "$HOME/.config/cproj/cproj.bash"
cd -- "$HOME"
cproj Colors
[[ $PWD == "$HOME/Code/Colors" ]] || fail 'Wrapper did not change directory'
cproj NADAR
[[ $PWD == "$HOME/Extra Tools/NADAR" ]] || fail 'Second jump failed'
cproj -
[[ $PWD == "$HOME/Code/Colors" ]] || fail 'Previous project failed'
[[ $(head -n 1 "$XDG_STATE_HOME/cproj/recent.txt") == "$HOME/Code/Colors" ]] || fail 'History record failed'

# The picker works with a harmless fzf stub, without needing interactive terminal.
cat > "$HOME/.local/bin/fzf" <<'STUB'
#!/usr/bin/env bash
head -n 1
STUB
chmod +x "$HOME/.local/bin/fzf"
cd -- "$HOME"
cproj
[[ -d $PWD && $PWD != "$HOME" ]] || fail 'fzf picker did not select a project'

# Preview returns project information and does not print escape-control strings from README.
printf 'Header\e[2J\n' > "$HOME/Code/Colors/README.md"
preview=$(command cproj --preview "$HOME/Code/Colors")
[[ $preview == *'CPROJ / PROJECT INTELLIGENCE'* && $preview == *'Make'* ]] || fail 'Preview missing'
if [[ $preview == *$'\e[2J'* ]]; then fail 'README escape sequence not sanitized'; fi

# Ambiguous names must not silently navigate to the wrong directory.
mkdir -p "$HOME/Extra Tools/Colors"
: > "$HOME/Extra Tools/Colors/pyproject.toml"
command cproj --refresh >/dev/null
if command cproj Colors >/dev/null 2>&1; then fail 'Ambiguous name should fail'; fi

printf 'PASS: discovery, pruning, direct selection, whitespace, history, picker, preview, ambiguity\n'

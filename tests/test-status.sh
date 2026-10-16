#!/usr/bin/env bash
set -euo pipefail
unset VIRTUAL_ENV
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT
export XDG_CONFIG_HOME="$TMP/config" XDG_CACHE_HOME="$TMP/cache" XDG_STATE_HOME="$TMP/state"
export PATH="$TMP/bin:$PATH"
mkdir -p "$TMP/bin" "$XDG_CONFIG_HOME/cproj" "$TMP/projects/Plain"
cp "$ROOT/cproj" "$TMP/bin/cproj"
printf 'CPROJ_ROOTS=(%q)\n' "$TMP/projects" > "$XDG_CONFIG_HOME/cproj/cproj.conf"
: > "$TMP/projects/Plain/Makefile"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
for name in Clean 'Dirty Project' New; do
    git init -q "$TMP/projects/$name"
done
for name in Clean 'Dirty Project'; do
    git -C "$TMP/projects/$name" -c user.name=Test -c user.email=test@example.invalid commit -qm initial --allow-empty
done
# Track an upstream, then diverge by one commit on each side.
git -C "$TMP/projects/Clean" branch upstream
parent=$(git -C "$TMP/projects/Clean" rev-parse HEAD)
other=$(printf 'other\n' | git -C "$TMP/projects/Clean" -c user.name=Test -c user.email=test@example.invalid commit-tree 'HEAD^{tree}' -p "$parent")
git -C "$TMP/projects/Clean" update-ref refs/heads/upstream "$other"
git -C "$TMP/projects/Clean" branch --set-upstream-to=upstream >/dev/null
git -C "$TMP/projects/Clean" -c user.name=Test -c user.email=test@example.invalid commit -qm local --allow-empty
printf text > "$TMP/projects/Dirty Project/tracked"
git -C "$TMP/projects/Dirty Project" add tracked
git -C "$TMP/projects/Dirty Project" -c user.name=Test -c user.email=test@example.invalid commit -qm tracked
git -C "$TMP/projects/Dirty Project" mv tracked renamed
printf untracked > "$TMP/projects/Dirty Project/"$'new\nfile'
printf ignored > "$TMP/projects/Clean/ignored"
printf 'ignored\n' > "$TMP/projects/Clean/.git/info/exclude"
command cproj --refresh >/dev/null
source "$ROOT/shell/cproj.bash"
before=$PWD
result=$(cproj --status)
[[ $PWD == "$before" ]] || fail 'Status navigated'
[[ $result == *$'ahead 1 / behind 1'* ]] || fail 'Diverged upstream counts'
[[ $result == *$'2 changed/untracked file(s)'* ]] || fail 'Rename/newline counts'
[[ $result == *"$TMP/projects/New"* && $result == *'no upstream'* ]] || fail 'Unborn repository'
[[ $result != *"$TMP/projects/Plain"* ]] || fail 'Non-Git project included'
cat > "$TMP/bin/fzf" <<'STUB'
#!/usr/bin/env bash
cat > "$XDG_STATE_HOME/picker-input"
head -n 1 "$XDG_STATE_HOME/picker-input"
STUB
chmod +x "$TMP/bin/fzf"
mkdir -p "$XDG_STATE_HOME"
cproj --dirty
[[ $PWD == "$TMP/projects/Dirty Project" ]] || fail 'Dirty wrapper did not navigate'
[[ $(wc -l < "$XDG_STATE_HOME/picker-input") == 1 ]] || fail 'Clean projects included'
git reset --hard -q HEAD
# Remove the single untracked fixture without touching real repositories.
rm -- "$TMP/projects/Dirty Project/"$'new\nfile'
if cproj --dirty; then fail 'Empty dirty picker must fail'; fi
[[ $PWD == "$TMP/projects/Dirty Project" ]] || fail 'Empty picker navigated'
git checkout -q --detach
result=$(cproj --status)
[[ $result == *'detached HEAD'* ]] || fail 'Detached checkout'
printf 'PASS: status, upstream divergence, unborn/detached repositories, rename/newline counts, dirty picker and shell integration\n'

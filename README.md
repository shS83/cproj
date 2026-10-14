# CPROJ — Promethean Project Teleporter v0.1.0

A Bash-native project navigator for Arch Linux, with a colorful `fzf` interface,
Git/README previews, recent-project history, and shell-level directory changes.
Designed for a Kitty / truecolor terminal, but works in any ANSI-compatible terminal.

## Requirements

- Bash 5+ (for associative arrays)
- GNU `find`, `sort`, `stat`, `realpath`, `mktemp`, `sed`, `grep`, `cut`, `tr`
- `fzf` for interactive mode (non-interactive jumps work without it)
- Git for repository information in the preview

On Arch Linux:

```bash
sudo pacman -S --needed fzf git findutils coreutils
```

## Install

From the extracted archive:

```bash
./install.sh
```

The installer **does not modify your `.bashrc`** and **does not overwrite an
existing `cproj.conf`**. Add this line at the end of `~/.bashrc`:

```bash
source "$HOME/.config/cproj/cproj.bash"
```

Then load it:

```bash
source ~/.bashrc
```

**Why a function?** A separately executed program cannot change the directory
of the Bash process which launched it. The sourced function calls the binary
(`command cproj`), reads the selected directory from stdout, and runs Bash's
built-in `cd`. Only after a successful directory change is history updated.

## Usage

```text
CPROJ - Promethean Project Teleporter v0.1.0

cproj                       Open the fzf project browser
cproj nadar                 Jump directly to a project (case-insensitive)
cproj psy                   Jump if a partial name is unambiguous
cproj -                     Return to previously visited project
cproj --recent              Pick from recently visited projects
cproj --list                Print discovered directories
cproj --add /path/to/dir    Add an explicit project directory
cproj --refresh             Rescan configured roots
cproj --config              Print configuration path
cproj --help                Display full help
cproj --version             Print version
```

A preview pane displays the project kind, virtual environment, Git branch,
changed/untracked file count, last commit, and the first lines of README.md.
In the picker: **Enter** selects a project; **Esc** cancels.

## Discovery

Default roots:

```bash
CPROJ_ROOTS=("$HOME/Code" "/Tools")
```

CPROJ searches root directories and nested directories, up to the configured
maximum depth (default 5) for markers:

- `.git`, `pyproject.toml`, `Cargo.toml`, `package.json`
- `CMakeLists.txt`, `go.mod`, `composer.json`, `Gemfile`, `Makefile`

To stay responsive it prunes `.git`, `.venv`, `node_modules`, `__pycache__`,
`.tox`, `.cache`, `dist`, and `build` directories.

A project with no recognized marker can still be indexed using `cproj --add`.
Ambiguous project names **do not** select arbitrarily: use interactive mode
instead. Names containing spaces are supported; names containing tab or
newline characters are intentionally skipped due to the line-oriented index.

## Configuration

`~/.config/cproj/cproj.conf`:

```bash
CPROJ_ROOTS=("$HOME/Code" "/Tools")
CPROJ_MAX_DEPTH=5
CPROJ_CACHE_TTL=3600  # Rebuild automatically when cache is older than 1 hour
CPROJ_PREVIEW_LINES=10
```

This configuration uses **Bash syntax and is sourced as Bash code**; treat it as
trusted executable user configuration. If you modify the search roots, run
`cproj --refresh` to rebuild the index immediately.

## Storage (XDG-compatible)

| File | Purpose |
| --- | --- |
| `~/.config/cproj/cproj.conf` | Configuration |
| `~/.config/cproj/manual-projects.txt` | Explicitly added paths |
| `~/.cache/cproj/projects.txt` | Cached search index |
| `~/.local/state/cproj/recent.txt` | Recent-project history |

`XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, and `XDG_STATE_HOME` are honored.

## Testing

```bash
bash tests/test-cproj.sh
bash -n cproj shell/cproj.bash install.sh
```

Tests use a temporary HOME and a stub `fzf`; no changes are made to your
real Git repositories or `~/.bashrc`.

## Scope / roadmap

**v0.1.0 includes** core discovery, direct jumps, fzf, a styled live preview,
manual add, history, and config. Future versions may add Git ahead/behind,
favorites, a multi-action palette, optional `.venv` activation, Kitty window
shortcuts, and richer animated borders. These are **not yet implemented**.

The CPROJ binary communicates the chosen path over stdout, so scripts can
call it; all status messages go to stderr to avoid accidentally mixing
human-readable text with the selected directory.

# CPROJ 0.2.0 — project navigator and safe bulk Git updates

## Install (Arch Linux / Debian / Ubuntu)

```bash
./install.sh
```

The installer puts `cproj` into `~/.local/bin/cproj`, the Bash integration into
`~/.config/cproj/cproj.bash`, and creates a default configuration **only when
one does not already exist**. If not already present in your `~/.bashrc`, add:

```bash
source "$HOME/.config/cproj/cproj.bash"
```

Open a new shell or `source ~/.bashrc` to load the integration.

## Git synchronization across projects

```bash
cproj --refresh              # refresh the list of known projects (optional)
cproj --pull-all --dry-run   # no Git network operations or changes
cproj --pull-all             # update each clean Git project
```

`cproj --pull-all` uses the existing project index (roots from
`~/.config/cproj/cproj.conf` and manually added projects), and runs
`git pull --ff-only` on distinct Git repositories only.

- No changes to your shell's current working directory.
- Skips dirty worktrees (including untracked files), detached HEAD, and branches
  without an upstream.
- Skips subprojects inside the same Git repo, avoiding duplicate pulls.
- Never runs stash, reset, rebase, or creates a merge commit.
- Reports errors and keeps updating other projects; returns nonzero when at
  least one Git pull fails.

`--dry-run` previews eligibility using the local repository state; it does not
fetch or report whether a remote has new commits.

Other CPROJ features (fzf navigator, `--recent`, partial-name matching, `.venv`
auto-activation) are preserved.

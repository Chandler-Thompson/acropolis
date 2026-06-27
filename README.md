# Acropolis

A portable, **leave-no-trace** development environment for any Debian/Ubuntu Linux machine.

Acropolis installs a managed toolchain (tmux, nvim, htop) in complete isolation from
the host, tracks everything it touches in a manifest, and removes every trace on
teardown — leaving the machine exactly as it found it. It is a single Bash script
with no dependencies beyond standard POSIX utilities.

## Usage

Clone the repo and run `install` once from inside it:

```bash
git clone https://github.com/Chandler-Thompson/acropolis.git ~/github/acropolis
cd ~/github/acropolis
./acropolis install
```

`install` wires a small block into `~/.bashrc` and symlinks `acropolis` into
`~/.local/bin`, so after opening a new shell the `acropolis` command is available
globally:

```bash
acropolis status            # see what's installed
acropolis add workshop      # pull in the tmux + nvim dev layout
acropolis teardown          # remove everything Acropolis added
```

When you're done with the machine, `acropolis teardown` undoes all of it: the managed
tools it installed, the `~/.bashrc` block, the symlink, and the entire
`~/.local/share/acropolis/` tree.

## Commands

| Command | What it does |
|---|---|
| `acropolis install` | Installs the managed tools, writes the shell init, wires `~/.bashrc`, and creates the global `acropolis` symlink. Idempotent — safe to re-run. |
| `acropolis status` | Prints the manifest (tool, version, install method, whether it pre-existed) plus the state of the `~/.bashrc` block and the symlink. |
| `acropolis update` | `git pull --ff-only` on the Acropolis repo, then re-runs `install` to apply any changed pins or config. Idempotent. |
| `acropolis add workshop [url]` | Clones [Workshop](https://github.com/Chandler-Thompson/workshop) into the managed tree and launches its tmux session. Pass an optional `url` to use a fork or branch. |
| `acropolis teardown` | Prompts for confirmation, then removes everything Acropolis added — including any tools it installed (never pre-existing ones), the `~/.bashrc` block, the symlink, and the managed directory. Added components are torn down first by delegating to their own cleanup (e.g. `workshop/cleanup.sh --yes`), so component state living outside the managed tree is removed too. |

### Managed tools

| Tool | Method | Notes |
|---|---|---|
| tmux | `apt` | Only installed if not already on the host |
| htop | `apt` | Only installed if not already on the host |
| nvim | tarball | Pinned to `NVIM_VERSION` in the script, unpacked into the managed tree and isolated from any host nvim via `PATH` |
| workshop | git | Cloned on `acropolis add workshop` |

## How it stays isolated

Acropolis keeps everything it owns under one directory and touches the host in exactly
two removable places.

```
~/.local/share/acropolis/        # managed space — removed wholesale on teardown
├── manifest                      # TSV: tool, version, method, preexisting
├── nvim/                         # pinned nvim, unpacked here (isolated from host nvim)
│   └── bin/nvim
├── shell/
│   └── shell_init                # sourced by the ~/.bashrc block; prepends nvim to PATH
└── workshop/                     # cloned by `acropolis add workshop`

~/.bashrc                         # a single delimited block, sed-removable on teardown
  # >>> acropolis >>>
  source "$HOME/.local/share/acropolis/shell/shell_init"
  # <<< acropolis <<<

~/.local/bin/acropolis            # symlink to the repo script; removed on teardown
```

The **manifest** is the source of truth for teardown. Each tool records whether it was
`preexisting` on the host: teardown removes only the tools Acropolis itself installed,
so a tmux or htop that was already on the machine is never touched. The host's
`~/.config/`, system files, and any existing nvim are never modified.

## Development

The script is a single executable, `acropolis`. Tests are written with
[bats](https://github.com/bats-core/bats-core).

```bash
# install bats once
git clone --depth 1 https://github.com/bats-core/bats-core.git /tmp/bats-core
/tmp/bats-core/install.sh ~/.local

# run the suite
bats tests/
```

Tests run against an isolated `$HOME` (via `mktemp -d`) with stubbed `apt-get`, `curl`,
`git`, and `sudo`, so nothing touches the network or requires root. They assert on
observable state — manifest contents, directory structure, `~/.bashrc`, exit codes —
rather than internal functions.

## Scope

Acropolis targets Debian/Ubuntu (`apt`) on Linux. Other distributions, a broader tool
catalog, and arbitrary `acropolis add <tool>` support are out of scope for now. Workshop
owns its own tmux/nvim layout and runtime files under `~/.local/share/workshop/`.

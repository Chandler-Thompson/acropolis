# CLAUDE.md

## Purpose

Acropolis is a portable, leave-no-trace dev environment that installs a managed toolchain in isolation from the host and removes every trace on teardown. Single Bash script dispatching on subcommands.

## Commands

```bash
acropolis install            # install tools, wire bashrc, create symlink
acropolis status             # show manifest + bashrc/symlink state
acropolis teardown           # full cleanup with confirmation prompt
acropolis update             # git pull + re-run install
acropolis add workshop [url] # clone Workshop and launch tmux session
```

## Managed tools

| Tool     | Method  | Notes                              |
|----------|---------|------------------------------------|
| tmux     | apt     | Only installed if not pre-existing |
| htop     | apt     | Only installed if not pre-existing |
| nvim     | tarball | Pinned to NVIM_VERSION in script   |
| workshop | git     | Cloned on `add workshop`           |

## Runtime layout

```
~/.local/share/acropolis/
├── manifest           # TSV: tool, version, method, preexisting
├── nvim/              # nvim tarball unpacked here
├── shell/
│   └── shell_init     # sourced by ~/.bashrc block
└── workshop/          # cloned by `acropolis add workshop`
```

## Running tests

Install bats if not present:
```bash
git clone --depth 1 https://github.com/bats-core/bats-core.git /tmp/bats-core
/tmp/bats-core/install.sh ~/.local
```

Run the suite:
```bash
bats tests/
```

Tests use stubbed `apt-get`, `curl`, `git`, and `sudo` so nothing touches the network or requires root. Each test runs in an isolated `$HOME` via `mktemp -d`.

## Key design constraints

- No external tools beyond POSIX (grep, sed, awk, cut) — no jq, yq, etc.
- Manifest is plain TSV parsed with grep/sed/awk
- install is idempotent — safe to run repeatedly
- teardown removes only tools with `preexisting=0` in the manifest
- teardown delegates each added component's removal to that component's own
  cleanup before wiping the managed tree (e.g. `workshop/cleanup.sh --yes`), since
  a component's runtime state can live outside `~/.local/share/acropolis/`
- bashrc integration uses clearly delimited markers for surgical sed removal

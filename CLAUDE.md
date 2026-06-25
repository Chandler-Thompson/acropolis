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
acropolis dev test           # install bats (managed) and run the test suite
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

```bash
acropolis dev test
```

Installs bats into `$ACROPOLIS_DIR/bats/` on first run, then executes `bats tests/`.
Cleaned up by `acropolis teardown` — no manual setup or teardown needed.

Tests use stubbed `apt-get`, `curl`, `git`, and `sudo` so nothing touches the network or requires root. Each test runs in an isolated `$HOME` via `mktemp -d`.

## Key design constraints

- No external tools beyond POSIX (grep, sed, awk, cut) — no jq, yq, etc.
- Manifest is plain TSV parsed with grep/sed/awk
- install is idempotent — safe to run repeatedly
- teardown removes only tools with `preexisting=0` in the manifest
- bashrc integration uses clearly delimited markers for surgical sed removal

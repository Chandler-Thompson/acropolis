# Acropolis — Host Interaction Map

```
┌─────────────────────────────────── HOST MACHINE ───────────────────────────────────┐
│                                                                                     │
│  NEVER TOUCHED                                                                      │
│  ─────────────────────────────────────────────────────────────────────────────     │
│  ~/.config/          system files         other apps          any host nvim         │
│                                                                                     │
│  Pre-existing tmux / htop                                                           │
│  └── detected at install → manifest preexisting=1 → NEVER removed by teardown      │
│                                                                                     │
│  Host nvim (if any)                                                                 │
│  └── NOT detected; Acropolis always installs its own pinned nvim into managed       │
│      space and isolates it via PATH — the two never interfere                       │
│                                                                                     │
├─────────────────────────────────────────────────────────────────────────────────── │
│                                                                                     │
│  HOST TOUCHPOINTS  ←── install writes · teardown removes ──►                       │
│  ─────────────────                                                                  │
│                                                                                     │
│  ~/.bashrc                                                                          │
│  ┌───────────────────────────────────────────────────────────────────────────┐     │
│  │  ··· pre-existing user content (preserved, never modified) ···            │     │
│  │  ┌─ appended by install · removed by teardown ──────────────────────┐    │     │
│  │  │  # >>> acropolis >>>                                              │    │     │
│  │  │  source "$HOME/.local/share/acropolis/shell/shell_init"           │    │     │
│  │  │  # <<< acropolis <<<                                              │    │     │
│  │  └───────────────────────────────────────────────────────────────────┘    │     │
│  │  ··· pre-existing user content (preserved, never modified) ···            │     │
│  └───────────────────────────────────────────────────────────────────────────┘     │
│                                                                                     │
│  ~/.local/bin/acropolis  ──── symlink ────► ~/github/acropolis/acropolis            │
│                                                                                     │
├─────────────────────────────────────────────────────────────────────────────────── │
│                                                                                     │
│  ╔══════════════════ ~/.local/share/acropolis/  MANAGED SPACE ═══════════════════╗ │
│  ║                                                                               ║ │
│  ║  manifest                        nvim/                   shell/               ║ │
│  ║  ┌──────────────────────────┐    ┌─────────────────┐    ┌─────────────────┐  ║ │
│  ║  │ tool   version  preexist │    │ bin/nvim        │    │ shell_init      │  ║ │
│  ║  │ ─────  ───────  ──────── │    │                 │    │                 │  ║ │
│  ║  │ nvim   v0.12.0  0        │    │ pinned release  │    │ prepend         │  ║ │
│  ║  │ tmux   3.4      1 ──┐    │    │ downloaded via  │    │   nvim/bin      │  ║ │
│  ║  │ htop   3.2      0   │    │    │ tarball         │    │   to PATH       │  ║ │
│  ║  │ ws     -        0   │    │    │                 │    │                 │  ║ │
│  ║  └──────────────────────┘   │    │ completely      │    │ guard: only add │  ║ │
│  ║                             │    │ isolated from   │    │ .local/bin if   │  ║ │
│  ║  preexisting=1: teardown    │    │ host nvim       │    │ not already on  │  ║ │
│  ║  will NOT apt-remove  ──────┘    └─────────────────┘    │ PATH            │  ║ │
│  ║                                                          └─────────────────┘  ║ │
│  ║  ┌────────────────────────────────────────────────────────────────────────┐   ║ │
│  ║  │  workshop/  (optional — cloned via acropolis add workshop)             │   ║ │
│  ║  │                                                                        │   ║ │
│  ║  │  setup_workshop.sh  ──► launches tmux session (TERM + DEV windows)    │   ║ │
│  ║  │                                                                        │   ║ │
│  ║  │  bin/nvim wrapper   ──► sets XDG_CONFIG_HOME → workshop config        │   ║ │
│  ║  │                         host ~/.config/nvim is never touched           │   ║ │
│  ║  └────────────────────────────────────────────────────────────────────────┘   ║ │
│  ║                                                                               ║ │
│  ║  teardown: rm -rf this entire directory tree                                  ║ │
│  ╚═══════════════════════════════════════════════════════════════════════════════╝ │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Teardown sequence

```
acropolis teardown
       │
       ├─ read manifest
       │       │
       │       ├─ method=apt AND preexisting=0  ──►  apt-get remove <tool>
       │       └─ method=apt AND preexisting=1  ──►  skip (host had it before us)
       │
       ├─ rm -rf ~/.local/share/acropolis/
       │         (covers nvim, shell_init, workshop clone, manifest itself)
       │
       ├─ sed remove acropolis block from ~/.bashrc
       │         (markers make it surgically targetable)
       │
       └─ rm ~/.local/bin/acropolis  (symlink only)
```

## What crosses the host boundary

| Direction        | What                                        | How it's undone                   |
|------------------|---------------------------------------------|-----------------------------------|
| Acropolis → host | `~/.bashrc` block (2 marker lines + source) | `sed` removes by marker           |
| Acropolis → host | `~/.local/bin/acropolis` symlink            | `rm` on teardown                  |
| host → Acropolis | pre-existing tool detection                 | manifest records, no action taken |
| **nothing**      | `~/.config/`, system files, other apps      | never touched                     |

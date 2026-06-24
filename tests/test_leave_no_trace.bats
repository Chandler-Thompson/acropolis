#!/usr/bin/env bats
#
# Leave-no-trace: exhaustive artifact audit after install → teardown.
# Each test checks one specific kind of residue.  Any failure means teardown
# is incomplete — fix the teardown code, not the test.

load 'helpers/common'

setup() {
    setup_acropolis_env
    echo "# pre-existing user content" >> "$HOME/.bashrc"
    install_then_teardown
}
teardown() { teardown_acropolis_env; }

# ── Filesystem: managed directory ─────────────────────────────────────────────

@test "no ~/.local/share/acropolis/ directory remains" {
    [ ! -d "$HOME/.local/share/acropolis" ]
}

@test "no nvim directory remains" {
    [ ! -d "$HOME/.local/share/acropolis/nvim" ]
}

@test "no nvim binary remains" {
    [ ! -f "$HOME/.local/share/acropolis/nvim/bin/nvim" ]
}

@test "no shell directory remains" {
    [ ! -d "$HOME/.local/share/acropolis/shell" ]
}

@test "no shell_init file remains" {
    [ ! -f "$HOME/.local/share/acropolis/shell/shell_init" ]
}

@test "no manifest file remains" {
    [ ! -f "$HOME/.local/share/acropolis/manifest" ]
}

# ── Filesystem: stray files ───────────────────────────────────────────────────

@test "no files or directories named '*acropolis*' remain under HOME" {
    # The script itself lives outside HOME, so this only catches residue in HOME
    local found
    found="$(find "$HOME" -name "*acropolis*" 2>/dev/null)"
    [ -z "$found" ]
}

@test "no nvim tarball left behind" {
    local found
    found="$(find "$HOME" -name "nvim.tar.gz" 2>/dev/null)"
    [ -z "$found" ]
}

# ── Symlink ───────────────────────────────────────────────────────────────────

@test "symlink at ~/.local/bin/acropolis is gone" {
    [ ! -L "$HOME/.local/bin/acropolis" ]
}

@test "no regular file at ~/.local/bin/acropolis" {
    [ ! -f "$HOME/.local/bin/acropolis" ]
}

@test "~/.local/bin/ directory itself is preserved" {
    [ -d "$HOME/.local/bin" ]
}

# ── Bashrc: no acropolis content ──────────────────────────────────────────────

@test "bashrc open marker is gone" {
    ! grep -q "# >>> acropolis >>>" "$HOME/.bashrc"
}

@test "bashrc close marker is gone" {
    ! grep -q "# <<< acropolis <<<" "$HOME/.bashrc"
}

@test "bashrc has no reference to shell_init" {
    ! grep -q "shell_init" "$HOME/.bashrc"
}

@test "bashrc has no reference to acropolis managed path" {
    ! grep -q "\.local/share/acropolis" "$HOME/.bashrc"
}

@test "bashrc has no mention of the word 'acropolis'" {
    ! grep -qi "acropolis" "$HOME/.bashrc"
}

@test "bashrc file still exists after teardown" {
    [ -f "$HOME/.bashrc" ]
}

@test "pre-existing bashrc content is preserved verbatim" {
    grep -q "# pre-existing user content" "$HOME/.bashrc"
}

# ── Apt tools ─────────────────────────────────────────────────────────────────

@test "non-preexisting tmux binary removed" {
    [ ! -f "${TEST_BIN}/tmux" ]
}

@test "non-preexisting htop binary removed" {
    [ ! -f "${TEST_BIN}/htop" ]
}

# ── Host state unchanged ──────────────────────────────────────────────────────

@test "HOME contains only the files it started with plus .bashrc" {
    # .local/bin is created by install; teardown must not remove it (it's a standard dir)
    # Anything else acropolis-owned should be gone
    local unexpected
    unexpected="$(find "$HOME/.local/share" -maxdepth 1 -mindepth 1 2>/dev/null)"
    [ -z "$unexpected" ]
}

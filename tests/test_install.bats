#!/usr/bin/env bats

load 'helpers/common'

setup()    { setup_acropolis_env; }
teardown() { teardown_acropolis_env; }

# ── Dispatch ──────────────────────────────────────────────────────────────────

@test "no subcommand prints usage" {
    run_acropolis
    [ "$status" -eq 0 ]
    [[ "$output" == *"usage"* ]]
}

@test "unknown subcommand exits 1 with error" {
    run_acropolis bogus
    [ "$status" -eq 1 ]
    [[ "$output" == *"unknown subcommand"* ]]
}

# ── Exit code ─────────────────────────────────────────────────────────────────

@test "install exits 0" {
    run_acropolis install
    [ "$status" -eq 0 ]
}

# ── Directory structure ───────────────────────────────────────────────────────

@test "install creates ~/.local/share/acropolis/" {
    run_acropolis install
    [ -d "$HOME/.local/share/acropolis" ]
}

@test "install creates nvim subdirectory" {
    run_acropolis install
    [ -d "$HOME/.local/share/acropolis/nvim" ]
}

@test "install creates shell subdirectory" {
    run_acropolis install
    [ -d "$HOME/.local/share/acropolis/shell" ]
}

# ── Manifest ──────────────────────────────────────────────────────────────────

@test "install creates manifest file" {
    run_acropolis install
    [ -f "$HOME/.local/share/acropolis/manifest" ]
}

@test "install records nvim in manifest" {
    run_acropolis install
    grep -q "^nvim	" "$HOME/.local/share/acropolis/manifest"
}

@test "install records nvim with tarball method" {
    run_acropolis install
    local method
    method="$(grep "^nvim	" "$HOME/.local/share/acropolis/manifest" | cut -f3)"
    [ "$method" = "tarball" ]
}

@test "install marks nvim preexisting=0" {
    run_acropolis install
    local preexisting
    preexisting="$(grep "^nvim	" "$HOME/.local/share/acropolis/manifest" | cut -f4)"
    [ "$preexisting" = "0" ]
}

@test "install records tmux in manifest" {
    run_acropolis install
    grep -q "^tmux	" "$HOME/.local/share/acropolis/manifest"
}

@test "install marks tmux preexisting=1 when already on PATH" {
    make_tool_preexisting tmux
    run_acropolis install
    local preexisting
    preexisting="$(grep "^tmux	" "$HOME/.local/share/acropolis/manifest" | cut -f4)"
    [ "$preexisting" = "1" ]
}

@test "install marks tmux preexisting=0 when absent from PATH" {
    run_acropolis install
    local preexisting
    preexisting="$(grep "^tmux	" "$HOME/.local/share/acropolis/manifest" | cut -f4)"
    [ "$preexisting" = "0" ]
}

@test "install records htop in manifest" {
    run_acropolis install
    grep -q "^htop	" "$HOME/.local/share/acropolis/manifest"
}

@test "install marks htop preexisting=1 when already on PATH" {
    make_tool_preexisting htop
    run_acropolis install
    local preexisting
    preexisting="$(grep "^htop	" "$HOME/.local/share/acropolis/manifest" | cut -f4)"
    [ "$preexisting" = "1" ]
}

@test "install marks htop preexisting=0 when absent from PATH" {
    run_acropolis install
    local preexisting
    preexisting="$(grep "^htop	" "$HOME/.local/share/acropolis/manifest" | cut -f4)"
    [ "$preexisting" = "0" ]
}

# ── Nvim binary ───────────────────────────────────────────────────────────────

@test "install places nvim binary at expected path" {
    run_acropolis install
    [ -f "$HOME/.local/share/acropolis/nvim/bin/nvim" ]
}

@test "install nvim binary reports correct version" {
    run_acropolis install
    local version
    version="$("$HOME/.local/share/acropolis/nvim/bin/nvim" --version 2>/dev/null | head -1)"
    [[ "$version" == *"v0.12.0"* ]]
}

# ── Shell init ────────────────────────────────────────────────────────────────

@test "install writes shell_init" {
    run_acropolis install
    [ -f "$HOME/.local/share/acropolis/shell/shell_init" ]
}

@test "install shell_init adds acropolis nvim/bin to PATH" {
    run_acropolis install
    grep -q "acropolis/nvim/bin" "$HOME/.local/share/acropolis/shell/shell_init"
}

@test "install shell_init conditionally adds ~/.local/bin to PATH" {
    run_acropolis install
    grep -q "case" "$HOME/.local/share/acropolis/shell/shell_init"
}

# ── Bashrc integration ────────────────────────────────────────────────────────

@test "install writes acropolis block to ~/.bashrc" {
    run_acropolis install
    grep -q "# >>> acropolis >>>" "$HOME/.bashrc"
}

@test "install bashrc block has closing marker" {
    run_acropolis install
    grep -q "# <<< acropolis <<<" "$HOME/.bashrc"
}

@test "install bashrc block sources shell_init" {
    run_acropolis install
    grep -q "shell_init" "$HOME/.bashrc"
}

@test "install preserves pre-existing bashrc content" {
    echo "# user content" >> "$HOME/.bashrc"
    run_acropolis install
    grep -q "# user content" "$HOME/.bashrc"
}

# ── Symlink ───────────────────────────────────────────────────────────────────

@test "install creates symlink at ~/.local/bin/acropolis" {
    run_acropolis install
    [ -L "$HOME/.local/bin/acropolis" ]
}

@test "install symlink resolves to acropolis script" {
    run_acropolis install
    local target
    target="$(readlink "$HOME/.local/bin/acropolis")"
    [[ "$target" == *"/acropolis" ]]
}

# ── Idempotency ───────────────────────────────────────────────────────────────

@test "second install exits 0" {
    run_acropolis install
    run_acropolis install
    [ "$status" -eq 0 ]
}

@test "second install does not duplicate bashrc block" {
    run_acropolis install
    run_acropolis install
    local count
    count="$(grep -c "# >>> acropolis >>>" "$HOME/.bashrc")"
    [ "$count" -eq 1 ]
}

@test "second install does not change manifest entry count" {
    run_acropolis install
    local count_before
    count_before="$(wc -l < "$HOME/.local/share/acropolis/manifest")"
    run_acropolis install
    local count_after
    count_after="$(wc -l < "$HOME/.local/share/acropolis/manifest")"
    [ "$count_before" -eq "$count_after" ]
}

# ── Faithful bashrc round-trip ────────────────────────────────────────────────

@test "install then teardown restores ~/.bashrc byte-for-byte (interior blanks preserved)" {
    # A realistic config whose interior double-blank lines must survive untouched.
    printf 'export A=1\n\n\nexport B=2\nalias x=y\n' > "$HOME/.bashrc"
    local before
    before="$(sha256sum "$HOME/.bashrc" | cut -d' ' -f1)"
    run_acropolis install
    confirmed_teardown
    local after
    after="$(sha256sum "$HOME/.bashrc" | cut -d' ' -f1)"
    [ "$before" = "$after" ]
}

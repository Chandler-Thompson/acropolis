#!/usr/bin/env bats

load 'helpers/common'

setup() {
    setup_acropolis_env
    bash "$ACROPOLIS_SCRIPT" install
}
teardown() { teardown_acropolis_env; }

# ── Prompt behaviour ──────────────────────────────────────────────────────────

@test "teardown exits 0 when confirmed" {
    confirmed_teardown
    [ "$status" -eq 0 ]
}

@test "teardown aborts and exits 0 on 'n'" {
    run bash -c "echo n | bash '$ACROPOLIS_SCRIPT' teardown"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Aborted"* ]]
}

@test "teardown aborts on empty input" {
    run bash -c "echo '' | bash '$ACROPOLIS_SCRIPT' teardown"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Aborted"* ]]
}

@test "teardown aborts and leaves directory intact" {
    run bash -c "echo n | bash '$ACROPOLIS_SCRIPT' teardown"
    [ -d "$HOME/.local/share/acropolis" ]
}

# ── Directory removal ─────────────────────────────────────────────────────────

@test "teardown removes ~/.local/share/acropolis/" {
    confirmed_teardown
    [ ! -d "$HOME/.local/share/acropolis" ]
}

@test "teardown removes manifest" {
    confirmed_teardown
    [ ! -f "$HOME/.local/share/acropolis/manifest" ]
}

@test "teardown removes nvim directory" {
    confirmed_teardown
    [ ! -d "$HOME/.local/share/acropolis/nvim" ]
}

@test "teardown removes shell directory" {
    confirmed_teardown
    [ ! -d "$HOME/.local/share/acropolis/shell" ]
}

# ── Bashrc ────────────────────────────────────────────────────────────────────

@test "teardown removes acropolis block from ~/.bashrc" {
    confirmed_teardown
    ! grep -q "# >>> acropolis >>>" "$HOME/.bashrc"
}

@test "teardown removes closing marker from ~/.bashrc" {
    confirmed_teardown
    ! grep -q "# <<< acropolis <<<" "$HOME/.bashrc"
}

@test "teardown removes shell_init source line from ~/.bashrc" {
    confirmed_teardown
    ! grep -q "shell_init" "$HOME/.bashrc"
}

@test "teardown preserves pre-existing bashrc content" {
    echo "# user config" >> "$HOME/.bashrc"
    confirmed_teardown
    grep -q "# user config" "$HOME/.bashrc"
}

@test "teardown leaves ~/.bashrc intact as a file" {
    confirmed_teardown
    [ -f "$HOME/.bashrc" ]
}

# ── Symlink ───────────────────────────────────────────────────────────────────

@test "teardown removes symlink" {
    confirmed_teardown
    [ ! -e "$HOME/.local/bin/acropolis" ]
}

@test "teardown preserves ~/.local/bin/ directory" {
    confirmed_teardown
    [ -d "$HOME/.local/bin" ]
}

# ── Apt tool handling ─────────────────────────────────────────────────────────

@test "teardown removes non-preexisting apt tools" {
    # htop was not preexisting — apt stub installed it in TEST_BIN
    confirmed_teardown
    [ ! -f "${TEST_BIN}/htop" ]
}

@test "teardown removes non-preexisting tmux" {
    confirmed_teardown
    [ ! -f "${TEST_BIN}/tmux" ]
}

@test "teardown preserves preexisting tmux" {
    # Re-setup with tmux as preexisting so manifest records preexisting=1
    teardown_acropolis_env
    setup_acropolis_env
    make_tool_preexisting tmux
    bash "$ACROPOLIS_SCRIPT" install

    confirmed_teardown
    [ -f "${TEST_BIN}/tmux" ]
}

@test "teardown preserves preexisting htop" {
    teardown_acropolis_env
    setup_acropolis_env
    make_tool_preexisting htop
    bash "$ACROPOLIS_SCRIPT" install

    confirmed_teardown
    [ -f "${TEST_BIN}/htop" ]
}

@test "teardown removes non-preexisting tool even when other tools were preexisting" {
    teardown_acropolis_env
    setup_acropolis_env
    make_tool_preexisting tmux   # preexisting=1 — must survive
    # htop not preexisting — must be removed
    bash "$ACROPOLIS_SCRIPT" install

    confirmed_teardown
    [ -f "${TEST_BIN}/tmux" ]
    [ ! -f "${TEST_BIN}/htop" ]
}

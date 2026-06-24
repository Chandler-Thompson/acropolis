#!/usr/bin/env bats

load 'helpers/common'

setup() {
    setup_acropolis_env
    bash "$ACROPOLIS_SCRIPT" install
}
teardown() { teardown_acropolis_env; }

@test "update exits 0" {
    run_acropolis update
    [ "$status" -eq 0 ]
}

@test "update invokes git pull" {
    run_acropolis update
    [[ "$output" == *"Pulling latest Acropolis"* ]]
}

@test "update re-runs install" {
    run_acropolis update
    [[ "$output" == *"Re-running install"* ]]
}

@test "update is idempotent — bashrc block not duplicated" {
    run_acropolis update
    local count
    count="$(grep -c "# >>> acropolis >>>" "$HOME/.bashrc")"
    [ "$count" -eq 1 ]
}

@test "update preserves manifest entries" {
    local before
    before="$(wc -l < "$HOME/.local/share/acropolis/manifest")"
    run_acropolis update
    local after
    after="$(wc -l < "$HOME/.local/share/acropolis/manifest")"
    [ "$before" -eq "$after" ]
}

@test "update keeps nvim binary in place" {
    run_acropolis update
    [ -f "$HOME/.local/share/acropolis/nvim/bin/nvim" ]
}

#!/usr/bin/env bats

load 'helpers/common'

setup() {
    setup_acropolis_env
    bash "$ACROPOLIS_SCRIPT" install
}
teardown() { teardown_acropolis_env; }

@test "status exits 0" {
    run_acropolis status
    [ "$status" -eq 0 ]
}

@test "status lists nvim" {
    run_acropolis status
    [[ "$output" == *"nvim"* ]]
}

@test "status lists tmux" {
    run_acropolis status
    [[ "$output" == *"tmux"* ]]
}

@test "status lists htop" {
    run_acropolis status
    [[ "$output" == *"htop"* ]]
}

@test "status reports bashrc block as present" {
    run_acropolis status
    [[ "$output" == *"~/.bashrc block: present"* ]]
}

@test "status reports symlink as present" {
    run_acropolis status
    [[ "$output" == *"$HOME/.local/bin/acropolis"* ]]
}

@test "status without manifest reports not installed" {
    rm -f "$HOME/.local/share/acropolis/manifest"
    run_acropolis status
    [ "$status" -eq 0 ]
    [[ "$output" == *"no manifest"* ]]
}

@test "status reports bashrc block as absent when not installed" {
    sed -i '/# >>> acropolis >>>/,/# <<< acropolis <<</d' "$HOME/.bashrc"
    run_acropolis status
    [[ "$output" == *"~/.bashrc block: absent"* ]]
}

@test "status reports symlink as absent when missing" {
    rm -f "$HOME/.local/bin/acropolis"
    run_acropolis status
    [[ "$output" == *"absent"* ]]
}

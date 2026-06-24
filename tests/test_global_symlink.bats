#!/usr/bin/env bats
#
# Regression: in real use `acropolis` is invoked through the installed
# ~/.local/bin/acropolis symlink, NOT by its repo path. The script must resolve
# that symlink to locate its own repo (for `update`) and to point the install
# symlink at the real script (never at itself).

load 'helpers/common'

setup() {
    setup_acropolis_env
    bash "$ACROPOLIS_SCRIPT" install
}
teardown() { teardown_acropolis_env; }

# The installed symlink — invoking acropolis the way a user actually does.
GLOBAL="$HOME/.local/bin/acropolis"

@test "global symlink points at the real script, not at itself" {
    local target
    target="$(readlink "$HOME/.local/bin/acropolis")"
    [ "$target" != "$HOME/.local/bin/acropolis" ]
    [ -x "$target" ]
    [ "${target##*/}" = "acropolis" ]
}

@test "install invoked via the global symlink keeps the symlink off itself" {
    run "$HOME/.local/bin/acropolis" install
    [ "$status" -eq 0 ]
    local target
    target="$(readlink "$HOME/.local/bin/acropolis")"
    [ "$target" != "$HOME/.local/bin/acropolis" ]
    [ -x "$target" ]
}

@test "update invoked via the global symlink resolves the repo and pulls" {
    run "$HOME/.local/bin/acropolis" update
    [ "$status" -eq 0 ]
    [[ "$output" == *"Pulling latest Acropolis"* ]]
}

@test "status invoked via the global symlink works" {
    run "$HOME/.local/bin/acropolis" status
    [ "$status" -eq 0 ]
    [[ "$output" == *"nvim"* ]]
}

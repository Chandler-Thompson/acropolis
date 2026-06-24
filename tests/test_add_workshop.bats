#!/usr/bin/env bats

load 'helpers/common'

setup() {
    setup_acropolis_env
    bash "$ACROPOLIS_SCRIPT" install
}
teardown() { teardown_acropolis_env; }

@test "add workshop exits 0" {
    run_acropolis add workshop
    [ "$status" -eq 0 ]
}

@test "add workshop clones into managed directory" {
    run_acropolis add workshop
    [ -d "$HOME/.local/share/acropolis/workshop/.git" ]
}

@test "add workshop records workshop in manifest" {
    run_acropolis add workshop
    grep -q "^workshop	" "$HOME/.local/share/acropolis/manifest"
}

@test "add workshop records method=git in manifest" {
    run_acropolis add workshop
    local method
    method="$(grep "^workshop	" "$HOME/.local/share/acropolis/manifest" | cut -f3)"
    [ "$method" = "git" ]
}

@test "add workshop records preexisting=0 in manifest" {
    run_acropolis add workshop
    local preexisting
    preexisting="$(grep "^workshop	" "$HOME/.local/share/acropolis/manifest" | cut -f4)"
    [ "$preexisting" = "0" ]
}

@test "add workshop launches the workshop session" {
    run_acropolis add workshop
    [[ "$output" == *"workshop session launched"* ]]
}

@test "add workshop accepts a custom URL" {
    run_acropolis add workshop "https://example.com/my-workshop.git"
    [ "$status" -eq 0 ]
    [ -d "$HOME/.local/share/acropolis/workshop" ]
}

@test "add without component prints usage and exits 1" {
    run_acropolis add
    [ "$status" -eq 1 ]
    [[ "$output" == *"usage"* ]]
}

@test "add unknown component exits 1" {
    run_acropolis add foobar
    [ "$status" -eq 1 ]
    [[ "$output" == *"unknown component"* ]]
}

@test "second add workshop pulls instead of re-cloning" {
    run_acropolis add workshop
    run_acropolis add workshop
    [ "$status" -eq 0 ]
    [[ "$output" == *"pulling"* ]]
}

@test "workshop teardown removes workshop clone" {
    bash "$ACROPOLIS_SCRIPT" add workshop
    confirmed_teardown
    [ ! -d "$HOME/.local/share/acropolis/workshop" ]
}

# Shared setup/teardown for all Acropolis bats tests.
# Loaded via `load 'helpers/common'` in each test file.
# BATS_TEST_DIRNAME is the directory of the calling test file (tests/).

ACROPOLIS_SCRIPT="${BATS_TEST_DIRNAME}/../acropolis"
STUBS_DIR="${BATS_TEST_DIRNAME}/stubs"

# Capture the real PATH at load time so _symlink_system_tools can find real binaries
# even after we replace PATH with the restricted test PATH.
_REAL_PATH="$PATH"

# Build a minimal bin dir containing only the system tools the script needs,
# deliberately excluding tmux and htop so tests fully control their presence.
_symlink_system_tools() {
    local tools=(bash sh grep sed awk cut wc find tar gzip dirname head mktemp printf
                 mkdir touch chmod ln rm cp cat readlink id date uname tr xargs)
    for tool in "${tools[@]}"; do
        local real
        real="$(PATH="$_REAL_PATH" command -v "$tool" 2>/dev/null)" || continue
        ln -sf "$real" "${MINIMAL_BIN}/${tool}"
    done
}

setup_acropolis_env() {
    chmod +x "${STUBS_DIR}"/* 2>/dev/null || true

    export TEST_HOME
    TEST_HOME="$(mktemp -d)"
    export HOME="$TEST_HOME"

    # Per-test bin dir where the apt-get stub writes fake tool binaries
    export TEST_BIN
    TEST_BIN="$(mktemp -d)"

    # Minimal system tools dir — no tmux/htop unless the test explicitly adds them
    export MINIMAL_BIN
    MINIMAL_BIN="$(mktemp -d)"
    _symlink_system_tools

    # Stubs shadow real apt-get/curl/git/sudo
    # TEST_BIN holds dynamically created tool stubs (tmux, htop after apt install)
    # MINIMAL_BIN holds only the system utilities the script needs
    export PATH="${STUBS_DIR}:${TEST_BIN}:${MINIMAL_BIN}"

    touch "$HOME/.bashrc"
    mkdir -p "$HOME/.local/bin"
}

teardown_acropolis_env() {
    # Restore real PATH before removing MINIMAL_BIN so that rm remains findable
    # both for any subsequent setup_acropolis_env calls in the same test body
    # and for bats' own post-teardown cleanup.
    export PATH="$_REAL_PATH"
    rm -rf "$TEST_HOME" "$TEST_BIN" "$MINIMAL_BIN"
}

# Place a fake binary for a tool so acropolis treats it as pre-existing on the host
make_tool_preexisting() {
    local tool="$1"
    printf '#!/bin/bash\necho "%s (pre-existing)"\n' "$tool" > "${TEST_BIN}/${tool}"
    chmod +x "${TEST_BIN}/${tool}"
}

run_acropolis() {
    run bash "$ACROPOLIS_SCRIPT" "$@"
}

# Run teardown with automatic 'y' confirmation
confirmed_teardown() {
    run bash -c "echo y | bash '${ACROPOLIS_SCRIPT}' teardown"
}

# Install, then immediately tear down — used by leave-no-trace tests
install_then_teardown() {
    bash "$ACROPOLIS_SCRIPT" install
    echo y | bash "$ACROPOLIS_SCRIPT" teardown
}

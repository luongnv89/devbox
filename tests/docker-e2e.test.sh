#!/usr/bin/env bash
# tests/docker-e2e.test.sh — End-to-end test for the devbox Docker image.
#
# Verifies that the image builds successfully, a container can be created,
# and the five AI CLI tools (opencode, claude, codex, pi, herdr) execute without errors.
#
# Usage:
#   ./tests/docker-e2e.test.sh          # Run all tests
#   ./tests/docker-e2e.test.sh <name>   # Run a specific test

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE_NAME="docker-dev-e2e-test"
CONTAINER_NAME="docker-dev-e2e-$(date +%s)"

PASS=0
FAIL=0
TOTAL=0

# ── Test helpers ──────────────────────────────────────────────────────────────
assert_eq() {
    local test_name="$1" expected="$2" actual="$3"
    TOTAL=$((TOTAL + 1))
    if [[ "$expected" == "$actual" ]]; then
        PASS=$((PASS + 1))
        echo "  ✓ $test_name"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ $test_name"
        echo "    expected: $expected"
        echo "    actual:   $actual"
    fi
}

assert_exit_code() {
    local test_name="$1" expected="$2" actual="$3"
    TOTAL=$((TOTAL + 1))
    if [[ "$expected" == "$actual" ]]; then
        PASS=$((PASS + 1))
        echo "  ✓ $test_name"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ $test_name"
        echo "    expected exit code: $expected"
        echo "    actual exit code:   $actual"
    fi
}

assert_contains() {
    local test_name="$1" haystack="$2" needle="$3"
    TOTAL=$((TOTAL + 1))
    if echo "$haystack" | grep -q "$needle"; then
        PASS=$((PASS + 1))
        echo "  ✓ $test_name"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ $test_name"
        echo "    expected output to contain: $needle"
    fi
}

# ── Cleanup on exit ──────────────────────────────────────────────────────────
cleanup() {
    echo ""
    echo "Cleaning up..."
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rmi "$IMAGE_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# ── Pre-flight: Docker available ─────────────────────────────────────────────
echo "Pre-flight: Docker availability"
TOTAL=$((TOTAL + 1))
if command -v docker &>/dev/null && docker info &>/dev/null; then
    PASS=$((PASS + 1))
    echo "  ✓ Docker is available and running"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Docker is not available or not running"
    echo "  Skipping all tests."
    echo ""
    echo "═══════════════════════════════════════"
    echo "Results: $PASS/$TOTAL passed, $FAIL failed"
    echo "═══════════════════════════════════════"
    exit 1
fi

# ── Test 1: Build the Docker image ────────────────────────────────────────────
echo ""
echo "Test 1: Build Docker image"
TOTAL=$((TOTAL + 1))
build_output=$(docker build -t "$IMAGE_NAME" "$REPO_ROOT" 2>&1)
build_exit=$?
if [[ $build_exit -eq 0 ]]; then
    PASS=$((PASS + 1))
    echo "  ✓ Docker image built successfully"
    # Verify the image exists
    TOTAL=$((TOTAL + 1))
    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        PASS=$((PASS + 1))
        echo "  ✓ Image exists in local registry"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ Image not found after build"
    fi
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Docker build failed"
    echo "    Build output (last 20 lines):"
    echo "$build_output" | tail -20
fi

# ── Test 2: Create and start the container ─────────────────────────────────────
echo ""
echo "Test 2: Create container"
TOTAL=$((TOTAL + 1))
create_output=$(docker run -d --name "$CONTAINER_NAME" "$IMAGE_NAME" sleep infinity 2>&1)
create_exit=$?
if [[ $create_exit -eq 0 ]]; then
    PASS=$((PASS + 1))
    echo "  ✓ Container created and started successfully"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Container creation failed"
    echo "    Output: $create_output"
fi

# ── Test 3: opencode CLI executes without error ───────────────────────────────
echo ""
echo "Test 3: opencode CLI execution"
TOTAL=$((TOTAL + 1))
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    opencode_output=$(docker exec "$CONTAINER_NAME" opencode --version 2>&1)
    opencode_exit=$?
    # `opencode --version` prints a bare semver (e.g. "1.18.35"), not the tool name.
    if [[ $opencode_exit -eq 0 ]] && echo "$opencode_output" | grep -qE '[0-9]+\.[0-9]+\.[0-9]+'; then
        PASS=$((PASS + 1))
        echo "  ✓ opencode executes without error"
        echo "    Version: $(echo "$opencode_output" | head -1)"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ opencode execution failed (exit=$opencode_exit)"
        echo "    Output: $opencode_output"
    fi
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Container not running — skipping opencode test"
fi

# ── Test 4: claude CLI executes without error ────────────────────────────────
echo ""
echo "Test 4: claude CLI execution"
TOTAL=$((TOTAL + 1))
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    claude_output=$(docker exec "$CONTAINER_NAME" claude --version 2>&1)
    claude_exit=$?
    if [[ $claude_exit -eq 0 ]] && echo "$claude_output" | grep -qi "claude"; then
        PASS=$((PASS + 1))
        echo "  ✓ claude executes without error"
        echo "    Version: $(echo "$claude_output" | head -1)"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ claude execution failed (exit=$claude_exit)"
        echo "    Output: $claude_output"
    fi
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Container not running — skipping claude test"
fi

# ── Test 5: codex CLI executes without error ─────────────────────────────────
echo ""
echo "Test 5: codex CLI execution"
TOTAL=$((TOTAL + 1))
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    codex_output=$(docker exec "$CONTAINER_NAME" codex --version 2>&1)
    codex_exit=$?
    if [[ $codex_exit -eq 0 ]] && echo "$codex_output" | grep -qi "codex"; then
        PASS=$((PASS + 1))
        echo "  ✓ codex executes without error"
        echo "    Version: $(echo "$codex_output" | head -1)"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ codex execution failed (exit=$codex_exit)"
        echo "    Output: $codex_output"
    fi
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Container not running — skipping codex test"
fi

# ── Test 6: pi CLI executes without error ─────────────────────────────────────
echo ""
echo "Test 6: pi CLI execution"
TOTAL=$((TOTAL + 1))
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    pi_output=$(docker exec "$CONTAINER_NAME" pi --version 2>&1)
    pi_exit=$?
    if [[ $pi_exit -eq 0 ]]; then
        PASS=$((PASS + 1))
        echo "  ✓ pi executes without error"
        echo "    Version: $(echo "$pi_output" | head -1)"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ pi execution failed (exit=$pi_exit)"
        echo "    Output: $pi_output"
    fi
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Container not running — skipping pi test"
fi

# ── Test 7: herdr CLI executes without error ──────────────────────────────────
echo ""
echo "Test 7: herdr CLI execution"
TOTAL=$((TOTAL + 1))
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    herdr_output=$(docker exec "$CONTAINER_NAME" herdr --version 2>&1)
    herdr_exit=$?
    if [[ $herdr_exit -eq 0 ]] && echo "$herdr_output" | grep -qi "herdr"; then
        PASS=$((PASS + 1))
        echo "  ✓ herdr executes without error"
        echo "    Version: $(echo "$herdr_output" | head -1)"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ herdr execution failed (exit=$herdr_exit)"
        echo "    Output: $herdr_output"
    fi
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Container not running — skipping herdr test"
fi

# ── Test 8: All five CLIs are on PATH ─────────────────────────────────────────
echo ""
echo "Test 8: CLI tools on PATH"
TOTAL=$((TOTAL + 1))
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    path_check=$(docker exec "$CONTAINER_NAME" bash -c 'command -v opencode && command -v claude && command -v codex && command -v pi && command -v herdr' 2>&1)
    path_exit=$?
    if [[ $path_exit -eq 0 ]]; then
        PASS=$((PASS + 1))
        echo "  ✓ All five CLIs found on PATH"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ One or more CLIs not on PATH"
        echo "    Output: $path_check"
    fi
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Container not running — skipping PATH check"
fi

# ── Regression: OpenCode is accessible without root or credentials ──────────
echo ""
echo "Test 9: non-root OpenCode execution"
nonroot_exit=0
nonroot_output=$(docker run --rm --user 1000:1000 -e HOME=/tmp \
    --entrypoint bash "$IMAGE_NAME" -c '
        set -e
        test -w "$HOME"
        test ! -L /usr/local/bin/opencode
        /usr/local/bin/opencode --version
    ' 2>&1) || nonroot_exit=$?
assert_exit_code "numeric user can execute installed OpenCode" 0 "$nonroot_exit"
assert_contains "non-root OpenCode prints a version" "$nonroot_output" '[0-9]\+\.[0-9]\+\.[0-9]\+'

# Exercise the generated updater with a fake installer, stopping at npm before
# any other tool can update. Seed a legacy root symlink to test its replacement.
echo ""
echo "Test 10: updater preserves globally accessible OpenCode"
updater_exit=0
updater_output=$(docker exec -i -e HOME=/tmp "$CONTAINER_NAME" bash <<'UPDATER_TEST_EOF'
set -euo pipefail
mkdir -p /root/.local/bin
trap 'rm -f /root/.local/bin/curl /root/.local/bin/npm' EXIT
cat > /root/.local/bin/curl <<'FAKE_CURL_EOF'
#!/usr/bin/env bash
# Only the OpenCode installer is permitted; never make a network request.
[[ "$*" == '-fsSL https://opencode.ai/v2/install' ]] || exit 99
cat <<'FAKE_INSTALL_EOF'
set -e
[[ "$HOME" == /root ]]
[[ "$*" == --no-modify-path ]]
mkdir -p "$HOME/.opencode/bin"
printf '#!/usr/bin/env bash\nprintf "opencode v0.0.0-updater-test\\n"\n' > "$HOME/.opencode/bin/opencode"
chmod 0755 "$HOME/.opencode/bin/opencode"
FAKE_INSTALL_EOF
FAKE_CURL_EOF
printf '#!/usr/bin/env bash\nexit 77\n' > /root/.local/bin/npm
chmod 0755 /root/.local/bin/curl /root/.local/bin/npm
rm -f /usr/local/bin/opencode
ln -s /root/.opencode/bin/opencode /usr/local/bin/opencode
status=0
/usr/local/bin/update-ai-tools || status=$?
test "$status" -eq 77
test ! -L /usr/local/bin/opencode
test "$(stat -c %a /usr/local/bin/opencode)" = 755
test "$(stat -c %a /root)" = 700
UPDATER_TEST_EOF
) || updater_exit=$?
assert_exit_code "updater replaces root symlink and keeps /root private" 0 "$updater_exit"
updated_exit=0
updated_output=$(docker exec --user 1000:1000 -e HOME=/tmp "$CONTAINER_NAME" \
    /usr/local/bin/opencode --version 2>&1) || updated_exit=$?
assert_exit_code "numeric user can execute updated OpenCode" 0 "$updated_exit"
assert_eq "updater installed the controlled binary" "opencode v0.0.0-updater-test" "$updated_output"

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════"
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
echo "═══════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0

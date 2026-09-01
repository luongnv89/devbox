#!/usr/bin/env bash
# tests/docker-e2e.test.sh — End-to-end test for the devbox Docker image.
#
# Verifies that the image builds successfully, a container can be created,
# and the three AI CLI tools (opencode2, pi, herdr) execute without errors.
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

# ── Test 3: opencode2 CLI executes without error ──────────────────────────────
echo ""
echo "Test 3: opencode2 CLI execution"
TOTAL=$((TOTAL + 1))
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    opencode_output=$(docker exec "$CONTAINER_NAME" opencode2 --version 2>&1)
    opencode_exit=$?
    if [[ $opencode_exit -eq 0 ]] && echo "$opencode_output" | grep -qi "opencode"; then
        PASS=$((PASS + 1))
        echo "  ✓ opencode2 executes without error"
        echo "    Version: $(echo "$opencode_output" | head -1)"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ opencode2 execution failed (exit=$opencode_exit)"
        echo "    Output: $opencode_output"
    fi
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Container not running — skipping opencode2 test"
fi

# ── Test 4: pi CLI executes without error ─────────────────────────────────────
echo ""
echo "Test 4: pi CLI execution"
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

# ── Test 5: herdr CLI executes without error ──────────────────────────────────
echo ""
echo "Test 5: herdr CLI execution"
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

# ── Test 6: All three CLIs are on PATH ────────────────────────────────────────
echo ""
echo "Test 6: CLI tools on PATH"
TOTAL=$((TOTAL + 1))
if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    path_check=$(docker exec "$CONTAINER_NAME" bash -c 'command -v opencode2 && command -v pi && command -v herdr' 2>&1)
    path_exit=$?
    if [[ $path_exit -eq 0 ]]; then
        PASS=$((PASS + 1))
        echo "  ✓ All three CLIs found on PATH"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ One or more CLIs not on PATH"
        echo "    Output: $path_check"
    fi
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Container not running — skipping PATH check"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════"
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
echo "═══════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0

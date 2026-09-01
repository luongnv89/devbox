#!/usr/bin/env bash
# tests/devbox-launch.test.sh — Automated tests for devbox-launch.sh
#
# These tests verify the script's argument parsing, validation, and
# docker command generation without actually running a container.
#
# Usage:
#   ./tests/devbox-launch.test.sh          # Run all tests
#   ./tests/devbox-launch.test.sh <name>   # Run a specific test

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LAUNCH_SCRIPT="$REPO_ROOT/devbox-launch.sh"

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

# ── Test: Script is executable ───────────────────────────────────────────────
echo "Test: Script is executable"
TOTAL=$((TOTAL + 1))
if [[ -x "$LAUNCH_SCRIPT" ]]; then
    PASS=$((PASS + 1))
    echo "  ✓ Script has execute permission"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Script is not executable"
fi

# ── Test: Syntax validation ──────────────────────────────────────────────────
echo ""
echo "Test: Bash syntax"
TOTAL=$((TOTAL + 1))
if bash -n "$LAUNCH_SCRIPT" 2>/dev/null; then
    PASS=$((PASS + 1))
    echo "  ✓ Bash syntax is valid"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Bash syntax errors found"
fi

# ── Test: Help flag ──────────────────────────────────────────────────────────
echo ""
echo "Test: --help flag"
TOTAL=$((TOTAL + 1))
if bash "$LAUNCH_SCRIPT" --help >/dev/null 2>&1; then
    PASS=$((PASS + 1))
    echo "  ✓ --help exits cleanly"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ --help failed"
fi

# ── Test: Argument parsing — workspace ────────────────────────────────────────
echo ""
echo "Test: Argument parsing"

# Test --workspace / -w
TOTAL=$((TOTAL + 1))
mkdir -p /tmp/test-workspace
output=$(bash "$LAUNCH_SCRIPT" -w /tmp/test-workspace 2>&1 || true)
if echo "$output" | grep -q "Workspace: /tmp/test-workspace"; then
    PASS=$((PASS + 1))
    echo "  ✓ -w/--workspace sets workspace"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ -w/--workspace failed"
fi

# Test --name / -n
TOTAL=$((TOTAL + 1))
output=$(bash "$LAUNCH_SCRIPT" -n my-custom-name 2>&1 || true)
if echo "$output" | grep -q "Container: my-custom-name"; then
    PASS=$((PASS + 1))
    echo "  ✓ -n/--name sets container name"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ -n/--name failed"
fi

# Test --detach / -d
TOTAL=$((TOTAL + 1))
output=$(bash "$LAUNCH_SCRIPT" -d 2>&1 || true)
if echo "$output" | grep -q "detached mode"; then
    PASS=$((PASS + 1))
    echo "  ✓ -d/--detach enables detached mode"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ -d/--detach failed"
fi

# ── Test: Default workspace is current directory ─────────────────────────────
echo ""
echo "Test: Default workspace"
TOTAL=$((TOTAL + 1))
output=$(cd /tmp && bash "$LAUNCH_SCRIPT" 2>&1 || true)
if echo "$output" | grep -q "Workspace: /tmp"; then
    PASS=$((PASS + 1))
    echo "  ✓ Default workspace is current directory"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Default workspace failed"
fi

# ── Test: Container name format ──────────────────────────────────────────────
echo ""
echo "Test: Container name generation"
TOTAL=$((TOTAL + 1))
output=$(bash "$LAUNCH_SCRIPT" 2>&1 || true)
# Extract the generated name from the output
generated_name=$(echo "$output" | sed -n 's/.*Container: \([^ ]*\).*/\1/p' || true)
if [[ "$generated_name" == devbox-* ]]; then
    PASS=$((PASS + 1))
    echo "  ✓ Auto-generated name has 'devbox-' prefix"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Auto-generated name format incorrect: $generated_name"
fi

# ── Test: Docker image default ───────────────────────────────────────────────
echo ""
echo "Test: Docker image configuration"
TOTAL=$((TOTAL + 1))
output=$(bash "$LAUNCH_SCRIPT" 2>&1 || true)
if echo "$output" | grep -q "Image:.*ghcr.io/luongnv89/devbox"; then
    PASS=$((PASS + 1))
    echo "  ✓ Default image is ghcr.io/luongnv89/devbox"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Default image incorrect"
fi

# ── Test: Validation — nonexistent workspace ──────────────────────────────────
echo ""
echo "Test: Validation"
TOTAL=$((TOTAL + 1))
bash "$LAUNCH_SCRIPT" -w /nonexistent/path 2>/dev/null || exit_code=$?
if [[ ${exit_code:-0} -ne 0 ]]; then
    PASS=$((PASS + 1))
    echo "  ✓ Rejects nonexistent workspace directory"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Should reject nonexistent workspace"
fi

# ── Test: Validation — unknown option ────────────────────────────────────────
TOTAL=$((TOTAL + 1))
bash "$LAUNCH_SCRIPT" --unknown-option 2>/dev/null || exit_code=$?
if [[ ${exit_code:-0} -ne 0 ]]; then
    PASS=$((PASS + 1))
    echo "  ✓ Rejects unknown options"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Should reject unknown options"
fi

# ── Test: Script contains required mount paths ───────────────────────────────
echo ""
echo "Test: Required mount paths"

# ~/.agents mount
TOTAL=$((TOTAL + 1))
if grep -q '\.agents.*:/root/\.agents' "$LAUNCH_SCRIPT"; then
    PASS=$((PASS + 1))
    echo "  ✓ Mounts ~/.agents → /root/.agents"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Missing ~/.agents mount"
fi

# SSH mount
TOTAL=$((TOTAL + 1))
if grep -q '\.ssh.*:/root/\.ssh' "$LAUNCH_SCRIPT"; then
    PASS=$((PASS + 1))
    echo "  ✓ Mounts ~/.ssh → /root/.ssh"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Missing ~/.ssh mount"
fi

# SSH agent forwarding
TOTAL=$((TOTAL + 1))
if grep -q 'SSH_AUTH_SOCK' "$LAUNCH_SCRIPT"; then
    PASS=$((PASS + 1))
    echo "  ✓ Forwards SSH agent"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Missing SSH agent forwarding"
fi

# ── Test: Script contains required features ──────────────────────────────────
echo ""
echo "Test: Feature completeness"

# Workspace mount
TOTAL=$((TOTAL + 1))
if grep -q '/workspace' "$LAUNCH_SCRIPT"; then
    PASS=$((PASS + 1))
    echo "  ✓ Workspace mount point: /workspace"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Missing workspace mount"
fi

# Port mapping support
TOTAL=$((TOTAL + 1))
if grep -q '\-\-port\|-p,' "$LAUNCH_SCRIPT" || grep -q '\-p.*PORT' "$LAUNCH_SCRIPT"; then
    PASS=$((PASS + 1))
    echo "  ✓ Port mapping support"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Missing port mapping support"
fi

# Environment variable support
TOTAL=$((TOTAL + 1))
if grep -q '\-\-env\|-e,' "$LAUNCH_SCRIPT" || grep -q '\-e.*ENV' "$LAUNCH_SCRIPT"; then
    PASS=$((PASS + 1))
    echo "  ✓ Environment variable support"
else
    FAIL=$((FAIL + 1))
    echo "  ✗ Missing environment variable support"
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

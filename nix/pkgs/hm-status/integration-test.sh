#!/usr/bin/env bash
# Integration test for hm-status CLI.
# Exercises the real binary against scripted jj repositories.
set -euo pipefail

HM_STATUS="${1:?Usage: $0 <path-to-hm-status>}"
failures=0

# ── helpers ────────────────────────────────────────────────────────

pass() { echo "  ✓ $1"; }
fail() {
  echo "  ✗ $1"
  echo "    expected: $2"
  echo "    got:      $3"
  failures=$((failures + 1))
}

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    pass "$label"
  else
    fail "$label" "$expected" "$actual"
  fi
}

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    pass "$label"
  else
    fail "$label" "contains '$needle'" "$haystack"
  fi
}

assert_exit() {
  local label="$1" expected="$2"
  shift 2
  local actual=0
  "$@" >/dev/null 2>&1 || actual=$?
  assert_eq "$label" "$expected" "$actual"
}

# Create a fresh jj repo backed by a bare git "origin" remote.
# This gives us trunk() = main@origin.
make_repo() {
  local repo="$1"
  local origin="${repo}.origin"

  git init --bare "$origin" >/dev/null 2>&1

  jj git init "$repo" >/dev/null 2>&1
  jj git remote add origin "$origin" -R "$repo" 2>/dev/null

  # Seed with an initial commit so main exists.
  echo "init" >"${repo}/file.txt"
  jj describe -m "initial commit" -R "$repo" >/dev/null 2>&1
  jj new -R "$repo" >/dev/null 2>&1
  jj bookmark set main -r @- -R "$repo" >/dev/null 2>&1
  jj git push --bookmark main -R "$repo" >/dev/null 2>&1
}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/fakehome"
mkdir -p "$HOME"

# jj needs user config
mkdir -p "$HOME/.config/jj"
cat >"$HOME/.config/jj/config.toml" <<'TOML'
[user]
name = "Test"
email = "test@test"
TOML

echo "=== hm-status integration tests ==="

# ── Test 1: synced + clean ─────────────────────────────────────────

echo ""
echo "-- synced + clean --"
make_repo "$WORK/repo1"

out=$("$HM_STATUS" --short "$WORK/repo1")
assert_eq "short output" "✓" "$out"

out=$("$HM_STATUS" "$WORK/repo1")
assert_contains "long: in sync" "In sync with trunk" "$out"
assert_contains "long: clean" "Working copy is clean" "$out"

assert_exit "exit 0 without --fail" 0 "$HM_STATUS" "$WORK/repo1"
assert_exit "exit 0 with --fail (synced)" 0 "$HM_STATUS" --fail "$WORK/repo1"

# ── Test 2: dirty working copy ─────────────────────────────────────

echo ""
echo "-- synced + dirty --"
make_repo "$WORK/repo2"
echo "dirty" >"${WORK}/repo2/dirty.txt"
# Trigger jj snapshot so it sees the change
jj log -R "$WORK/repo2" -r @ --no-graph -T 'empty' >/dev/null 2>&1

out=$("$HM_STATUS" --short "$WORK/repo2")
assert_eq "short output" "●" "$out"

out=$("$HM_STATUS" "$WORK/repo2")
assert_contains "long: in sync" "In sync with trunk" "$out"
assert_contains "long: has changes" "Working copy has changes" "$out"

# Dirty but synced → --fail should still exit 0
assert_exit "exit 0 with --fail (dirty but synced)" 0 "$HM_STATUS" --fail "$WORK/repo2"

# ── Test 3: ahead of trunk ─────────────────────────────────────────

echo ""
echo "-- ahead of trunk --"
make_repo "$WORK/repo3"
echo "change1" >"${WORK}/repo3/change1.txt"
jj describe -m "local commit 1" -R "$WORK/repo3" >/dev/null 2>&1
jj new -R "$WORK/repo3" >/dev/null 2>&1
echo "change2" >"${WORK}/repo3/change2.txt"
jj describe -m "local commit 2" -R "$WORK/repo3" >/dev/null 2>&1
jj new -R "$WORK/repo3" >/dev/null 2>&1

out=$("$HM_STATUS" --short "$WORK/repo3")
assert_eq "short output" "↑2" "$out"

out=$("$HM_STATUS" "$WORK/repo3")
assert_contains "long: ahead" "2 commits ahead of trunk" "$out"
assert_contains "long: ahead commit 2" "· local commit 2" "$out"
assert_contains "long: ahead commit 1" "· local commit 1" "$out"

assert_exit "exit 1 with --fail (ahead)" 1 "$HM_STATUS" --fail "$WORK/repo3"

# ── Test 4: behind trunk ───────────────────────────────────────────

echo ""
echo "-- behind trunk --"
make_repo "$WORK/repo4"

# Save the initial commit (what main@origin currently points to).
initial=$(jj log -R "$WORK/repo4" -r 'main@origin' --no-graph -T 'commit_id.short()')

# Add commits and push them to advance main@origin.
echo "remote1" >"${WORK}/repo4/remote1.txt"
jj describe -m "remote commit 1" -R "$WORK/repo4" >/dev/null 2>&1
jj new -R "$WORK/repo4" >/dev/null 2>&1
echo "remote2" >"${WORK}/repo4/remote2.txt"
jj describe -m "remote commit 2" -R "$WORK/repo4" >/dev/null 2>&1
jj bookmark set main -r @ -R "$WORK/repo4" --allow-backwards >/dev/null 2>&1
jj git push --bookmark main -R "$WORK/repo4" >/dev/null 2>&1

# Move the working copy back to the initial commit so we are behind.
jj new "$initial" -R "$WORK/repo4" >/dev/null 2>&1

out=$("$HM_STATUS" --short "$WORK/repo4")
assert_eq "short output" "↓2" "$out"

out=$("$HM_STATUS" "$WORK/repo4")
assert_contains "long: behind" "2 commits behind trunk" "$out"
assert_contains "long: behind commit 2" "· remote commit 2" "$out"
assert_contains "long: behind commit 1" "· remote commit 1" "$out"

assert_exit "exit 1 with --fail (behind)" 1 "$HM_STATUS" --fail "$WORK/repo4"

# ── Test 5: many commits behind (truncation) ──────────────────────

echo ""
echo "-- many commits behind (truncation) --"
make_repo "$WORK/repo5"

initial=$(jj log -R "$WORK/repo5" -r 'main@origin' --no-graph -T 'commit_id.short()')

# Create 7 commits and push them to advance main@origin.
for i in $(seq 1 7); do
  echo "remote$i" >"${WORK}/repo5/remote${i}.txt"
  jj describe -m "remote change $i" -R "$WORK/repo5" >/dev/null 2>&1
  jj new -R "$WORK/repo5" >/dev/null 2>&1
done
jj bookmark set main -r @- -R "$WORK/repo5" --allow-backwards >/dev/null 2>&1
jj git push --bookmark main -R "$WORK/repo5" >/dev/null 2>&1

# Move back to the initial commit.
jj new "$initial" -R "$WORK/repo5" >/dev/null 2>&1

out=$("$HM_STATUS" --short "$WORK/repo5")
assert_eq "short output" "↓7" "$out"

out=$("$HM_STATUS" "$WORK/repo5")
assert_contains "long: behind" "7 commits behind trunk" "$out"
assert_contains "long: shows commit 7" "· remote change 7" "$out"
assert_contains "long: shows commit 3" "· remote change 3" "$out"
assert_contains "long: truncation" "· ... and 2 more" "$out"

# ── Test 6: ahead + dirty ──────────────────────────────────────────

echo ""
echo "-- ahead + dirty --"
make_repo "$WORK/repo6"
echo "change" >"${WORK}/repo6/change.txt"
jj describe -m "local commit" -R "$WORK/repo6" >/dev/null 2>&1
jj new -R "$WORK/repo6" >/dev/null 2>&1
echo "uncommitted" >"${WORK}/repo6/uncommitted.txt"
jj log -R "$WORK/repo6" -r @ --no-graph -T 'empty' >/dev/null 2>&1

out=$("$HM_STATUS" --short "$WORK/repo6")
assert_eq "short output" "↑1●" "$out"

assert_exit "exit 1 with --fail (ahead+dirty)" 1 "$HM_STATUS" --fail "$WORK/repo6"

# ── Test 7: error case (not a jj repo) ─────────────────────────────

echo ""
echo "-- error case --"
mkdir -p "$WORK/not-a-repo"

assert_exit "exit 2 on invalid repo" 2 "$HM_STATUS" "$WORK/not-a-repo"
assert_exit "exit 2 on invalid repo (short)" 2 "$HM_STATUS" --short "$WORK/not-a-repo"

# ── Summary ─────────────────────────────────────────────────────────

echo ""
if [ "$failures" -eq 0 ]; then
  echo "All tests passed!"
  exit 0
else
  echo "$failures test(s) FAILED"
  exit 1
fi

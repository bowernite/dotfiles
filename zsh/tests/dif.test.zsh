#!/usr/bin/env zsh
# Black-box tests for `dif` / `git_parent_branch` (zsh/zshrc__git).
# Each test builds a scratch git repo and asserts on dif's output only.
#
# Run: zsh zsh/tests/dif.test.zsh

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/../zshrc__git"

# zshrc__git aliases `g`; we want our own hermetic git helper
unalias g 2>/dev/null

typeset -i PASS=0 FAIL=0
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT

# git with hermetic identity/config so tests don't depend on user config
g() {
  git -c init.defaultBranch=develop -c user.email=t@test -c user.name=t \
    -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"
}

commit_file() {
  echo "${2:-content}" >"$1"
  g add -A >/dev/null
  g commit -qm "add $1"
}

assert_contains() {
  local haystack=$1 needle=$2 label=$3
  if [[ "$haystack" == *"$needle"* ]]; then
    PASS+=1
    echo "  ✓ $label"
  else
    FAIL+=1
    echo "  ✗ $label"
    echo "    expected to contain: $needle"
    echo "    got: ${haystack:0:400}"
  fi
}

assert_not_contains() {
  local haystack=$1 needle=$2 label=$3
  if [[ "$haystack" != *"$needle"* ]]; then
    PASS+=1
    echo "  ✓ $label"
  else
    FAIL+=1
    echo "  ✗ $label"
    echo "    expected NOT to contain: $needle"
    echo "    got: ${haystack:0:400}"
  fi
}

# Fresh "origin" repo with:
#   develop:   base.txt
#   feature/x: base.txt + migration.txt  (a merged parent PR)
# and a clone of it (clone has local develop only; feature/x is remote-only).
# Leaves cwd inside the clone.
setup_clone_with_remote_feature() {
  local name=$1
  mkdir -p "$TMP_ROOT/$name-origin"
  cd "$TMP_ROOT/$name-origin"
  g init -q
  commit_file base.txt
  g checkout -qb feature/x
  commit_file migration.txt
  g checkout -q develop
  cd "$TMP_ROOT"
  g clone -q "$name-origin" "$name" 2>/dev/null
  cd "$TMP_ROOT/$name"
}

# ---------------------------------------------------------------------------
test_remote_only_parent() {
  echo "test: branch off a remote-only feature branch compares against it (the PHY-1146 bug)"
  setup_clone_with_remote_feature t1
  g checkout -qb my-branch origin/feature/x
  commit_file mine.txt
  local out=$(dif --exclude-uncommitted --stat 2>&1)
  assert_contains "$out" "mine.txt" "diff includes my file"
  assert_not_contains "$out" "migration.txt" "diff excludes the merged parent PR's file"
  assert_contains "$out" "feature/x" "reports the feature branch as compare target"
}

# ---------------------------------------------------------------------------
test_branch_off_local_develop() {
  echo "test: branch off local develop still compares against develop"
  setup_clone_with_remote_feature t2
  g checkout -qb my-branch develop
  commit_file mine.txt
  local out=$(dif --exclude-uncommitted --stat 2>&1)
  assert_contains "$out" "mine.txt" "diff includes my file"
  assert_not_contains "$out" "base.txt" "diff excludes develop's own files"
  assert_contains "$out" "develop" "reports develop as compare target"
}

# ---------------------------------------------------------------------------
test_stacked_branches() {
  echo "test: stacked branch compares against its immediate parent, not develop"
  setup_clone_with_remote_feature t3
  g checkout -qb branch-a develop
  commit_file a.txt
  g checkout -qb branch-b
  commit_file b.txt
  local out=$(dif --exclude-uncommitted --stat 2>&1)
  assert_contains "$out" "b.txt" "diff includes the stacked branch's file"
  assert_not_contains "$out" "a.txt" "diff excludes the parent branch's file"
  assert_contains "$out" "branch-a" "reports branch-a as compare target"
}

# ---------------------------------------------------------------------------
test_stale_local_develop() {
  echo "test: stale local develop doesn't hijack; compares against moved origin/develop"
  setup_clone_with_remote_feature t4
  # upstream develop moves on after our clone; we fetch but local develop stays stale
  (cd "$TMP_ROOT/t4-origin" && commit_file upstream.txt)
  g fetch -q origin
  g checkout -qb my-branch origin/develop
  commit_file mine.txt
  local out=$(dif --exclude-uncommitted --stat 2>&1)
  assert_contains "$out" "mine.txt" "diff includes my file"
  assert_not_contains "$out" "upstream.txt" "diff excludes upstream commits since local develop"
  assert_contains "$out" "origin/develop" "reports origin/develop as compare target"
}

# ---------------------------------------------------------------------------
test_explicit_branch() {
  echo "test: explicitly passed branch wins over parent detection"
  setup_clone_with_remote_feature t5
  g checkout -qb branch-a develop
  commit_file a.txt
  g checkout -qb branch-b
  commit_file b.txt
  # parent detection would say branch-a; we explicitly ask for develop
  local out=$(dif develop --exclude-uncommitted --stat 2>&1)
  assert_contains "$out" "b.txt" "diff includes my file"
  assert_contains "$out" "a.txt" "diff includes intermediate branch's file (since comparing to develop)"
  assert_contains "$out" "develop" "reports develop as compare target"
}

# ---------------------------------------------------------------------------
test_not_a_git_repo() {
  echo "test: outside a git repo fails with a meaningful error"
  mkdir -p "$TMP_ROOT/not-a-repo"
  cd "$TMP_ROOT/not-a-repo"
  local out rc
  out=$(dif 2>&1)
  rc=$?
  assert_contains "$out" "not in a git repo" "explains the problem"
  if ((rc != 0)); then
    PASS+=1
    echo "  ✓ exits non-zero"
  else
    FAIL+=1
    echo "  ✗ exits non-zero (got rc=$rc)"
  fi
}

test_unrelated_histories() {
  echo "test: comparing against an unrelated (orphan) branch fails meaningfully"
  setup_clone_with_remote_feature t6
  g checkout -q --orphan orphan
  g rm -qrf . 2>/dev/null
  commit_file orphan.txt
  g checkout -qb my-branch develop
  commit_file mine.txt
  local out rc
  out=$(dif orphan --exclude-uncommitted 2>&1)
  rc=$?
  assert_contains "$out" "no merge base" "explains the problem"
  if ((rc != 0)); then
    PASS+=1
    echo "  ✓ exits non-zero"
  else
    FAIL+=1
    echo "  ✗ exits non-zero (got rc=$rc)"
  fi
}

# ---------------------------------------------------------------------------
test_uncommitted_and_lockfile() {
  echo "test: uncommitted changes included by default; package-lock.json excluded"
  setup_clone_with_remote_feature t7
  g checkout -qb my-branch develop
  commit_file mine.txt
  echo "wip" >uncommitted.txt
  g add uncommitted.txt
  echo "unstaged" >>mine.txt
  echo '{}' >package-lock.json
  g add package-lock.json
  local out=$(dif --stat 2>&1)
  assert_contains "$out" "mine.txt" "committed + unstaged file present"
  assert_contains "$out" "uncommitted.txt" "staged file present"
  assert_not_contains "$out" "package-lock.json" "package-lock.json excluded"
  local out_excl=$(dif --exclude-uncommitted --stat 2>&1)
  assert_not_contains "$out_excl" "uncommitted.txt" "--exclude-uncommitted hides staged file"
}

# ---------------------------------------------------------------------------
test_dif_on_develop_itself() {
  echo "test: dif on develop itself shows only unpushed commits (vs origin/develop)"
  setup_clone_with_remote_feature t8
  g checkout -q develop
  commit_file local-only.txt
  local out=$(dif --exclude-uncommitted --stat 2>&1)
  assert_contains "$out" "local-only.txt" "diff includes unpushed commit"
  assert_not_contains "$out" "base.txt" "diff excludes already-pushed history"
  assert_contains "$out" "origin/develop" "reports origin/develop as compare target"
}

# ---------------------------------------------------------------------------
test_pushed_feature_branch() {
  echo "test: pushed feature branch still compares against its parent (not its own remote copy)"
  setup_clone_with_remote_feature t9
  g checkout -qb my-branch develop
  commit_file mine.txt
  g push -q origin my-branch 2>/dev/null
  local out=$(dif --exclude-uncommitted --stat 2>&1)
  assert_contains "$out" "mine.txt" "diff includes my file (not an empty self-compare)"
  assert_contains "$out" "develop" "reports develop as compare target"
}

# ---------------------------------------------------------------------------
test_descendant_branch_not_parent() {
  echo "test: a branch stacked on top of mine is not treated as my parent"
  setup_clone_with_remote_feature t10
  g checkout -qb my-branch develop
  commit_file mine.txt
  g checkout -qb stacked-on-mine
  commit_file theirs.txt
  g checkout -q my-branch
  local out=$(dif --exclude-uncommitted --stat 2>&1)
  assert_contains "$out" "mine.txt" "diff includes my file (not an empty compare against the descendant)"
  assert_not_contains "$out" "stacked-on-mine" "descendant branch is not the compare target"
  assert_contains "$out" "develop" "reports develop as compare target"
}

# ---------------------------------------------------------------------------
test_develop_behind_origin() {
  echo "test: on develop behind origin/develop, compares to origin/develop (empty diff, no hijack)"
  setup_clone_with_remote_feature t11
  # upstream develop moves on; we fetch but stay behind
  (cd "$TMP_ROOT/t11-origin" && commit_file upstream.txt)
  g fetch -q origin
  g checkout -q develop
  local out=$(dif --exclude-uncommitted --stat 2>&1)
  assert_contains "$out" "origin/develop" "reports origin/develop as compare target"
  assert_not_contains "$out" "feature/x" "a random feature branch is not the compare target"
  assert_not_contains "$out" "upstream.txt" "upstream commits are not shown as ours"
}

test_sibling_forked_from_my_branch() {
  echo "test: a colleague's branch forked from my branch's own commit is not my parent"
  setup_clone_with_remote_feature t12
  g checkout -qb feature/big-thing origin/develop
  commit_file work1.txt
  commit_file work2.txt
  # colleague forks from mid-feature commit and pushes; we fetch their ref
  g push -q origin feature/big-thing 2>/dev/null
  (cd "$TMP_ROOT/t12-origin" &&
    g checkout -q feature/big-thing 2>/dev/null &&
    g checkout -qb colleague-branch HEAD~1 &&
    commit_file colleague.txt &&
    g checkout -q develop)
  g fetch -q origin
  commit_file work3.txt
  local out=$(dif --exclude-uncommitted --stat 2>&1)
  assert_contains "$out" "work1.txt" "diff includes all of my branch's work"
  assert_contains "$out" "work3.txt" "diff includes latest work"
  assert_not_contains "$out" "colleague-branch" "colleague's fork is not the compare target"
  assert_contains "$out" "develop" "reports develop as compare target"
}

test_partially_pushed_branch() {
  echo "test: branch with unpushed commits still compares against parent, not its own remote"
  setup_clone_with_remote_feature t13
  g checkout -qb my-branch develop
  commit_file first.txt
  g push -q origin my-branch 2>/dev/null
  commit_file second.txt
  local out=$(dif --exclude-uncommitted --stat 2>&1)
  assert_contains "$out" "first.txt" "diff includes pushed commit"
  assert_contains "$out" "second.txt" "diff includes unpushed commit"
  assert_contains "$out" "develop" "reports develop as compare target"
}

# ---------------------------------------------------------------------------
test_shared_branch_pull_rebase() {
  echo "test: shared branch synced via pull --rebase still compares against develop"
  setup_clone_with_remote_feature t14
  g checkout -qb feature/big-thing origin/develop
  commit_file work1.txt
  g push -q origin feature/big-thing 2>/dev/null
  # colleague pushes to the shared branch, and forks their own branch off it
  (cd "$TMP_ROOT/t14-origin" &&
    g checkout -q feature/big-thing 2>/dev/null &&
    commit_file colleague-work.txt &&
    g checkout -qb colleague-fork &&
    commit_file colleague-own.txt &&
    g checkout -q develop)
  # we have local work, then sync with the shared branch the usual way
  # (a real rebase, not a fast-forward)
  commit_file work2.txt
  g pull -q --rebase origin feature/big-thing 2>/dev/null
  g fetch -q origin
  local out=$(dif --exclude-uncommitted --stat 2>&1)
  assert_contains "$out" "work1.txt" "diff includes my earlier work"
  assert_contains "$out" "work2.txt" "diff includes my latest work"
  assert_contains "$out" "colleague-work.txt" "diff includes colleague's shared-branch work (it's the branch's work vs develop)"
  assert_not_contains "$out" "colleague-fork" "colleague's fork is not the compare target"
  assert_contains "$out" "develop" "reports develop as compare target"
}

test_rebased_onto_new_parent() {
  echo "test: branch rebased --onto a different parent compares against the new parent"
  setup_clone_with_remote_feature t15
  # old parent: a PR branch off develop (like a stacked PR that later gets squash-merged)
  g checkout -qb old-pr origin/develop
  commit_file old-pr-work.txt
  g checkout -qb my-branch
  commit_file mine.txt
  # re-target: rebase our commit onto the remote feature branch instead
  g rebase -q --onto origin/feature/x old-pr my-branch 2>/dev/null
  local out=$(dif --exclude-uncommitted --stat 2>&1)
  assert_contains "$out" "mine.txt" "diff includes my file"
  assert_not_contains "$out" "migration.txt" "diff excludes the new parent's own files"
  assert_not_contains "$out" "old-pr-work" "diff excludes the abandoned old parent's files"
  assert_contains "$out" "feature/x" "reports the new parent as compare target"
}

# ---------------------------------------------------------------------------
test_remote_only_parent
test_branch_off_local_develop
test_stacked_branches
test_stale_local_develop
test_explicit_branch
test_not_a_git_repo
test_unrelated_histories
test_uncommitted_and_lockfile
test_dif_on_develop_itself
test_pushed_feature_branch
test_descendant_branch_not_parent
test_develop_behind_origin
test_sibling_forked_from_my_branch
test_partially_pushed_branch
test_shared_branch_pull_rebase
test_rebased_onto_new_parent

echo "\n$PASS passed, $FAIL failed"
((FAIL == 0))

#!/usr/bin/env bash
# fable-process SessionEnd hook: auto-commit harness DOCS so session logs survive.
# Allowlist only — WORKLOG/INSIGHTS/PROGRESS + CLAUDE.md — never the whole
# .fable/ directory (sentinels, reports, scratch stay uncommitted), never source.
# Refuses to act in special git states (merge/rebase/cherry-pick/detached HEAD)
# and skips files the user has partially staged. Fails open on any error.
set -u

command -v git >/dev/null 2>&1 || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
TOP="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$TOP" || exit 0
GITDIR="$(git rev-parse --git-dir 2>/dev/null)" || exit 0

if [ -e "$GITDIR/MERGE_HEAD" ] || [ -e "$GITDIR/REBASE_HEAD" ] \
  || [ -d "$GITDIR/rebase-merge" ] || [ -d "$GITDIR/rebase-apply" ] \
  || [ -e "$GITDIR/CHERRY_PICK_HEAD" ]; then
  exit 0
fi
git symbolic-ref -q HEAD >/dev/null 2>&1 || exit 0

CANDIDATES=".fable/WORKLOG.md .fable/INSIGHTS.md .fable/PROGRESS.md .fable/raw CLAUDE.md"
STAGED=""
for p in $CANDIDATES; do
  [ -e "$p" ] || continue
  git check-ignore -q "$p" 2>/dev/null && continue
  st="$(git status --porcelain -- "$p" 2>/dev/null | cut -c1-2)"
  case "$st" in
    "MM"|"AM"|"RM") continue ;;
  esac
  git add -- "$p" 2>/dev/null || continue
  STAGED="$STAGED $p"
done
[ -n "$STAGED" ] || exit 0

# shellcheck disable=SC2086  # fixed, space-free paths
if git diff --cached --quiet -- $STAGED 2>/dev/null; then
  exit 0
fi
# shellcheck disable=SC2086
git commit -q --no-verify \
  -m "chore(harness): session-end auto-commit of harness docs [fable-process]" \
  -- $STAGED 2>/dev/null || true
exit 0

#!/usr/bin/env bash
# fable-process SessionEnd hook: auto-commit harness docs so session logs survive.
# Scope is deliberately narrow — ONLY .fable/ and CLAUDE.md, never source code.
# Fails open: not a git repo, nothing changed, or any git error → exit 0 silently.
set -u

command -v git >/dev/null 2>&1 || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

PATHS=()
[ -d ".fable" ] && PATHS+=(".fable")
[ -f "CLAUDE.md" ] && PATHS+=("CLAUDE.md")
[ "${#PATHS[@]}" -gt 0 ] || exit 0

git add -- "${PATHS[@]}" 2>/dev/null || exit 0
if git diff --cached --quiet -- "${PATHS[@]}" 2>/dev/null; then
  exit 0
fi
git commit -q -m "chore(harness): session-end auto-commit of harness docs [fable-process]" -- "${PATHS[@]}" 2>/dev/null || true
exit 0

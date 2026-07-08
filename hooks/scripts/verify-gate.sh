#!/bin/bash
# fable-process light verification gate (Stop hook).
# If files were edited this turn and no verification-ish command (test/build/lint/…)
# ran afterwards, block the stop ONCE and ask Claude to verify or justify skipping.
# Fails open: any parsing problem → exit 0 (never breaks the session).
set -u

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Never block twice: stop_hook_active=true means we already blocked this stop.
stop_active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null) || exit 0
[ "$stop_active" = "true" ] && exit 0

transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null) || exit 0
{ [ -n "$transcript" ] && [ -f "$transcript" ]; } || exit 0

# Only look at the recent tail — cheap and covers the current turn.
recent=$(tail -n 800 "$transcript" 2>/dev/null) || exit 0

last_edit=$(printf '%s\n' "$recent" \
  | grep -nE '"name" *: *"(Edit|Write|NotebookEdit)"' \
  | tail -1 | cut -d: -f1)
[ -n "$last_edit" ] || exit 0

last_verify=$(printf '%s\n' "$recent" \
  | grep -nEi '"command" *: *"[^"]*(test|lint|build|tsc|typecheck|pytest|vitest|jest|cargo (check|test)|go (vet|test)|ruff|mypy)' \
  | tail -1 | cut -d: -f1)

if [ -z "$last_verify" ] || [ "$last_edit" -gt "$last_verify" ]; then
  jq -n '{decision: "block", reason: "fable-process verify gate: files were edited this turn but no verification command (test/build/lint) ran afterwards. Run the appropriate verification and report the result before finishing. If verification is impossible or meaningless for this change (docs, config, scratch files), state that in one line and finish."}'
  exit 0
fi

exit 0

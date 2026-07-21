#!/usr/bin/env bash
# fable-relay: fresh-context relay loop (Ralph-style) for long-haul work.
# Each iteration runs a FRESH headless Claude session that completes exactly ONE
# milestone from the progress file, verifies it, checkpoints, and exits. Fresh
# context per milestone beats one long session eroded by compaction.
#
# Usage: fable-relay.sh [progress-file] [done-sentinel]
#   FABLE_RELAY_MAX_ITER   hard iteration cap (default 10 — cost safety)
#   FABLE_RELAY_CLAUDE_ARGS extra args for claude, e.g. "--permission-mode acceptEdits --model opus"
set -u

PROGRESS="${1:-.fable/PROGRESS.md}"
DONE_SENTINEL="${2:-.fable/DONE}"
MAX_ITER="${FABLE_RELAY_MAX_ITER:-10}"
EXTRA_ARGS="${FABLE_RELAY_CLAUDE_ARGS:-}"

if [ ! -f "$PROGRESS" ]; then
  echo "fable-relay: no progress file at $PROGRESS — run the long-haul skill's step 1 first." >&2
  exit 1
fi

i=0
while [ ! -f "$DONE_SENTINEL" ]; do
  i=$((i + 1))
  if [ "$i" -gt "$MAX_ITER" ]; then
    echo "fable-relay: reached max iterations ($MAX_ITER) without $DONE_SENTINEL — stopping for cost safety." >&2
    echo "fable-relay: inspect $PROGRESS, then re-run (raise cap via FABLE_RELAY_MAX_ITER)." >&2
    exit 2
  fi
  echo "=== fable-relay iteration $i/$MAX_ITER ==="
  # shellcheck disable=SC2086  # intentional word splitting for extra args
  claude -p $EXTRA_ARGS "Read $PROGRESS. Complete exactly ONE unchecked milestone using fable-process deep-work discipline: implement it, run its done-conditions, update $PROGRESS marking it done WITH the verification evidence, and commit as a checkpoint. Do not start a second milestone. If every milestone is already done and the final done-conditions pass, write a one-line summary to $DONE_SENTINEL instead." \
    || echo "fable-relay: iteration $i exited nonzero — continuing to next iteration" >&2
done

echo "fable-relay: DONE after $i iteration(s): $(cat "$DONE_SENTINEL")"

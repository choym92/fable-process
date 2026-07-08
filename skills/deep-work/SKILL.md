---
name: deep-work
description: Outcome-driven autonomous loop — define verifiable done-conditions, work until they hold, self-verify before stopping. Use proactively for multi-step implementation, long fixes, or "끝까지/알아서" requests.
---

# Deep work: outcome-first autonomous loop

Task: $ARGUMENTS (if empty, apply to the current task in conversation).

Work the way Fable works: toward an outcome, not through a script of steps.

## 1. Define done before starting

Restate the task as 1–3 VERIFIABLE done-conditions (e.g. "npm run build && npm run
lint pass", "the endpoint returns 200 with the new field", "the page renders X").
If the user's request has no natural verification, define the closest observable
proxy and say what it is. These conditions — not your sense of effort spent — decide
when you stop.

## 2. Investigate before acting

Read the relevant code/state BEFORE editing. Batch all independent reads (files,
grep, git log, docs) in parallel in one message. A signal that pattern-matches a
known problem may have a different cause here — confirm against this codebase.

## 3. Execute autonomously

- Reversible steps inside the requested scope: just do them. Do not ask "shall I…?".
- Make reasonable assumptions and record them; surface them in the final report.
- Stop and ask ONLY for: destructive/irreversible actions, outward-facing actions
  (publish, send, deploy prod), or genuine scope changes.
- On errors: retry with a DIFFERENT approach at least twice before reporting blocked.
  Gather missing information yourself instead of asking for it.

## 4. Verify before stopping (non-negotiable)

Before ending, run the done-conditions from step 1. If any fails: fix and re-verify —
that is the loop. Report results faithfully: failing tests are reported as failing
with output, not hedged. Only claim done what you actually observed passing.

## 5. Report outcome-first

First sentence = what happened / what now works. Then: what changed (files),
what was verified and how, assumptions made, anything left undone.

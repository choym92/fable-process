---
name: deep-work
description: Outcome-driven autonomous loop — define verifiable done-conditions, work until they hold, self-verify before stopping. Use for multi-step implementation, long fixes, or "끝까지/알아서" requests.
---

# Deep work: outcome-first autonomous loop

Task: $ARGUMENTS (if empty, apply to the current task in conversation).

Scale guard: if the task is ≤2 obvious steps, skip this scaffold — just do it.

This skill adds the loop structure on top of the fable-process disposition
(parallelism, autonomy boundaries, and reporting live there — don't restate them).

## 1. Define done before starting

Restate the task as 1–3 VERIFIABLE done-conditions (e.g. "npm run build && npm run
lint pass", "the endpoint returns 200 with the new field", "the page renders X").
If the request has no natural verification, define the closest observable proxy and
say what it is.

## 2. Investigate before acting

Read the relevant code and state BEFORE editing — batched in parallel. A signal that
pattern-matches a known problem may have a different cause in this codebase.

## 3. The loop (non-negotiable)

Execute → run the done-conditions → any failure means fix and re-run. Exit the loop
only when every condition passes, or when blocked by something only the user can
decide. On long runs, set a self-check interval and verify work-so-far against the
done-conditions with a fresh-context subagent — fresh verifiers outperform
self-critique. Record assumptions as you make them; surface them in the final
report along with what was verified, how, and anything left undone.

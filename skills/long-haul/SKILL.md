---
name: long-haul
description: Hold coherence over long autonomous runs — maintain a durable progress record, re-anchor to it after context grows, checkpoint via commits. Use for work spanning many milestones, likely to exceed one context window or session.
---

# Long-haul: keep the thread across a long run

Task: $ARGUMENTS (if empty, apply to the current long-running task).

Scale guard: this is for work that will span many milestones or outlive a single
context window / session. Short or medium tasks → deep-work; this ritual is
overhead on them. The whole point is an EXTERNAL anchor, because context compaction
and long runs erode the in-context thread — most on models below Fable-class.

Lean on the harness; don't reinvent it: TodoWrite tracks in-session steps,
auto-memory carries lessons across sessions. This skill adds only the durable
progress artifact and the re-anchor discipline.

## 1. Write the brief once, up front

Create a durable progress file (default `.fable/PROGRESS.md`; gitignore it if the
repo shouldn't carry it — it still survives locally across sessions). Record:
- **Goal & why** — the outcome and who it's for, in the user's words.
- **Spec / constraints** — decisions already settled (from `align` if it ran).
- **Done-conditions** — the verifiable checks that end the work.
- **Milestone checklist** — the ordered plan, each item independently checkable.

## 2. Work in milestones, checkpoint each

After completing each milestone: verify it (fresh-context subagent against the
spec), update the progress file (mark done WITH the evidence, note what's next),
then commit as a checkpoint so the state is recoverable. One milestone = one
verified, committed step.

## 3. Re-anchor (the coherence mechanism)

Before starting each milestone — and immediately after any context compaction,
summary, or session resume — re-read the progress file and restate the current
objective in one line before acting. Trust the file over your in-context memory
when they disagree; the file is the source of truth. Scope of that trust: the file
is authoritative for DECISIONS and SCOPE; for factual claims about the code,
current observation wins — update the file when reality disagrees with it. Do not
re-derive settled decisions or re-litigate closed branches.

## 4. Don't self-truncate

Do not stop, summarize, or propose a new session on account of context length. The
progress file IS the handoff — if context resets, you re-read it and continue.
Keep working until the done-conditions hold or you hit a genuine blocker (see the
disposition's checkpoint rule).

## 5. Close out

Reconcile the progress file against what actually shipped, run the done-conditions
one final time, and report outcome-first: what now works, what was verified and
how, assumptions made, anything left undone.

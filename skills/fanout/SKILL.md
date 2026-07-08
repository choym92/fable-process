---
name: fanout
description: Decompose → parallel workers → adversarial verify → synthesize. Use for audits, migrations, and multi-module research or sweeps.
---

# Fan-out: decompose → parallel → verify → synthesize

Task: $ARGUMENTS. Materialize the task into a fully self-contained string before
running the workflow — the workflow cannot see this conversation.

Run the Fable-style fan-out process. Model tiering is deliberate: workers are cheap
(Sonnet), judgment is expensive (Opus). Do not flatten this — it is the cost model.

## 0. Scale guard — the default is NO fan-out

This skill auto-invokes, so this gate is the cost control. Fan out ONLY if at
least one of these holds:

- The user made thoroughness the POINT of the request — "audit", "철저하게", a
  standalone "전체 다 봐줘". Casual phrasing that merely contains such words
  ("전체적으로 어때?") does not count.
- You already KNOW, from prior context — not speculation — that ≥3 independent
  modules/directories are involved.

When unsure, run ONE explorer agent first; fan out only if its findings prove
breadth. Otherwise handle the task inline and say so.

Bounds once fanning out: default 3 angles (up to 7 only on an explicit
thoroughness directive); verify only load-bearing findings — those that change
the conclusion or gate a risky action (mechanical results skip verification);
if the projected agent count exceeds ~10, state the plan and rough cost in one
line before launching.

## 1. Decompose

Break the task into 3–7 INDEPENDENT angles. Independence test: each angle must be
answerable/executable without any other angle's result. If two angles depend on each
other, merge them. Write each angle as a fully self-contained prompt — the worker has
no access to this conversation.

## 2. Fan out (parallel, never sequential)

- Preferred: if the Workflow tool is available, author a workflow script — use
  `pipeline()` so verification starts per-angle as soon as that angle's work finishes.
  A ready-made generic script ships with this plugin at `workflows/fanout.js`
  (reference code, not an auto-registered workflow — run it via
  `Workflow({scriptPath: "<plugin-root>/workflows/fanout.js", args: "<task>"})`,
  or copy it to `~/.claude/workflows/` once to invoke by name). Mirror its cost
  bounds if you author your own script: findings capped per worker, Opus
  verification only for load-bearing findings, hard total verify cap (~20).
- Fallback: launch all workers via the Agent tool IN ONE MESSAGE (one Agent call per
  angle, same response block). Use agent `fable-process:explorer` for read-only
  research angles and `fable-process:worker` for angles that change files or collect
  data. Never launch them one-at-a-time across turns.
- For unknown-size discovery (bugs, issues, edge cases): loop-until-dry — keep
  spawning finder rounds until 2 consecutive rounds surface nothing new. A fixed
  round count misses the tail.

## 3. Adversarial verify (the step that makes this Fable-like)

For each finding/result that will influence the final answer or a risky change:
spawn `fable-process:verifier` (Opus) with the single claim and its evidence,
prompted to REFUTE it. Verify in parallel across findings. Drop REFUTED findings;
mark UNCERTAIN ones as such in the report — never silently promote them to fact.
Skip verification only for trivial mechanical results (a file list, a rename).

## 4. Synthesize

- Dedupe semantically across workers (same fact found twice ≠ two facts).
- Rank by confidence: verified > unverified > uncertain.
- Report coverage honestly: list what was NOT covered (angles dropped, dirs skipped,
  workers that returned nothing). Silent truncation reads as full coverage — forbidden.
- Lead the final report with the conclusion, then supporting detail.

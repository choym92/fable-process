---
name: fanout
description: Fable-style multi-agent fan-out — decompose a task into independent angles, run parallel workers, adversarially verify findings, synthesize. Use for audits, broad research, migrations, codebase-wide sweeps, or any "be thorough / comprehensive" request.
---

# Fan-out: decompose → parallel → verify → synthesize

Task: $ARGUMENTS (if empty, apply to the current task in conversation).

Run the Fable-style fan-out process. Model tiering is deliberate: workers are cheap
(Sonnet), judgment is expensive (Opus). Do not flatten this — it is the cost model.

## 1. Decompose

Break the task into 3–7 INDEPENDENT angles. Independence test: each angle must be
answerable/executable without any other angle's result. If two angles depend on each
other, merge them. Write each angle as a fully self-contained prompt — the worker has
no access to this conversation.

## 2. Fan out (parallel, never sequential)

- Preferred: if the Workflow tool is available, author a workflow script — use
  `pipeline()` so verification starts per-angle as soon as that angle's work finishes.
  A ready-made generic script ships with this plugin at `workflows/fanout.js`.
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

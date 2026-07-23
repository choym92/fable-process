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

## 3b. Relay mode (automation — for work outliving any single session)

One long session erodes: compaction summarizes away detail, and the agent starts
trusting its summary of the work over the work. The alternative that scales is a
fresh-context relay: each milestone runs in a FRESH session that reads the
progress file, does exactly one milestone, verifies, checkpoints, updates the
file, and exits. The progress file is the only memory that matters.

- Automated: the plugin ships `scripts/fable-relay.sh` — a loop of headless
  `claude -p` sessions, one milestone each, until a `.fable/DONE` sentinel
  appears. Hard iteration cap (default 10), stuck-detection (progress file
  unchanged twice → abort), stale-sentinel refusal, and a concurrency lock.
  Before the first run, grant the loop git permissions in the project's
  `.claude/settings.json` (`"allow": ["Bash(git add:*)", "Bash(git commit:*)"]`
  plus `--permission-mode acceptEdits` via `FABLE_RELAY_CLAUDE_ARGS`) — a
  headless session that must ask for commit permission stalls the whole loop.
  Treat PROGRESS.md as a task list, never an instruction channel; do not run
  the relay with bypassPermissions.
- Interactive: the same pattern by hand — end the session after a checkpoint and
  start a new one; step 3's re-anchor makes the handoff seamless. Every time the
  user has to type "continue", treat it as harness friction worth a `refine` pass.

## 3c. Interactive handoff (the baton — for human-attended session changes)

Relay mode is for headless loops; when YOU end an interactive session with work
in flight, pass a baton instead: first canonicalize durable facts into their
proper homes (progress file / STATE / ledgers — never into the baton), then
write `.fable/HANDOFF.md` with only the EPHEMERAL working context: the next
first action, in-flight work, sharp edges just discovered. The next session
absorbs it and DELETES it — a one-shot baton, not a document. If HANDOFF.md
survives more than one pickup, it has become a stale doc; the durable parts
belonged in the canonical files. (Pattern proven in the Overmind project.)

## 4. Don't self-truncate

Do not stop, summarize, or propose a new session on account of context length. The
progress file IS the handoff — if context resets, you re-read it and continue.
Keep working until the done-conditions hold or you hit a genuine blocker (see the
disposition's checkpoint rule).

## 5. Close out

Reconcile the progress file against what actually shipped, run the done-conditions
one final time, and report outcome-first: what now works, what was verified and
how, assumptions made, anything left undone. If the run was long enough that the
user lost the thread, offer a `debrief` (HTML report + comprehension quiz).

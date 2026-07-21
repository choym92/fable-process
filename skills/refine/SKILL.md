---
name: refine
description: Harness garbage collection — harvest this session's friction (gate blocks, user corrections, skill over/under-triggering, "continue" nudges), turn each into a durable rule so it never recurs. Run weekly or after any session with repeated friction.
---

# Refine: every mistake becomes a rule

Focus: $ARGUMENTS (if empty, harvest the current session).

The mindset (OpenAI harness-engineering practice): when the agent does something
dumb, the failure is usually legible — a missing convention, a gap in a guard, a
command the gate didn't recognize. Blaming the model and waiting for the next
version wastes the lesson. Every piece of friction is one durable fix away from
never happening again. Every time the user has to say "continue" or repeat a
correction is a harness failure — treat those as the highest-signal events.

## 1. Harvest friction events from the session

Scan the conversation for: verify-gate blocks (true positives AND false
positives), user corrections or repeated instructions, skills that fired when
they shouldn't have (or didn't when they should), "continue"-style nudges, review
feedback that recurred, commands the harness misclassified.

## 2. Classify each event by its durable home

| Friction type | Durable fix lives in |
|---|---|
| Disposition drift (tone, scope, reporting) | output style — one line, only if not already covered |
| Skill over/under-triggering | that skill's description or scale guard |
| Gate false-block / false-pass | `hooks/scripts/verify-gate.sh` pattern list |
| Repo-specific convention miss | that project's CLAUDE.md or `.claude/rules/` — NOT the plugin |
| A check worth automating per-push | suggest a bespoke lint/test whose ERROR MESSAGE includes the remediation ("error messages are prompts"); repo-level — plugin only suggests |
| Same code-level slop class recurring | suggest a test about the source itself (file length caps, dedup of schemas/helpers, dependency edges) |

## 3. Apply, verify, ship

For plugin-level fixes: edit the file in the fable-process repo, run the relevant
verification (`bash -n` + fixture regression for the hook, `claude plugin
validate` for manifests), bump the patch version, commit with the friction event
named in the message, push, and update the installed copy. For project-level
fixes: edit that repo's CLAUDE.md/rules directly.

Rules: one fix per friction event — no speculative rules for problems not
observed (that is how bloat starts, and bloated instructions get ignored). If an
event is covered by an existing rule that was ignored, strengthen or shorten that
rule instead of adding a second one. Report at the end: events found → fixes
applied → events deliberately skipped and why.

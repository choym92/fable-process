---
name: align
description: Reach shared understanding before building — interrogate the request one question at a time, answer from the codebase where possible, block implementation until intent is confirmed. Use before large or ambiguous builds.
---

# Align: confirm the right thing before building it

Request: $ARGUMENTS (if empty, apply to the pending request in conversation).

Scale guard: skip when the request is small, unambiguous, or cheaply reversible —
just build it. This skill is for work that is expensive to redo if built on a
misunderstanding.

## Process

1. Read the relevant code, config, and docs FIRST. Never ask the user something the
   repo can answer — state what you found and confirm your understanding instead.
2. Identify the decision branches that actually change what gets built: scope, data
   shapes, UX, failure behavior, integration points. Ignore branches that don't
   change the outcome.
3. Ask ONE question at a time. With every question, state your recommended answer
   and why — the user should mostly be confirming or redirecting, not designing
   from scratch.
4. Challenge vague or contradictory answers; follow up until each decision is
   concrete enough to implement.
5. Once open branches are resolved (typically 3–7 questions), present a compact
   build spec: what will be built, what explicitly won't, and the done-conditions.
6. Do NOT start implementation until the user confirms shared understanding. Then
   execute with deep-work discipline using the agreed done-conditions.

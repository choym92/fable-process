---
name: scaffold
description: Bootstrap a project's harnessed environment — .fable/ docs (WORKLOG, INSIGHTS), tagged pointer-based logging convention, and per-domain agents (data-engineering, analysis, frontend, backend) that read and maintain it. Use when starting a new project or retrofitting an existing one ("scaffold this project", "하네스 환경 만들어줘").
---

# Scaffold: make the project legible to agents

Domains: $ARGUMENTS (e.g. "data-engineering analysis" — default: ask which of
data-engineering / analysis / frontend / backend apply, one question).

Principle (OpenAI harness practice): docs live in ONE place all processes attach
to; the log points at artifacts instead of restating them — that is what keeps it
from bloating. Never overwrite existing files — merge into them.

## 1. Create the durable docs home: `.fable/`

**`.fable/WORKLOG.md`** — the session log. Prepend this convention header (if it
already exists from a previous scaffold run, do NOT re-add it — only reconcile
differences):

```markdown
# Worklog — tagged pointers, not prose
One entry per work session that changed something significant.
Format: `## [YYYY-MM-DD] #tag #tag — one-line outcome`
Body: POINTERS only — commit SHAs, file paths, INSIGHTS.md entry titles,
PR links. No code, no explanations (the pointer's target has those).
Tags (fixed vocabulary): #data-eng #analysis #frontend #backend #harness
#decision #bug #experiment. Update an entry rather than adding a near-duplicate.
```

**`.fable/INSIGHTS.md`** — analysis findings ledger (format from the `insights`
skill: claim + reproducible evidence + affected decision + status).

**`.fable/raw/`** — the lossless layer. Subagent reports (deep-research dumps,
UX/community investigations) are load-bearing but huge and die in session
scratch. Save them here verbatim, named `YYYY-MM-DD_topic.md`. This directory is
NEVER auto-loaded — it is a grep-only vault, reached by one hop from a curated
note's pointer. Add an INDEX.md that lists each file with a one-line "what it
is", and states "do not bulk-load; grep for keywords or follow a note's pointer".

## 1b. The three-layer memory contract (dieting and losslessness are layers, not a trade)

| Layer | Home | Rule | Lossy? |
|---|---|---|---|
| 1 — entry point | STATE/CLAUDE.md/INDEX | budgeted (auto-loaded every session — keep small) | relocation only |
| 2 — curated notes | INSIGHTS.md, WORKLOG.md | compress + "which decision it changed" + pointer to raw | compressed, raw one hop away |
| 3 — raw originals | `.fable/raw/` | subagent reports verbatim; grep-only, never auto-loaded | lossless |

The point of the raw layer is that "does the summary really reflect the source?"
is always one hop away. The point of NOT auto-loading it is our own research
finding: bulk-loading stale originals degrades accuracy and makes outdated text
read as truth (a hallucination path). Curated layer first; raw is for
verification and re-mining. Rule going forward: any investigation that changed a
decision is saved as a PAIR — curated note (layer 2) + raw report (layer 3).

## 2. Generate domain agents: `.claude/agents/<domain>.md`

One per requested domain, `model: sonnet`, with this duty structure:

- FIRST ACTION every task: read `.fable/WORKLOG.md` tail, `.fable/INSIGHTS.md`,
  and the project CLAUDE.md — the harness docs outrank in-context memory.
- Do the domain work with fable-process discipline (minimal diff, verify, honest
  report).
- LAST ACTION: if the work was significant, add/update a WORKLOG entry (tagged
  pointers only) and any INSIGHTS entries; fix harness docs found stale while
  working — stale docs are bugs.

Give each agent a short domain-specific "what good looks like" section
(data-engineering: idempotent pipelines, schema documented; analysis: numbers
with reproduction commands; frontend/backend: project conventions) — seed it
thin; `refine` grows it from observed friction, not speculation.

## 3. Wire the project CLAUDE.md

Add (or merge into) a `## Harnessed environment` section: where the docs live,
the worklog convention, the domain agents and when to delegate to them, and the
rule that every agent reads `.fable/` first. Keep it under ~30 lines — bloated
instructions get ignored.

## 4. Close the loop

Tell the user: the fable-process SessionEnd hook auto-commits `.fable/` and
CLAUDE.md changes when a session ends (harness docs only — never source code),
so the log survives even a forgotten commit. Writing GOOD entries is the model's
job during the session; the hook is just the safety net.

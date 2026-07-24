---
name: help
description: Quick reference for fable-process — what each skill does, when it fires on its own, and the keywords worth typing. Use when the user asks what this plugin can do, which skill to use, or "뭘 할 수 있어".
disable-model-invocation: false
---

# fable-process quick reference

Print this compactly, in the user's language. Most of it is automatic — the point
of this card is that the user knows what already happens and what they can type.

## Automatic (no command needed)

| When | What happens |
|---|---|
| Session starts (scaffolded project) | Reads `.fable/INDEX.md` → orients from the project's own state docs |
| Big ambiguous request | `align` — one question at a time until the spec is agreed |
| Multi-step implementation | `deep-work` — done-conditions, loop until they hold |
| Multi-module sweep / audit | `fanout` — parallel Sonnet workers + Opus adversarial verify |
| Design fork | `judge-panel` — independent candidates, Opus judges, synthesis |
| Work spanning sessions | `long-haul` — progress file, re-anchor, commit checkpoints |
| Analysis finding | `insights` — curated ledger; bulky reports go to `raw/` |
| Code edited, nothing verified | Stop gate blocks once and asks for verification |
| Session ends | Harness docs auto-committed (never source) |

## Worth typing

- `/fable-process:scaffold <domains>` — set up (or bridge) a project's harness
- `/fable-process:refine` — turn this week's friction into durable rules
- `/fable-process:debrief` — HTML report + quiz on what just changed
- `/fable-process:align`, `:deep-work`, `:fanout`, `:judge-panel`, `:long-haul`,
  `:insights` — force any of the above explicitly
- `ultrathink` in a prompt — one turn of deeper reasoning
- `ultracode` in a prompt — orchestrated multi-agent workflows
- `/output-style default` — turn the disposition off; `/output-style fable-process` back on

## Dials

Effort: `/effort` menu (xhigh persisted in settings; `max` session-only, Opus).
Cost: workers run on Sonnet, judgment on Opus — fan-out caps Opus verification.

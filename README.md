# fable-process

Fable 5-style work process for Claude Code, on any model (built for Opus after
Fable 5 access ends 2026-07-12). Packages the process — parallel fan-out,
adversarial verification, outcome-driven autonomy, self-verification before
stopping — as a portable personal plugin: install it on any machine, use it in
any project.

Based on verified research (2026-07-08): the Fable "process" is almost entirely
Claude Code **harness** machinery (workflows/ultracode, subagents, skills, hooks,
output styles, memory — all model-agnostic), while the model-specific residual is
*disposition* (unprompted parallelism, investigation, self-verification). This
plugin re-imposes that disposition on Opus via an output style, skills, tiered
agents, and a light Stop-hook verification gate.

## What's inside

| Piece | What it does | Model |
|---|---|---|
| `skills/fanout` | decompose → parallel workers → adversarial verify → synthesize | tiered |
| `skills/deep-work` | outcome-driven autonomous loop, verify-before-stop | session |
| `skills/judge-panel` | N independent candidates → Opus judges → synthesis | tiered |
| `skills/setup` | one-time install of the output style + settings check | — |
| `agents/explorer` | read-only parallel recon worker | Sonnet |
| `agents/worker` | scoped implementation/collection worker | Sonnet |
| `agents/verifier` | adversarial refuter (CONFIRMED/REFUTED/UNCERTAIN) | Opus xhigh |
| `agents/judge` | candidate scorer with failure-mode hunting | Opus xhigh |
| `workflows/fanout.js` | generic parameterized fan-out workflow script | tiered |
| `hooks/verify-gate.sh` | Stop hook: edited-but-unverified → one nudge to verify | — |
| `output-styles/fable-process.md` | the disposition, injected into the system prompt | — |

Cost model: workers are Sonnet, judgment (verify/judge/decompose) is Opus. Keep it.

## Install (any machine)

```
# from GitHub (after pushing this repo):
/plugin marketplace add <github-user>/fable-process
/plugin install fable-process@fable-process

# or test locally without installing:
claude --plugin-dir /path/to/fable-process
```

Then once per machine:

```
/fable-process:setup        # installs the output style, checks settings
/output-style fable-process # activate the disposition
```

Recommended `~/.claude/settings.json` baseline:

```json
{
  "effortLevel": "xhigh",
  "outputStyle": "fable-process"
}
```

## Use

- Big/thorough task → `/fable-process:fanout <task>`, or just say `ultracode` in the
  prompt (harness keyword — orchestrated workflows work on Opus).
- Multi-step implementation → `/fable-process:deep-work <task>`.
- Design fork → `/fable-process:judge-panel <problem>`.
- One-off deeper reasoning → include `ultrathink` in the prompt (harness keyword,
  model-agnostic). `/effort max` for a whole session (Opus only, session-scoped).
- Generic workflow: `Workflow({scriptPath: ".../workflows/fanout.js", args: "<task>"})`
  — or let the fanout skill author a task-specific script.

## Update

```
/plugin update fable-process   # pull latest from the marketplace repo
/fable-process:setup           # re-sync the output style (shows a diff if changed)
```

Restart the session after updating. Skills/agents/hooks apply automatically; only
the output style needs the setup re-run.

## Auto-invocation & cost control

Skills are fully auto-invocable by design (Fable-like proactivity): Claude routes
big decomposable work to `fanout`, multi-step implementation to `deep-work`, and
design forks to `judge-panel` on its own. The counterweight is each skill's scale
guard — small tasks stay inline, fan-out defaults to 3 angles (7 only on explicit
thoroughness signals), only load-bearing findings get Opus verification, and plans
above ~10 agents are announced with cost before launch.

## Requirements & notes

- Claude Code >= 2.1.154 (dynamic workflows); >= 2.1.198 recommended (background
  subagents by default). Workflows may need enabling in `/config` on some plans.
- The Stop-hook gate fails open (any parse issue → no block) and blocks at most
  once per stop (`stop_hook_active` check).
- Output styles can't ship inside plugins — hence the `setup` skill copies it to
  `~/.claude/output-styles/`. Re-run `setup` after updating the plugin if the
  style changed.
- The output style responds in Korean by default (personal preference) — edit
  `output-styles/fable-process.md` to change.

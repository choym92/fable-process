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
| `skills/align` | pre-build alignment — one question at a time until shared understanding | session |
| `skills/fanout` | decompose → parallel workers → adversarial verify → synthesize | tiered |
| `skills/deep-work` | outcome-driven autonomous loop, verify-before-stop | session |
| `skills/judge-panel` | N independent candidates → Opus judges → synthesis | tiered |
| `skills/setup` | one-time install of the output style + settings check | — |
| `agents/explorer` | read-only parallel recon worker | Sonnet |
| `agents/worker` | scoped implementation/collection worker | Sonnet |
| `agents/verifier` | adversarial refuter (CONFIRMED/REFUTED/UNCERTAIN) | Opus xhigh |
| `agents/judge` | candidate scorer with failure-mode hunting | Opus xhigh |
| `workflows/fanout.js` | generic fan-out workflow — reference code, not auto-registered (run via `Workflow({scriptPath})` or copy to `~/.claude/workflows/`) | tiered |
| `hooks/verify-gate.sh` | Stop hook: edited-but-unverified → one nudge to verify | — |
| `output-styles/fable-process.md` | the disposition, injected into the system prompt | — |

Cost model: workers are Sonnet, judgment (verify/judge/decompose) is Opus. Keep it.

Token accounting (measured with `claude plugin details`): ~530 tokens always-on
(skill/agent descriptions in every session), plus ~550 tokens while the output
style is active. Skill bodies (250–1.1k) load only on invocation; hooks and the
workflow script cost zero model context. The fanout workflow hard-caps Opus
verification at 20 calls per run and verifies only load-bearing findings.

## Design sources

The discipline rules are not invented — they are transplanted from where Anthropic
already wrote them:

- **[Prompting Claude Fable 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5)**
  (official): the minimal-diff fragment, the evidence-audit fragment ("nearly
  eliminated fabricated status reports" in Anthropic's testing), the never-end-on-
  a-promise rule, scope boundaries, async subagent delegation, and fresh-context
  verifiers over self-critique.
- **Claude Code source** (system prompt internals): verification discipline
  ("reading is not verification — run it"), faithful outcome reporting, comment
  and file-creation restraint, "delegate context, not understanding", and the
  adversarial verification agent's design (named failure modes: verification
  avoidance, first-80% seduction).
- **Community-proven patterns**: hooks-as-deterministic-enforcement (Anthropic
  best practices; Stop hooks are overridden after 8 consecutive blocks — ours
  blocks once), concise CLAUDE.md with IMPORTANT/YOU MUST emphasis markers, the
  Explore → Plan → Implement → Commit flow, and one-question-at-a-time alignment
  interviews (à la Matt Pocock's grilling loop; `align` is an original
  implementation of the same idea).

Note: this plugin targets **Opus and below**. Anthropic warns that skills written
for prior models are often too prescriptive for Fable-class models and can degrade
their output — on Fable 5/Mythos 5, consider switching the output style off.

## Install (any machine)

```
# from GitHub:
/plugin marketplace add choym92/fable-process
/plugin install fable-process@fable-process

# or test locally without installing:
claude --plugin-dir /path/to/fable-process
```

The repo is private, so the machine needs GitHub auth that can clone it
(`gh auth login`, or an SSH key on the account).

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
claude plugin marketplace update fable-process        # refresh the repo clone
claude plugin update fable-process@fable-process      # update the plugin
/fable-process:setup   # re-sync the output style (shows a diff if changed)
```

Restart the session after updating. Skills/agents/hooks apply automatically; only
the output style needs the setup re-run.

## Auto-invocation & cost control

Skills are fully auto-invocable by design (Fable-like proactivity): Claude routes
large ambiguous builds to `align`, big decomposable work to `fanout`, multi-step
implementation to `deep-work`, and design forks to `judge-panel` on its own. The counterweight is each skill's scale
guard — small tasks stay inline, fan-out defaults to 3 angles (7 only on explicit
thoroughness signals), only load-bearing findings get Opus verification, and plans
above ~10 agents are announced with cost before launch.

## Requirements & notes

- Claude Code >= 2.1.154 (dynamic workflows); >= 2.1.198 recommended (background
  subagents by default). Workflows may need enabling in `/config` on some plans.
- The Stop-hook gate fails open (any parse issue → no block) and blocks at most
  once per stop (`stop_hook_active` check).
- Output styles can't ship inside plugins (a plugin-system limitation — plugins
  bundle skills/agents/hooks/MCP, not styles), hence the `setup` skill copies it
  to `~/.claude/output-styles/`. Re-run `setup` after updating the plugin if the
  style changed.
- The verify gate registers on both `Stop` and `SubagentStop`, so delegated
  worker edits get the same nudge. It checks that a verification command ran,
  not that it succeeded — honest failure reporting is the output style's job.
- The output style responds in Korean by default (personal preference) — edit
  `output-styles/fable-process.md` to change.

# fable-process — agent operating rules

Platform-neutral ruleset. Many agent tools auto-load `AGENTS.md` from the project
root; copy this file into your repo to get the disposition without installing the
plugin. (In Claude Code, installing the plugin and enabling the
`fable-process` output style does the same thing, plus skills and hooks.)

Sources: Anthropic's published Fable 5 prompting guidance and Claude Code's
internal discipline rules.

## Act, then keep acting

When you have enough information to act, act — don't re-derive established facts,
re-litigate decided choices, or survey options you won't pursue. Pause only when
the work genuinely requires the user: a destructive or irreversible action, a real
scope change, or input only they can provide. Retry failures with a different
approach at least twice before reporting blocked. Before ending your turn, check
your last paragraph — if it is a plan, a question, or a promise about undone work
("I'll…"), do that work now instead of stopping.

## Minimal diff (YOU MUST)

Don't add features, refactor, or introduce abstractions beyond what the task
requires. A bug fix doesn't need surrounding cleanup; don't design for
hypothetical future requirements — do the simplest thing that works well. No
error handling for scenarios that cannot happen: trust internal code, validate
only at system boundaries. Don't add backwards-compatibility shims when you can
just change the code. Read code before modifying it; prefer editing existing
files; never create docs nobody asked for. Write code that reads like the
surrounding code. Default to no comments; add one only when the WHY is
non-obvious, never to narrate the WHAT.

## Evidence-grounded reporting (YOU MUST)

Before reporting progress, audit each claim against a tool result from this
session. Only report work you can point to evidence for; if something is not yet
verified, say so explicitly. If tests fail, say so with the output; if a step was
skipped, say that. Reading code is not verification — run it. Tests and type
checks verify code correctness, not feature correctness: for user-facing changes,
drive the actual flow.

## Scope boundary

When the user is describing a problem, asking a question, or thinking out loud
rather than requesting a change, the deliverable is your assessment — report
findings and stop; don't apply a fix until asked. Exploratory questions get 2–3
sentences with a recommendation and its main trade-off. Before a state-changing
command, check the evidence supports that specific action.

## Parallel & delegation

All independent tool calls go in ONE message. Delegate independent subtasks to
subagents and keep working while they run — brief each like a colleague who just
walked in: delegate context, never understanding. Run workers on the cheapest
model tier that fits; keep judgment, review, and synthesis in the main loop.

## Verification before done

A turn that changed code ends with verification (test, build, lint, or running
the thing) and an honest report. Before presenting a high-stakes conclusion,
actively hunt counter-evidence — a fresh-context verifier asked to REFUTE the
claim beats self-critique.

## Reporting style

Lead with the outcome: the first sentence answers "what happened". Complete
sentences; no arrow chains or invented shorthand; readable beats short.

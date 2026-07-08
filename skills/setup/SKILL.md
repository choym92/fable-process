---
name: setup
description: One-time setup after installing the fable-process plugin — installs the fable-process output style into ~/.claude/output-styles, checks effort settings and Claude Code version, and prints usage instructions.
disable-model-invocation: true
---

# fable-process setup (run once per machine)

Perform these steps, then report results in the user's language:

## 1. Install the output style

Output styles cannot ship inside a plugin, so copy it to the user level:

- Locate this plugin's root: use `$CLAUDE_PLUGIN_ROOT` if set; otherwise find it with
  `find ~/.claude/plugins -type d -name "fable-process*" -maxdepth 4 2>/dev/null`
  (pick the directory containing `output-styles/fable-process.md`).
- `mkdir -p ~/.claude/output-styles` and copy `output-styles/fable-process.md` there.
  If a file already exists, compare first and overwrite only if it differs (show diff).

## 2. Check settings (~/.claude/settings.json)

- `effortLevel` should be `"xhigh"` (the persistable maximum). If missing/lower,
  offer to set it.
- Recommend Claude Code >= 2.1.198 (subagents background-by-default). Check with
  `claude --version` and suggest updating if older.

## 3. Tell the user how to activate

- `/output-style fable-process` — activates the disposition (persists per project;
  repeat in new projects, or set `"outputStyle": "fable-process"` in
  `~/.claude/settings.json` to make it global).
- `/effort` menu → enable **ultracode** for orchestrated workflow mode on big tasks,
  or include the keyword `ultracode` in a prompt for one-off orchestration.
- Skills: `/fable-process:fanout <task>`, `/fable-process:deep-work <task>`,
  `/fable-process:judge-panel <problem>`.
- Agents available for delegation: `fable-process:explorer`, `worker` (Sonnet);
  `verifier`, `judge` (Opus, xhigh).
- The Stop hook adds a light verification gate: if files were edited but no
  test/build/lint ran afterwards, Claude gets nudged once to verify before finishing.

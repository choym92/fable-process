---
name: setup
description: One-time setup (re-run after plugin updates) — installs the fable-process output style, checks effort settings and Claude Code version, prints usage.
disable-model-invocation: true
---

# fable-process setup (run once per machine, and after every plugin update)

Perform these steps, then report results in the user's language. Start by reading
the installed plugin's `.claude-plugin/plugin.json` and reporting its version.

## 1. Install the output style

Output styles cannot ship inside a plugin, so copy it to the user level:

- Locate the style file: use `$CLAUDE_PLUGIN_ROOT/output-styles/fable-process.md`
  if that env var is set; otherwise
  `find ~/.claude/plugins -type f -name "fable-process.md" -path "*output-styles*" 2>/dev/null`
  and pick the newest match (installed copies live under a versioned path like
  `plugins/cache/fable-process/fable-process/<version>/`).
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

#!/usr/bin/env bash
# fable-process SessionStart hook: point the agent at the harness table-of-contents.
# Injects a SMALL pointer (not the content) so every session starts knowing where
# the durable docs live. Fires ONLY in scaffolded projects (.fable/INDEX.md
# exists) — silent everywhere else. Static conventions stay in CLAUDE.md; this
# hook only surfaces the DYNAMIC entry point (INDEX + recent WORKLOG state).
set -u

cat >/dev/null 2>&1  # drain stdin (SessionStart payload); we don't need it

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT="$PWD"
INDEX="$ROOT/.fable/INDEX.md"
[ -f "$INDEX" ] || exit 0

command -v jq >/dev/null 2>&1 || exit 0

read -r -d '' MSG <<'EOF'
This project uses a fable-process harness. Before substantial work, read `.fable/INDEX.md` — the table of contents — and follow its pointers to the current state and curated notes it names (the layout is project-specific; INDEX.md is authoritative). Do not bulk-load any raw/verbatim-report layer it points to; grep it or follow a note's pointer instead. Keep the durable docs current as you work; the SessionEnd hook commits the harness docs. Curated layers first; raw is for verification and re-mining.
EOF

jq -n --arg ctx "$MSG" '{additionalContext: $ctx}' 2>/dev/null || exit 0
exit 0

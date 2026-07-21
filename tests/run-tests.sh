#!/usr/bin/env bash
# fable-process test suite. Run after ANY edit to hooks/ or scripts/ (refine
# does this), and before every release. Pure bash+jq — CI-safe.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GATE="$ROOT/hooks/scripts/verify-gate.sh"
SLOG="$ROOT/hooks/scripts/session-log-commit.sh"
RELAY="$ROOT/scripts/fable-relay.sh"

pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok:   $1"; }
bad() { fail=$((fail+1)); echo "  FAIL: $1 (expected=$2 actual=$3)"; }
expect() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "$2" "$3"; fi; }

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

U='{"type":"user","message":{"content":"do it"}}'
E='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"/x/a.ts"}}]}}'
B_TEST='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"npm test"}}]}}'
B_TAIL='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"tail -f latest.log"}}]}}'
B_ENVQ='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"NODE_ENV=\"production\" npm run build"}}]}}'
B_SED='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"sed -i '"'"'s/a/b/'"'"' src/app.ts"}}]}}'
B_JQ='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"jq empty settings.json"}}]}}'
B_VAL='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"claude plugin validate ."}}]}}'

gate() { local f="$TMP/$1"; shift; printf '%s\n' "$@" > "$f"
  local out; out=$(printf '{"transcript_path":"%s","stop_hook_active":false}' "$f" | "$GATE")
  [ -n "$out" ] && echo block || echo pass; }

echo "verify-gate.sh:"
expect "edit + nothing → block"              block "$(gate a "$U" "$E")"
expect "edit + npm test → pass"              pass  "$(gate b "$U" "$E" "$B_TEST")"
expect "prev-turn edit, Q&A now → pass"      pass  "$(gate c "$U" "$E" "$B_TEST" "$U")"
expect "edit + tail latest.log → block"      block "$(gate d "$U" "$E" "$B_TAIL")"
expect "edit + quoted-env build → pass"      pass  "$(gate e "$U" "$E" "$B_ENVQ")"
expect "sed -i via bash → block"             block "$(gate f "$U" "$B_SED")"
expect "edit + jq empty → pass"              pass  "$(gate g "$U" "$E" "$B_JQ")"
expect "edit + plugin validate → pass"       pass  "$(gate h "$U" "$E" "$B_VAL")"
f="$TMP/i"; printf '%s\n' "$U" "$E" > "$f"
out=$(printf '{"transcript_path":"%s","stop_hook_active":true}' "$f" | "$GATE")
expect "stop_hook_active → no double block"  pass  "$([ -n "$out" ] && echo block || echo pass)"

echo "session-log-commit.sh:"
R="$TMP/repo"; mkdir -p "$R"; git -C "$R" init -q; git -C "$R" commit -q --allow-empty -m init
commits() { git -C "$R" log --oneline | wc -l | tr -d ' '; }
(cd "$R" && bash "$SLOG")
expect "no harness docs → no commit"         1 "$(commits)"
mkdir -p "$R/.fable"; echo "## entry" > "$R/.fable/WORKLOG.md"
(cd "$R" && bash "$SLOG")
expect "new worklog → auto-commit"           2 "$(commits)"
(cd "$R" && bash "$SLOG")
expect "no change → idempotent"              2 "$(commits)"
echo "code" > "$R/app.py"
(cd "$R" && bash "$SLOG")
expect "source change → untouched"           2 "$(commits)"
expect "source stays uncommitted"            1 "$(git -C "$R" status --porcelain | grep -c app.py)"
(cd "$TMP" && bash "$SLOG"); expect "non-git dir → exit 0" 0 "$?"

echo "fable-relay.sh (stubbed claude):"
RL="$TMP/relay"; mkdir -p "$RL/bin" "$RL/.fable"; echo "- [ ] m1" > "$RL/.fable/PROGRESS.md"
printf '#!/bin/bash\necho x >> stub.log\n[ "$(wc -l < stub.log | tr -d " ")" -ge 3 ] && echo done > .fable/DONE\nexit 0\n' > "$RL/bin/claude"
chmod +x "$RL/bin/claude"
(cd "$RL" && PATH="$RL/bin:$PATH" FABLE_RELAY_MAX_ITER=5 bash "$RELAY" >/dev/null 2>&1)
expect "sentinel appears → exit 0"           0 "$?"
rm -f "$RL/.fable/DONE" "$RL/stub.log"; printf '#!/bin/bash\ntrue\n' > "$RL/bin/claude"; chmod +x "$RL/bin/claude"
(cd "$RL" && PATH="$RL/bin:$PATH" FABLE_RELAY_MAX_ITER=2 bash "$RELAY" >/dev/null 2>&1)
expect "no sentinel → cap exit 2"            2 "$?"

echo ""
echo "passed $pass / $((pass + fail))"
[ "$fail" -eq 0 ] || exit 1

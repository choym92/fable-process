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
echo "stale" > "$R/.fable/DONE"; echo "<html>" > "$R/.fable/report.html"; echo "more" >> "$R/.fable/WORKLOG.md"
(cd "$R" && bash "$SLOG")
expect "junk in .fable NOT committed"        0 "$(git -C "$R" ls-files | grep -c -e DONE -e report.html)"
expect "worklog update still committed"      3 "$(commits)"
mkdir -p "$R/sub"; echo "even more" >> "$R/.fable/WORKLOG.md"
(cd "$R/sub" && bash "$SLOG")
expect "subdir cwd → still commits (H1)"     4 "$(commits)"
R2="$TMP/repo2"; mkdir -p "$R2/.fable"; git -C "$R2" init -q; git -C "$R2" commit -q --allow-empty -m init
printf '.fable/\n' > "$R2/.gitignore"; echo "log" > "$R2/.fable/WORKLOG.md"; echo "# proj" > "$R2/CLAUDE.md"
(cd "$R2" && bash "$SLOG")
expect "ignored .fable: CLAUDE.md commits (C2)" 1 "$(git -C "$R2" ls-files | grep -c CLAUDE.md)"
expect "ignored .fable: nothing left staged"    0 "$(git -C "$R2" diff --cached --name-only | wc -l | tr -d ' ')"
R3="$TMP/repo3"; mkdir -p "$R3"; git -C "$R3" init -q; git -C "$R3" commit -q --allow-empty -m init
mkdir -p "$R3/.git-fake"; touch "$R3/.git/MERGE_HEAD"; mkdir -p "$R3/.fable"; echo "x" > "$R3/.fable/WORKLOG.md"
(cd "$R3" && bash "$SLOG")
expect "mid-merge → refuses to act (M1)"     0 "$(git -C "$R3" diff --cached --name-only | wc -l | tr -d ' ')"
(cd "$TMP" && bash "$SLOG"); expect "non-git dir → exit 0" 0 "$?"

echo "fable-relay.sh (stubbed claude):"
RL="$TMP/relay"; mkdir -p "$RL/bin" "$RL/.fable"; echo "- [ ] m1" > "$RL/.fable/PROGRESS.md"
mkstub() { printf '%s\n' '#!/bin/bash' "$1" > "$RL/bin/claude"; chmod +x "$RL/bin/claude"; }
run_relay() { (cd "$RL" && PATH="$RL/bin:$PATH" FABLE_RELAY_MAX_ITER="$1" bash "$RELAY" >/dev/null 2>&1); echo "$?"; }
mkstub 'echo x >> .fable/PROGRESS.md; echo x >> stub.log; [ "$(wc -l < stub.log | tr -d " ")" -ge 3 ] && echo done > .fable/DONE; exit 0'
expect "sentinel path → exit 0"              0 "$(run_relay 5)"
expect "lock released after run"             0 "$( [ -d "$RL/.fable/relay.lock" ] && echo 1 || echo 0 )"
expect "stale sentinel → refuse, exit 1 (C1)" 1 "$(run_relay 5)"
rm -f "$RL/.fable/DONE" "$RL/stub.log"
mkdir "$RL/.fable/relay.lock"
expect "lock held → exit 1 (H3)"             1 "$(run_relay 5)"
rmdir "$RL/.fable/relay.lock"
mkstub 'exit 0'
expect "no progress change ×2 → stuck exit 3 (H4)" 3 "$(run_relay 9)"
mkstub 'exit 1'
expect "consecutive failures → exit 4 (M6)"  4 "$(run_relay 9)"
mkstub 'echo x >> .fable/PROGRESS.md; exit 0'
expect "progressing but no DONE → cap exit 2" 2 "$(run_relay 2)"

echo ""
echo "passed $pass / $((pass + fail))"
[ "$fail" -eq 0 ] || exit 1

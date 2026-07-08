#!/usr/bin/env bash
# fable-process light verification gate (Stop + SubagentStop hook).
# Blocks a stop at most once when the CURRENT TURN (events after the last genuine
# user message) edited files and no verification-shaped command ran afterwards.
# Checks that a verify command RAN, not that it succeeded — honest reporting of
# failures is the output style's job.
# Fails open: jq missing, unreadable transcript, or any parse problem → exit 0.
set -u

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

stop_active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null) || exit 0
[ "$stop_active" = "true" ] && exit 0

transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null) || exit 0
{ [ -n "$transcript" ] && [ -f "$transcript" ]; } || exit 0

verdict=$(tail -n 2000 "$transcript" 2>/dev/null | jq -Rrs '
  def verifyish:
    test("(^|[\\s;&|(])(pytest|vitest|jest|tsc|mypy|ruff|eslint|phpunit|rspec)\\b")
    or test("\\b(npm|pnpm|yarn|bun)(\\s+run)?\\s+(test|build|lint|typecheck|check)\\b")
    or test("\\b(make|cargo|go|mvn|gradle)\\s+(test|build|check|vet|verify)\\b")
    or test("\\bpython3?\\s+-m\\s+(pytest|unittest|py_compile)\\b")
    or test("\\bvalidate\\b")
    or test("\\bnode\\s+--check\\b")
    or test("\\bbash\\s+-n\\b")
    or test("\\bjq\\s+(empty|-e\\b|\\.\\s)")
    or test("\\b(json\\.tool|yamllint)\\b")
    or test("\\byq\\s+");
  def editish_cmd:
    test("\\bsed\\s+-i") or test("\\bgit\\s+apply\\b")
    or test("(^|[\\s;&|])patch\\s") or test("\\btee\\s");
  [ split("\n")[] | fromjson? // empty
    | if .type == "user"
        and ((.message.content | type) == "string"
             or ((.message.content | type) == "array"
                 and ([.message.content[]? | select(.type == "tool_result")] | length) == 0))
      then "user"
      elif .type == "assistant"
      then (.message.content[]? | select(.type == "tool_use")
            | if .name == "Edit" or .name == "Write" or .name == "NotebookEdit"
              then "edit"
              elif .name == "Bash"
              then ((.input.command // "")
                    | if editish_cmd then "edit"
                      elif verifyish then "verify"
                      else "other" end)
              else empty end)
      else empty
      end
  ]
  | (rindex(["user"])) as $u
  | (if $u == null then . else .[($u + 1):] end)
  | (rindex(["edit"])) as $e
  | (rindex(["verify"])) as $v
  | if $e == null then "pass"
    elif $v == null or $v < $e then "block"
    else "pass"
    end
' 2>/dev/null) || exit 0

if [ "$verdict" = "block" ]; then
  jq -n '{decision: "block", reason: "fable-process verify gate: this turn edited files but no verification command (test/build/lint) ran afterwards. Run the appropriate verification and report the result. If a subagent already verified this work, restate its result instead of re-running. If verification is meaningless for this change (docs, config, scratch files), say so in one line and finish."}'
fi
exit 0

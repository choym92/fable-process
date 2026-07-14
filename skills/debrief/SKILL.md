---
name: debrief
description: Close the comprehension gap after substantial work — generate an HTML report of what changed (context, intuition, work performed) ending with a quiz the user must pass. Use when the user says "debrief", "뭘 한거야", "quiz me", or has visibly lost track after a large autonomous run.
---

# Debrief: the user must understand what happened

Scope: $ARGUMENTS (if empty, the most recent substantial change set).

Why this exists: AI output speed exceeds human comprehension speed; unreviewed
changes accumulate as cognitive debt. The quiz is deliberate friction — the
speed-control mechanism for the loop. (Pattern: Thariq Shihipar, Claude Code team.)

Scale guard: only for substantial work — multi-file changes, a long autonomous
run, or an explicit request. A one-file fix needs a sentence, not a report.

## Build the report (one self-contained HTML file)

Write to `.fable/debrief-<topic>.html` (or the user's preferred location), inline
CSS, no external assets. Sections in order:

1. **Context** — what problem this work solved and why it was undertaken; the
   before-state a returning reader needs.
2. **Intuition** — the mental model: WHY this approach, what the key design
   decisions were, what was rejected and why. This is the section that prevents
   "it works but I don't know how".
3. **Work performed** — the changes, walked through file by file with short code
   excerpts; each excerpt gets a one-line plain-language summary above it.
4. **Verification** — what was run to prove it works, with actual results.
5. **Quiz (must pass)** — 3–7 questions targeting the load-bearing concepts: the
   WHY of decisions and the failure modes, not trivia. Multiple choice or short
   answer; hide answers behind `<details>` so the user attempts first. Include
   one question about what would BREAK if a key piece were changed.

## Rules

- Write for a reader who saw none of the work: no session shorthand, every
  identifier introduced in plain language on first mention.
- Ground every claim in the actual diff/tool results — the report is evidence,
  not recollection.
- After delivering, tell the user the file path and offer to go through the quiz
  interactively; on wrong answers, explain and re-quiz that concept differently.
- Flashcard variant on request: same content as Q/A pairs (front/back) for
  spaced repetition instead of a one-shot quiz.

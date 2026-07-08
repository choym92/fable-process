---
name: judge-panel
description: Explore a wide solution space the Fable way — generate N independent candidate approaches from different angles, score them with parallel Opus judges, synthesize the winner grafting the best ideas from runners-up. Use for design decisions, architecture choices, refactoring strategies, or anything with more than one defensible answer.
---

# Judge panel: diverge → judge → synthesize

Problem: $ARGUMENTS (if empty, apply to the decision under discussion).

Beats one-attempt-iterated whenever the solution space is wide. Skip it when there
is one conventional answer — this pattern is for genuine forks.

## 1. Diverge (parallel candidates)

Generate 3 candidate approaches via parallel `fable-process:worker` agents launched
in ONE message — each with a DIFFERENT forced perspective so they can't converge:
e.g. simplest-thing-that-works / robustness-and-edge-cases-first / best-long-term-
architecture. Each worker prompt is self-contained: the problem, the constraints,
its assigned lens, and "produce a concrete proposal with its main trade-off stated".
Do not let workers see each other's output.

## 2. Judge (parallel scoring)

Send all candidates to `fable-process:judge` (Opus). For high-stakes decisions, use
2–3 judge calls with different emphasis (correctness / maintenance cost / risk) and
require majority agreement. Judges must name each candidate's failure mode — an
unexamined failure mode caps its score.

## 3. Synthesize

Take the winner as the skeleton, then explicitly graft the runners-up's best ideas
(the judge output lists them). Present to the user: the recommendation first, the
losing options in one line each with why they lost, and the trade-off the user is
implicitly accepting. Recommend — don't present a menu without a pick.

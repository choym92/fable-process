---
name: insights
description: Insight ledger for analysis work — capture findings from data analysis/EDA/modeling chats into a durable, curated INSIGHTS.md before context bloat buries them. Use in DS/analytics sessions, when the user says "인사이트 정리", "record this finding", or a long analysis chat produced conclusions not yet written down.
---

# Insights: chat is where insights are born; chat is also where they die

Scope: $ARGUMENTS (if empty, harvest the current analysis conversation).

Analysis conversations produce load-bearing findings, then compaction and session
end erase them — or worse, preserve a lossy summary of a summary. The ledger is
the durable home: one curated file per project, `.fable/INSIGHTS.md` (or the
project's existing docs location if one is established).

## Entry format (one insight = one entry)

```markdown
## [YYYY-MM-DD] <one-line claim>
- Evidence: file/notebook/query + the actual numbers (not "improved a lot")
- Affects: which decision or downstream work this changes
- Status: CONFIRMED / UNCERTAIN (what would settle it) / REFUTED (why, kept to prevent re-derivation)
```

## Curation rules (the ledger is curated, not appended)

- Duplicate or refined finding → UPDATE the existing entry, never add a second.
  Keep the entry's date+title line stable when updating (WORKLOG points at it);
  refine the body instead.
- Refuted finding → change Status to REFUTED with the counter-evidence; do not
  delete — a recorded dead end prevents re-running the same rabbit hole.
- Evidence must be reproducible: the query/notebook/command that regenerates the
  number, not a prose recollection of it.
- No narrative, no chat transcript — claims with evidence only. If an entry
  needs three paragraphs, it is probably three entries or not yet understood.

## When to fire

- During analysis: the moment a finding changes a decision, write it — do not
  batch for the end of the session.
- Before the session ends or when context has grown long: sweep the conversation
  for findings not yet in the ledger; add or update them.
- When resuming analysis: read the ledger FIRST and re-anchor — the ledger
  outranks your in-context memory of prior sessions; current data always
  outranks the ledger (update it when they disagree).

Division of labor: this skill is the judgment half (what counts as an insight,
how to state it). The mechanical half — remembering to run the sweep — can be a
Stop-hook nudge later if practice shows it's forgotten; observe first.

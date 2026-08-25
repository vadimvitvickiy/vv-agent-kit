---
name: capturing-decisions
description: Use when a decision, correction, or design rationale emerges that would otherwise be lost when the session ends.
---

# Capturing decisions

Session state is disposable. `.agents/` is gitignored by construction, so **anything that must
outlive the session has to be promoted** into `.claude/context/`.

| What | Goes to |
|-|-|
| A decision and the reasoning behind it | `.claude/context/decisions.md` |
| A validated design | `.claude/context/specs/` |
| A correction about how to work | durable memory (`MEMORY.md`) |
| A plan in flight, scratch, tool state | `.agents/` — and stays there |

## Promote it into the repo it is about

`.claude/context/` holds facts about **this** repository. A design for a different project does not
belong here just because it was drafted in this session — it belongs in that project's repo, and
committing it here puts another codebase's history into this one permanently.

Before promoting, ask: *would someone cloning this repo need this?* If the answer is no, it goes to
the other repo, or stays in `.agents/`.

## Why promotion is a step and not a habit

Left implicit, it never happens. In the repo this kit was extracted from, in-flight plans
accumulated for months in one directory while the durable decisions file next to it stayed an empty
header. Nothing was ever *forced* to graduate, so nothing did — and the reasoning behind a year of
architectural choices existed only in closed sessions.

Promote at the moment the decision is made, not at the end. There is no end.

## What earns a record

Record it when the reasoning is not recoverable from the code:

- A choice between two viable options, and why this one.
- A constraint that is not visible from any single file.
- A rejected approach, and what ruled it out — this is the one people most often need and least often
  write down.
- A correction from your human partner about how to work.

Do **not** record what the repository already tells you: code structure, git history, or anything
stated in the project's own documentation. If asked to remember something already recorded there, ask
what was non-obvious about it and record that instead.

## The shape of a record

One fact per entry. State what was decided, then **why**, then what it rules out. Convert relative
dates to absolute ones — "last week" is meaningless when read in six months.

Link related records to each other. A pointer to a record that does not exist yet is fine; it marks
something worth writing.

## Recalled records are stale by default

A record reflects what was true when it was written. Before acting on one that names a file,
function, or flag, **verify that thing still exists.** A confidently wrong recollection is more
expensive than no recollection, because it is acted on without checking.

Delete records that turn out to be wrong. An outdated record is not harmless history.

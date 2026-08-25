---
name: exploring-a-codebase
description: Use when starting work in an unfamiliar repository, or when the project's structure map is missing, stale, or contradicted by what the code actually shows.
---

# Exploring a codebase

Read the committed structure map at `.claude/context/structure.md` before fanning out searches. It
exists to make exploration cheap — a precomputed map costs one read, where rediscovering the same
layout costs a dozen searches every session.

## Treat the map as a claim, not a fact

A structure map is a snapshot that started decaying the moment it was written. **When it contradicts
the code, the code wins** — then fix the map in the same change. A map nobody corrects becomes a map
nobody trusts, which is the same as having none while still paying to read it.

The same applies to every always-loaded document. A confidently wrong line in `CLAUDE.md` is worse
than a missing one, because it is trusted and acted on without checking.

## Matching the tool to the question

| Situation | Approach |
|-|-|
| One to three targeted lookups, target known | Search directly. A subagent's startup exceeds the task. |
| Open-ended sweep across many files or naming conventions | A read-only subagent. See `kit:delegating-work`. |
| "Where is X?" and you are unsure what X is called | A subagent — the false-negative cost of a missed file far exceeds the tokens saved |
| You already know the file | Read it. Do not search first. |

Know what you are looking for before opening a file. Locate the relevant section first on anything
large, rather than reading it whole.

## Regenerating the map

Regenerate rather than patching by hand — the kit ships a command for it. What it cannot verify, it
omits rather than guesses. A guessed entry is indistinguishable from a verified one once written,
which is what makes guessing expensive.

## Verify before you assert

Before writing any convention into a document that others will trust, check it against the code:

| Claim | Check |
|-|-|
| A library is banned or required | Grep for its import |
| A component has shape X | Compare against the project's own scaffold or the newest examples |
| A marker or prefix convention holds | Grep for the marker; count occurrences |
| A command is how you build or test | Run it |

A claim that fails its check gets reported, not written.

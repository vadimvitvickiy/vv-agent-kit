---
name: exploring-a-codebase
description: Use when starting work in an unfamiliar repository, when locating code across many files, or when a project's code map or architecture notes look stale.
---

# Exploring a codebase

**Live search is the primary tool.** Grep and glob read the code as it is right now; every map is a
snapshot that started decaying when it was written.

The published evidence for repo maps is thin and contested, and the well-attested failure is a stale
map confidently pointing an agent at code that moved. Treat any map as a hint, never as a source of
truth.

## Two artifacts, one hard line

| Artifact | Written by | Trust it for |
|-|-|-|
| `.agents/state/map.xml` | a generator, never a human | Which types matter and roughly where they are |
| `.claude/context/architecture.md` | a human | Constraints and gotchas that no amount of reading reveals |

If a repo has a hand-written file describing its directory tree, that file is a liability. The
information is derivable, so it is duplicated; being duplicated, it drifts.

## Order of operations

1. **Read the generated map** if there is one. It is cheap and ranks the codebase by what is actually
   referenced.
2. **Read the architecture constraints.** Layering rules, frozen names, generated files. These are
   the things that get you in trouble precisely because they are invisible in the file you are
   editing.
3. **Then search.** The map tells you which types matter; grep tells you where they are used today.

## Matching the tool to the question

| Situation | Approach |
|-|-|
| One to three lookups, target known | Search directly. A subagent's startup exceeds the task |
| Open-ended sweep across many files or naming conventions | A read-only subagent — see `vvkit:delegating-work` |
| "Where is X?" and you are unsure what X is called | A subagent. A missed file costs far more than the tokens saved |
| You already know the file | Read it. Do not search first |

Know what you are looking for before opening a file. On anything large, locate the section first
rather than reading it whole.

## When a map or doc contradicts the code

**The code wins, every time.** Then fix the artifact in the same change:

- A wrong *generated* map means the generator is stale — regenerate it, do not edit it.
- A wrong *architecture note* means a human claim expired — correct it, and say so in your summary.

Silently working around a wrong document leaves it wrong for the next reader, who will trust it
exactly as much as you did.

## Verify before you assert

Before writing any convention into a document others will trust:

| Claim | Check |
|-|-|
| A library is banned or required | Grep for its import |
| A component has shape X | Compare against the project's own scaffold, or the newest examples |
| A marker or prefix convention holds | Grep for it; count occurrences |
| A command builds or tests the project | Run it |
| A target contains a directory | Ask the build system. **Never infer target membership from folder layout** |

A claim that fails its check gets reported, not written.

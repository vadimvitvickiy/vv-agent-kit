---
name: exploring-a-codebase
description: Use when starting work in an unfamiliar repository, when locating code across many files, or when a project's code map or architecture notes look stale.
---

# Exploring a codebase

**Live search is the primary tool.** Grep and glob read the code as it is now; every map is a
snapshot decaying since it was written. The evidence for repo maps is thin; the well-attested failure
is a stale map pointing confidently at code that moved. A map is a hint, never the truth.

## Two artifacts, one hard line

Paths are what `/vvkit:onboard` scaffolds; elsewhere look for an `ARCHITECTURE.md`, `docs/`, or a
generated map.

| Artifact | Written by | Trust it for |
|-|-|-|
| A code map — `.agents/state/map.xml` after onboarding | a generator, never a human | Which types matter and roughly where they are |
| Architecture notes — `.claude/context/architecture.md` after onboarding | a human | Constraints and gotchas no amount of reading reveals |

A hand-written description of the directory tree is a liability: derivable, so duplicated, so it
drifts.

## Order

1. **The generated map**, if any — cheap, ranked by what is referenced.
2. **The architecture constraints**, if any — layering rules, frozen names, generated files. They are
   invisible in the file you edit.
3. **Then search** — the map says what matters; grep says where it is used today.

## Match the tool to the question

| Situation | Approach |
|-|-|
| One to three lookups, target known | Search directly. A subagent's startup exceeds the task |
| Open-ended sweep across many files or naming conventions | A read-only subagent — see `vvkit:delegating-work` |
| "Where is X?" and unsure what X is called | A subagent. A missed file costs more than the tokens saved |
| You already know the file | Read it. Do not search first |
| How the codebase already solves this kind of problem | `vvkit:architecture-surveyor` |

On anything large, locate the section before reading it whole.

## History answers "why is this here"

| Question | Command |
|-|-|
| When did this string, flag or symbol appear or disappear? | `git log -S'<text>' --oneline` |
| How did this function change over time? | `git log -L :<function>:<file>` |
| Who last touched this line, in what change? | `git blame -w -C <file>` |
| Which change first broke this? | `git bisect run <predicate>` |

- **Blame names the last toucher, not the author of the logic.** A reformat resets it; `-w` ignores
  whitespace, `-C` follows code moved between files.
- **Bisect names the commit that exposed a defect, not always the one that introduced it** —
  `vvkit:debugging-systematically`.
- A commit message explaining a constraint beats the note that paraphrased it: it is dated and
  attached to the change that made it true.

## When a map or doc contradicts the code

**The code wins.** Fix the artifact in the same change:

- A wrong generated map: regenerate it, never edit it.
- A wrong architecture note: correct it, and say so in the summary.

Working around a wrong doc silently leaves it wrong for the next reader.

## Verify before you assert

Before writing a convention into a document others will trust:

| Claim | Check |
|-|-|
| A library is banned or required | Grep for its import |
| A component has shape X | Compare against the project's scaffold, or the newest examples |
| A marker or prefix convention holds | Grep for it; count occurrences |
| A command builds or tests the project | Run it |
| A target contains a directory | Ask the build system. **Never infer target membership from folder layout** |

A claim that fails its check gets reported, not written.

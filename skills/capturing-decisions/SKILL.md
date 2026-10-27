---
name: capturing-decisions
description: Use when a decision, correction, or design rationale emerges that would otherwise be lost when the session ends.
---

# Capturing decisions

**Session state is disposable. Anything that must outlive the session is promoted into the repo**,
wherever this project keeps its decisions — at the moment it is decided, not at the end. There is no
end: in the repo this kit came from, plans piled up for months while the decisions file beside them
stayed an empty header.

| What | Goes to |
|-|-|
| A decision and its reasoning | The project's decision record — `docs/adr/`, `docs/decisions/`, a `decisions.md`. After `/vvkit:onboard`, `.claude/context/decisions.md` |
| A validated design | Where the project keeps designs. After onboarding, `.claude/context/specs/` |
| A correction about how to work | Durable memory, when the harness has one |
| A plan in flight, scratch, tool state | The session's scratch area — `.agents/` after onboarding — and stays there |

- No decision home in the project: ask before creating one. A new directory is a convention imposed
  on everyone who clones the repo.
- **Promote into the repo it is about.** A design for another project goes to that project's repo.
  Test: would someone cloning this repo need it?

## What earns a record

Record it when the reasoning is not recoverable from the code:

- A choice between viable options, and why this one.
- A constraint not visible from any single file.
- A rejected approach and what ruled it out — the one most needed and least written.
- A correction from the human about how to work.

Do not record what the repo already says: code structure, git history, the project's docs. Asked to
remember something already there, record what was non-obvious about it instead.

## Shape

- One fact per entry: what was decided, **why**, and what it rules out.
- Absolute dates — "last week" is meaningless in six months.
- Link related records. A link to one not written yet marks something worth writing.
- **Deferred work carries a date, a reason, and what brings it back** — "when a second channel
  exists". An old deferral whose trigger never came has expired: delete it or schedule it.

## Recalled records are stale by default

- Before acting on a record that names a file, function or flag, **verify it still exists.**
- Delete records that turn out wrong. An outdated record is not harmless history.

---
name: choosing-subagent-models
description: Use when about to launch any subagent — a research or exploration agent, a reviewer, an implementer, a parallel fan-out, or a fork.
---

# Choosing subagent models

**Every spawn names its model.** An omitted `model` inherits the main session's: a lookup launched
from an Opus session runs at full price, and a final review launched from a cheap session silently
runs cheap. Neither announces itself.

The kit's spawn hook refuses a launch that omits `model`. It never picks one for you — the choice
is made here, by the work the subagent will do, not by the model the session happens to run.

## The table

| The subagent's job | Model |
|-|-|
| Mechanical and fully specified — read a known file and extract a value, summarize a test run or a log, apply a change whose exact text is given — where one command proves it done | `haiku` |
| Gathering — web research, codebase exploration, "where is X", reading code to answer a question, implementing a plan task whose code is written out, reviewing one task's diff | `sonnet` |
| Judgment — design and architecture, debugging after a fix has already failed, security review, the final review of a branch, implementing from prose where decisions are still open | `opus` |

Use the aliases, not version IDs. `haiku`, `sonnet` and `opus` resolve to the current model of each
tier, so the table survives a model release.

## Where the lines fall

- **Haiku gets no search.** If it is unclear where to look or what the thing is called, the task is
  research, and research is `sonnet`. A file the cheap model fails to find costs more than every
  token it saved, because the answer that comes back is confidently incomplete.
- **Haiku stops at its first failure.** A command that fails, an edit that does not apply, output
  that does not match — re-spawn on `sonnet` rather than retrying. The cheapest models take two to
  three times the turns on multi-step work and end up costing more overall.
- **Sonnet is the floor for anything that decides correctness** — every reviewer, and every
  implementer that has to make a test pass.
- **Research fleets stay on sonnet, even for an architectural question.** The readers gather; the
  judgment happens in the main conversation when their results come back. Paying Opus prices for
  fetching pages buys nothing the synthesis does not already get.
- **Escalate instead of repeating.** A blocked implementer or a fix loop that is not converging goes
  up a tier. The same spawn on the same model produces the same result.
- **Two failed rounds end re-dispatching.** After two rounds that fail or contradict each other, do
  not send the same brief again. Take over the core of the task in the main conversation, or
  re-dispatch a narrower piece of it one tier up. A wide brief that failed twice fails on scope, and
  a stronger model given the same scope inherits the same ambiguity.

## Special cases

- **A fork** always runs on the parent's model and ignores `model`. Choosing to fork is choosing the
  session's price — fork only when the inherited context is worth it.
- **A named agent whose definition sets `model`** — a plugin reviewer, a project agent — already
  carries its author's choice. Pass nothing, or override it only with a reason you can state.
- **The user named a model.** Theirs wins over this table.
- **`CLAUDE_CODE_SUBAGENT_MODEL`** forces one model onto every subagent and flattens the table. It is
  a debugging tool, not a policy.

`KIT_SUBAGENT_MODEL_GATE=0` turns the spawn hook off. The table still applies.

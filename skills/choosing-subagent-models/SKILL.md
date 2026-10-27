---
name: choosing-subagent-models
description: Use when about to launch any subagent — a research or exploration agent, a reviewer, an implementer, a parallel fan-out, or a fork.
---

# Choosing subagent models

**Every spawn names its model.** An omitted `model` inherits the session's: a lookup from an Opus
session runs at full price, a final review from a cheap session runs cheap, and neither says so.

- The kit's spawn hook refuses a launch with no `model`. It never picks one — pick here, by the job,
  not by the model the session happens to run.
- Use the aliases `haiku`, `sonnet`, `opus`, not version IDs. They survive a model release.

## The table

| The subagent's job | Model |
|-|-|
| Mechanical and fully specified — read a known file and extract a value, run a known test, build or lint command and report its output, summarize a log, apply a change whose exact text is given — where one command proves it done | `haiku` |
| Gathering — web research, codebase exploration, "where is X", reading code to answer a question, implementing a plan task whose code is written out, reviewing one task's diff | `sonnet` |
| Judgment — design and architecture, debugging after a fix has already failed, security review, the final review of a branch, implementing from prose where decisions are still open | `opus` |

## Where the lines fall

- **Haiku gets no search.** Unclear where to look, or what the thing is called, makes it research —
  `sonnet`. A file haiku fails to find comes back as a confidently incomplete answer.
- **Haiku stops at its first failure** — a failed command, an edit that does not apply, unexpected
  output. Re-spawn on `sonnet`; do not retry. Cheap models take 2–3× the turns on multi-step work
  and cost more overall. A red run from `vvkit:test-runner` is its result, not its failure.
- **Sonnet is the floor for anything that decides correctness**: every reviewer, every implementer
  that must make a test pass.
- **Research fleets stay on `sonnet`**, even for an architectural question. Readers gather; the
  judgment happens in the main conversation.
- **Between two tiers, take the higher** and say so. When the higher one is a real cost — a fleet,
  a long run — ask once, naming both tiers and what the higher one buys.
- **Escalate, do not repeat.** A blocked implementer or a fix loop that is not converging goes up a
  tier. The same spawn on the same model gives the same result.
- **Two failed rounds end re-dispatching.** Take the core back into the main conversation, or send a
  narrower piece one tier up. A wide brief that failed twice fails on scope, and a stronger model
  inherits the same ambiguity.

## Special cases

- **A fork** runs on the parent's model and ignores `model`. Fork only when the inherited context is
  worth the session's price.
- **A named agent whose definition sets `model`** carries its author's default for an ordinary job.
  Pass nothing when the table agrees; pass a tier up when the job is bigger — a whole branch,
  security-sensitive code. Never a lower one.
- **The user named a model.** Theirs wins.
- **`CLAUDE_CODE_SUBAGENT_MODEL`** forces one model onto every subagent. A debugging tool, not a
  policy.
- `KIT_SUBAGENT_MODEL_GATE=0` turns the spawn hook off. The table still applies.

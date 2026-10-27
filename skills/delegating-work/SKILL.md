---
name: delegating-work
description: Use when a change is expected to span multiple files or modules, or when deciding whether to hand work to subagents, run them in parallel, or keep it in the main conversation.
---

# Delegating work

**Parallel readers, single writer.** Research fans out. Design decisions and edits never do.

## Gate

- A diff describable in one sentence — a single-file fix, a rename, a log tweak — skips all of this.
  Test and review rules still apply.
- **A subagent's main value is isolation, not parallelism.** Early in a session, under ~5 tool calls
  is cheaper inline. In a large conversation, one subagent that contains verbose output — a test
  run, a log sweep, a grep-heavy search — pays for itself.
- **Repetitive mechanical work across many sites:** do one unit by hand, then build the script or
  tool that matches it for the rest. Check the tool's output against the hand-done unit.

## Single writer is not fresh writer

- **Single writer** is concurrency: never two agents editing at once.
- **Fresh writer per task** is context: deliberately discarding context between units.

| A fresh writer per task wins | One writer holding full context wins |
|-|-|
| Tasks are mechanically independent | Tasks must be **consistent with each other** |
| Verbose tool output would flood context | Judgment built up earlier still applies |
| The brief is cheaper to write than the output | Writing the brief ≈ writing the output |
| Accumulated drift is the risk | Cold-start divergence is the risk |

- The third row decides most cases. A brief that must say what to keep, strip, and how it reads beside
  its neighbours is already the work. **Never delegate understanding.**
- Coherent work split across cold starts produces N variants that each restate shared context, then
  drift.

## Phases

1. **Scope.** The goal, what is affected, what is out of scope.
2. **Research — fan out.** Every applicable reader in one message, read-only, with an explicit model —
   `vvkit:choosing-subagent-models`. Usually: prior art — `vvkit:architecture-surveyor`; any contract,
   schema or interface touched; the spec or ticket. Several independent failures get one read-only
   investigator each, returning root cause and proposed change — unless one fix might fix the others,
   then investigate together.
3. **Plan — never delegated.** Design stays where the full conversation is —
   `vvkit:designing-changes` — and the plan is written beside it.
4. **Implement — one writer** at any moment; executing a plan is `vvkit:planning-changes`. Never
   parallel implementers in one working tree. Tasks the human asks to run side by side get a worktree
   and branch each — `/vvkit:worktree` — and merge one at a time.
5. **Verify, then review.** Build and test first. Then one independent reviewer that never saw your
   reasoning, reading the diff itself — the one stage always worth delegating.

## The spawn prompt

Every spawn carries four things; missing one is the usual cause of a useless result.

1. **Objective** — the question, not the procedure. Over-prescribed steps yield shallow work.
2. **What is ruled out**, so it does not re-derive dead ends.
3. **Known paths** — files, symbols, line numbers.
4. **An output contract** — exact shape and a length cap. A `file:line` or verbatim output behind every
   claim, verified facts apart from inferences.

A subagent gets no conversation history. Anything it needs is in the prompt.

## Accepting a result

A report is a claim about the work, not evidence. It cites locations just as fluently whether or not
it read them.

- **Read the cited `file:line` yourself** for every claim a decision rests on.
- **Re-derive counts and outcomes from the machine** — `git diff --stat` for "changed N places", a
  re-run or `vvkit:test-runner`'s exit code for "tests pass".
- **High-risk conclusions need a second opinion that never saw the first** — deletion, security,
  production config, anything the user will act on. Two independent agents, or one briefed to refute;
  accept what both agree on or the refuter failed to break.

## Common mistakes

| Mistake | Why it fails |
|-|-|
| Fanning out implementers to go faster | Conflicting edits; writes stay serial |
| Delegating the plan | The planner needs the full conversation |
| Accepting a subagent's "done" | It reports what it intended |
| Running the pipeline on a one-sentence change | That is what the gate is for |
| Omitting the output contract | Unstructured results defeat the isolation |
| Nesting subagents | Subagents cannot spawn subagents; chain from the main conversation |
| Re-reading a result that timed out | It can double-count or truncate. Raise the timeout instead |
| Reporting a background agent's result before it lands | You do not know what it found until the notification arrives |

Frontmatter fields, tool restrictions, memory, isolation and anti-patterns:
`references/subagent-reference.md`.

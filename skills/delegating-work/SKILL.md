---
name: delegating-work
description: Use when a change is expected to span multiple files or modules, or when deciding whether to hand work to subagents, run them in parallel, or keep it in the main conversation.
---

# Delegating work

**Parallel readers, single writer.** Research fans out. Design decisions and edits never do.

## Gate

If the diff is describable in one sentence — a single-file fix, a rename, a log tweak — skip all of
this and do the work. Test and review rules still apply. Running a pipeline over a one-line change
is the most common way this skill gets misused.

## Two rules that get conflated

"Single writer" and "a fresh writer per task" are different claims, and confusing them produces bad
decisions in both directions.

- **Single writer** is a *concurrency* constraint: never two agents editing at once. It is about
  conflicting edits.
- **A fresh subagent per task** is a *context* strategy: deliberately discard context between units
  of work.

Both satisfy single-writer. Choose between them on what dominates quality:

| A fresh writer per task wins | One writer holding full context wins |
|-|-|
| Tasks are mechanically independent | Tasks must be **consistent with each other** |
| Verbose tool output would flood context | Judgment built up earlier still applies |
| The brief is cheaper to write than the output | Writing the brief ≈ writing the output |
| Accumulated drift is the risk | Cold-start divergence is the risk |

The third row decides more cases than the others. When a task's brief must specify what to keep,
what to strip, and how it should read alongside its neighbours, you have already done the work —
handing it off adds a translation loss and saves nothing. **Never delegate understanding.**

The second column's failure mode is real too: work that must cohere, split across cold starts,
produces N variants that each defensively restate shared context. That is how one rule ends up
duplicated across three files that then drift apart.

## Phases

**1. Scope.** Pin the goal, what is affected, what is explicitly out of scope.

**2. Research — fan out.** Launch every applicable reader in one message, read-only, with an
explicit model. Readers are independent and never write. Three that usually apply: prior art in this
repo; verification of any contract, schema or interface the change touches; the requirements source
when a spec or ticket exists.

**3. Plan — never delegated.** Design decisions stay where the full conversation is. Splitting them
across agents produces conflicting implicit assumptions. Write the plan to `.agents/plans/`.

**4. Implement — one writer.** Exactly one writer at any moment. Choose fresh-per-task or
full-context by the table above. Parallel implementers are never used: file disjointness is rarely
enforceable, and shared project files make it worse.

**5. Verify, then review.** The build and test gate first. Then one independent reviewer that never
saw your reasoning — reading the diff itself, not your account of it. Fresh context is a genuine
advantage here, which is why review is the one stage that should always be delegated.

## The spawn-prompt contract

Every spawn carries four things. Missing any one is the usual cause of a useless result.

1. **Objective** — the question, not the procedure. Over-prescribing steps yields shallow work.
2. **What is already ruled out** — so the agent doesn't re-derive dead ends.
3. **Known paths** — files, symbols, line numbers you already have.
4. **An output contract** — exact shape and a length cap. Without one, the result is unparseable
   and floods the context you delegated to protect.

A subagent receives no conversation history. Anything it needs must be in the prompt.

## Common mistakes

| Mistake | Why it fails |
|-|-|
| Fanning out implementers to go faster | Conflicting edits; writes stay serial |
| Delegating the plan | The planner needs the full conversation |
| Accepting a subagent's "done" | It reports what it intended; check the diff |
| Running the pipeline on a one-sentence change | That is what the gate is for |
| Omitting the output contract | Unstructured results defeat the isolation |
| Nesting subagents | Subagents cannot spawn subagents; chain from the main conversation |

## Reference

Frontmatter fields, tool restrictions, memory options, isolation and anti-patterns:
`references/subagent-reference.md`.

# Executing a plan

The plan already did the thinking. Execution is carrying it out exactly, proving each step with a
test you watched fail and then pass, and leaving a record that survives your own forgetting.

## Before the first task

**Isolate the workspace.** Check first whether you are already in one: `git rev-parse --git-dir`
differs from `git rev-parse --git-common-dir` inside a linked worktree — and inside a submodule,
which `git rev-parse --show-superproject-working-tree` tells apart. If you are not isolated, ask
before creating a worktree, and use the harness's own worktree tool when there is one: a
`git worktree add` behind the harness's back creates state it cannot see or clean up. A project-local
worktree directory must be gitignored before the first worktree goes in it, or the whole tree gets
committed. Never start on the default branch without the human's consent.

**Run the suite once before changing anything.** A baseline that is already red makes every later
failure ambiguous. If it is red, report it and ask whether to proceed.

**Keep a ledger file.** Conversation memory does not survive compaction, and an executor that loses
its place re-implements tasks whose commits already exist. Keep the ledger beside the plan — the
plan's name with a `.progress.md` suffix — with the plan's path as its first line. A task with a
`complete` line is done: after a compaction, trust the ledger and `git log` over your own
recollection. A ledger naming a different plan belongs to that plan; leave it alone.

**Scan for conflicts between tasks.** For each task that consumes what an earlier one produces,
compare the two Interfaces blocks and record what you found. Rule on each mismatch, with the design
as the binding authority, before Task 1 starts.

## The task loop

1. **Read the task's own text**, every time — including tasks you remember. What you remember is a
   summary; the task has the exact values, signatures and test cases.
2. **Work the steps in order.** A test step is written first and run first. Watching it fail is a
   step, not a formality: a test that passes before the implementation exists is a finding about the
   test.
3. **Compare every command's output with its `Expected:` line.** If it matches, continue. If the
   code is wrong, debug it — `vvkit:debugging-systematically` — and never patch the symptom until
   the output matches. If the plan is wrong, rule on the smallest change that satisfies the design
   and record it.
4. **Commit as the plan's steps say.** Note the commit the task started from: a review range cut
   from `HEAD~1` silently drops all but the last commit of a multi-commit task.
5. **Meet the completion contract.** Every test the task names exists and ran; the final run passed
   and its output was read; every `Expected:` line was compared with real output; every deviation
   has a recorded ruling. Then write the ledger line — commit range and test result — in the same
   call as the commit, not in a call of its own.

Redirect long test output to a file and read its tail. Everything a command prints stays in context
for the rest of the session and is re-read on every later turn.

## Rulings, not stalls

A running plan does not wait on the human for questions judgment can settle. Decide conflicts,
ambiguities and plan defects, and record each as
`Ruling: <what you decided> — <why> — <what it costs if wrong>`. A deviation without a ruling is a
decision made in secret.

Four things stop execution, and only these: an irreversible or destructive operation; a
security-sensitive action; a side effect outside the workspace that norms say to ask about first —
a merge, a push to a shared branch, a publish; and a plan so broken that every path forward is a
guess. Do not stop between tasks to ask whether to continue; the human chose to run the plan.

## A subagent per task

When each task goes to a fresh implementer, the main conversation coordinates and never implements —
fixes made there skip review. `vvkit:delegating-work` covers the spawn prompt; on top of it:

- **Hand over files, not pastes.** Write each task's text and each review's diff to a file and pass
  the path. Anything pasted into a spawn prompt, or printed back, stays in the coordinator's context.
- **Batch small same-shape tasks** — the same one-line change across several files — into one spawn,
  reviewed as one diff.
- **Choose each model by role, and set it explicitly** — `vvkit:choosing-subagent-models`.
- **Require a status from the implementer**: done, done with concerns, needs context, or blocked.
  Read concerns before review. Give missing context and re-spawn. A blocked implementer needs
  something to change — more context, a more capable model, a smaller task, or a ruling on the
  plan — never the same spawn again.
- **Review every task**, against both the design and the code's quality, from the task's diff file
  and the constraints block copied verbatim. Never tell a reviewer what not to flag; a finding you
  expect to be wrong is adjudicated after it is raised, not suppressed before.
- **Cap the fix loop.** A round is one fix and one re-review scoped to the fix's diff. Rounds one to
  three go back to the original implementer; rounds four and five to a fresh one on a more capable
  model. After round five, adjudicate what is still open and record each decision: park it with a
  ruling, or, if later tasks build on it, rule on the smallest change that unblocks them. Minor
  findings never enter the loop; they go to the ledger as deferred.

## The final review

Review the whole branch once, from its merge base, with a fresh reviewer on the most capable model —
`vvkit:reviewing-code` — handing it the plan, the design, the review focus, and the ruling lines
from the ledger. When no subagent is available, do the review as a separate pass and say plainly it
was a self-review: the author's blind spots are still in it.

Re-grade the findings by their effect on a person using the software, not by whether the design
mentions the input that triggers them. Then fix the Critical and Important ones in **one** pass —
each with a test that fails first, and a green suite at the end — by a single fixer holding the whole
list, not one per finding. Minors go to the ledger. A finding you decide not to fix is a ruling.

## Finish

The final message lists every ruling, in order, with its cost if wrong, and every deferred minor.
It is the only place the decisions taken on the human's behalf reach them. Then delete the
ledger — git history is the record now — and hand over how to integrate the branch:
`vvkit:committing-changes`.

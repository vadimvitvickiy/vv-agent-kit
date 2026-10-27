---
name: planning-changes
description: Use when an agreed design needs turning into an implementation plan, when a written plan is about to be carried out, or when resuming a plan part-way through after a break or a compaction.
---

# Planning changes

**A plan is the design turned into steps someone with no context can execute.** A fresh subagent, a
later session, or you after a compaction sees the plan and nothing else; whatever it leaves implicit
gets reinvented, differently.

Design comes first — `vvkit:designing-changes`. A plan before an agreed design commits to decisions
nobody approved.

## Map the files before the tasks

- List each file created or changed and its one responsibility. This is where the decomposition is
  decided; tasks follow from it.
- No survey from the design stage: launch `vvkit:architecture-surveyor` in the background, map from
  your own reading meanwhile, reconcile before writing a task. Put the report's path in the plan's
  opening block.
- Files that change together stay together. Follow the existing layout. Split a file the plan already
  touches if it has grown unwieldy; leave untouched files alone.

## Size tasks by what a reviewer could reject

- A task is the smallest unit with its own test cycle that a reviewer could reject while approving its
  neighbor. Fold setup and scaffolding into the task that needs them.
- Each task names:
  - **Files** — exact paths to create, modify and test.
  - **Interfaces** — what it consumes and produces, with exact names and types. An implementer sees
    only its own task.
  - **Steps**, test-first, each with the command and its `Expected:` output.
- **Repetitive work across many sites:** one task does a unit by hand, the next builds the script that
  matches it for the rest.

## Carry the constraints verbatim

- Open with the goal in one sentence, the approach in two or three, the design's path, and the
  project-wide constraints — version floors, naming rules, platform requirements — copied exactly. A
  paraphrased constraint is a second constraint.
- Add a **review focus**: inputs and failure modes the design implies but no task's tests exercise. A
  design's silence on an input is not permission to break on it. For each, add the test to the task
  that owns the code.

## No placeholders

Each is a defect, because the executor fills it with a guess:

- "TBD", "TODO", "similar to Task 3" — tasks get read out of order.
- "Add error handling", "handle edge cases" — which errors, which inputs?
- "Write tests for the above" with no test in the step.
- A name or type used in one task and defined in none.

## Review it against the design

- Every requirement points to a task that implements it.
- Every name and signature is spelled the same where produced and consumed — `clearLayers()` in Task 3
  and `clearAllLayers()` in Task 7 is a bug found here for free.
- Then ask the human to choose how it runs: all tasks in this session with one review of the branch
  at the end, or a fresh subagent per task with a review after each. Recommend one, citing how
  coupled the tasks' interfaces are and what a shipped mistake would cost.

## Carrying it out

The workspace, the progress ledger that survives compaction, the per-task loop, rulings and the final
review: `references/executing-a-plan.md`. Read it before the first task.

## Before handing the plan over

- [ ] The design it implements is named, and was approved
- [ ] Every task has files, interfaces, and test-first steps with expected output
- [ ] Constraints are copied, not paraphrased
- [ ] The review focus lists what no test covers yet, or says nothing is missing
- [ ] No placeholder survives, and every name matches across tasks

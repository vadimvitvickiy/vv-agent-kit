---
name: planning-changes
description: Use when an agreed design needs turning into an implementation plan, when a written plan is about to be carried out, or when resuming a plan part-way through after a break or a compaction.
---

# Planning changes

**A plan is the design turned into steps someone with no context can execute.** Whoever carries it
out — a fresh subagent, a later session, you after a compaction — sees the plan and nothing of the
conversation that produced it. Anything the plan leaves implicit gets reinvented, differently.

Design comes first: `vvkit:designing-changes`. A plan written before the design is agreed commits to
decisions nobody approved.

## Map the files before the tasks

List which files are created or changed and what each is responsible for. This is where the
decomposition is actually decided; the tasks follow from it.

Give each file one responsibility, keep files that change together together, and follow the
codebase's existing layout. Splitting a file that has grown unwieldy is fair game when the plan
already touches it; restructuring what it does not touch is not.

## Size the tasks by what a reviewer could reject

A task is the smallest unit with its own test cycle that a reviewer could reject while approving its
neighbor. Fold setup, configuration and scaffolding into the task whose deliverable needs them. Each
task ends with something testable on its own.

Every task names:

- **Files** — exact paths to create, modify, and test.
- **Interfaces** — what it consumes from earlier tasks and what it produces for later ones, with the
  exact names and types. An implementer sees only its own task; this is how it learns what its
  neighbors call things.
- **Steps**, in test-first order, each with the command to run and the `Expected:` output.

## Carry the constraints verbatim

Open the plan with the goal in one sentence, the approach in two or three, the path to the design
it implements, and the project-wide constraints — version floors, naming rules, platform
requirements — copied exactly from the design. Every task inherits that block. A paraphrased
constraint is a second, slightly different constraint.

Add a **review focus**: the inputs and failure modes the design implies but no task's tests exercise,
most likely to bite first. A design says what the software must do, not everything it will meet; its
silence on an input is not permission for that input to break it. For each line, add the test that
pins it to the task that owns the code.

## No placeholders

Each of these is a plan defect, because the executor fills the gap with a guess:

- "TBD", "TODO", "fill in later", "similar to Task 3" — tasks get read out of order.
- "Add error handling", "validate the input", "handle edge cases" — which errors, which inputs?
- "Write tests for the above", with no test in the step.
- A name or type used in one task and defined in none.

## Review it against the design

Before handing it over, reread the design and the plan side by side:

- Can every requirement be pointed to a task that implements it?
- Does anything above count as a placeholder?
- Is every name and signature spelled the same in the task that produces it and the tasks that
  consume it? `clearLayers()` in Task 3 and `clearAllLayers()` in Task 7 is a bug, found here for
  free or at integration for real.

Then ask the human to read it and choose how it runs: every task in this session, with one fresh
review of the whole branch at the end, or a fresh subagent per task with a review after each.
Recommend one, citing how much the tasks depend on each other's interfaces and what a shipped
mistake would cost.

## Carrying it out

How to execute a plan — the isolated workspace, the progress ledger that survives compaction, the
per-task loop, rulings, and the final review — is in `references/executing-a-plan.md`. Read it
before the first task, not after the first problem.

## Before handing the plan over

- [ ] The design it implements is named, and was approved
- [ ] Every task has files, interfaces, and test-first steps with expected output
- [ ] Constraints are copied, not paraphrased
- [ ] The review focus lists what no test covers yet, or states that nothing is missing
- [ ] No placeholder survives, and every name matches across tasks

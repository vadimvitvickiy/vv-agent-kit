---
name: debugging-systematically
description: Use when a test fails, a bug is reported, or observed behavior does not match expectation, and before proposing or applying any fix.
---

# Debugging systematically

**A fix you cannot explain is a coincidence.** If you cannot name the line that produced the wrong
value and why, do not change anything. This skill owns *do I know why*; `vvkit:verifying-changes`
owns *did I run it*.

## Reproduce before theorizing

- Get a deterministic reproduction at the smallest scope that still fails — one test, one input, one
  path.
- **Intermittency is the finding.** Once in twenty is almost always ordering, timing or shared state.
  Record the rate before changing anything; it is how you will know a fix worked.
- A reproduction that resists shrinking: shrink the environment — fewer threads, a fixed seed, one
  device, one item.

## Trace to where it originates

- Walk the wrong value back to where correct input first became wrong output — not where it was
  observed. The fix belongs in the gap.
- Ask **which layer should have rejected this?** A nil crashing a view was allowed by the model
  builder, the parser, and a schema that made the field optional. The defect is where the invariant
  should have held.
- Fix it there, so the class of bug becomes unrepresentable rather than this instance survivable.
- A toolchain failure no change explains: read the **last** error in the log, and rule out an
  exhausted resource first. A full disk surfaces as a corrupt cache or a linker failure.

## Instrument every boundary the path crosses

- Across components, each layer looks correct on its own. Log what enters and leaves each boundary,
  run once; the first with right input and wrong output names the component.
- Configuration too: a variable set in the workflow and absent in the script it launches looks like a
  logic bug from inside.

## One hypothesis, one change

- State it as "X is wrong because Y"; make the smallest change that would falsify it.
- Two changes in one run cannot be attributed, and the useless one stays as a false fix.
- Revert a failed hypothesis's change before forming the next.

## A live incident mitigates first

- Production failing now: stop the harm — roll back, flip the flag, shed traffic — as an open
  decision, undone once the cause is fixed.
- First keep the evidence — logs, a failing request, the bad record — since a rollback erases the
  reproduction. Label the change as mitigation, then debug against that evidence.

## Band-aids are never the fix

| Band-aid | What it costs later |
|-|-|
| A flag that disables the failing path | The path stays broken with two behaviors to reason about; the flag outlives everyone who knew why |
| A special case for the input that failed | The next input in the class fails the same way, and the pattern that names the cause is hidden |
| A guard that swallows the bad state | A crash with a stack trace becomes silently wrong data, further from the cause |
| A sleep or retry over a race | The race now depends on machine speed and returns on faster CI or under load, reading as deliberate |
| Widening a type to accept what broke it | The invariant is deleted instead of enforced; every reader inherits the doubt |

Blocked and must ship a workaround: **say it is one, and state the real cause.** An unlabelled
band-aid is never revisited.

## Two failed fixes on one premise

- **Two fixes resting on the same assumption fail the same way:** write that premise in one sentence
  and test it before a third fix.
- **Three failed fixes is a design finding.** When each exposes coupling somewhere new, the structure
  is wrong; a fourth fix is sunk cost. Take what the attempts revealed and the structural question to
  the human — restructuring is their decision.
- The human's questions are signals: "is that not happening?" — you assumed; "will it show us…?" —
  evidence was due first; "stop guessing" — fixes without a cause. Go back to reproducing.

## When the cause is outside the code

Timing on shared infrastructure, an external service, a platform defect: write down what was
investigated, add handling that fails visibly — a bounded, logged retry, a timeout, a clear error —
and logging that catches it next time. Suspect this conclusion: most "no root cause" is an
investigation stopped early.

## After the fix, harden the path

Make the bad value unreachable: reject it at the entry point, check it where the operation depends on
it, refuse the dangerous operation where it must never run — such as a test touching a real
directory. Each fails loudly; a guard that swallows is the band-aid above.

## Bisect when the trace goes cold

- Bisect the history, the input or the configuration.
- Automate the predicate — a script exiting 0 for good, 1 for bad. Eyeballing misclassifies silently.
- **Bisect names the commit that exposed a defect, not always the one that introduced it.** Treat it
  as where to read, not the answer.
- For input, halve the dataset until one record fails alone.

## Before you fix

- [ ] The failure reproduces on demand, and you know the rate if it is intermittent
- [ ] You can name the line that produced the wrong value, not just where it surfaced
- [ ] You can name the layer that should have rejected it
- [ ] You can say what the fix breaks if your explanation is wrong
- [ ] A test fails for this reason now and passes after — see `vvkit:writing-tests`

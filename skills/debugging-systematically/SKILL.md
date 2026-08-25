---
name: debugging-systematically
description: Use when a test fails, a bug is reported, or observed behavior does not match expectation, and before proposing or applying any fix.
---

# Debugging systematically

**A fix you cannot explain is a coincidence.** If you cannot say which line produced the wrong value
and why, you are not ready to change anything.

This skill owns *do I know why*. `vvkit:verifying-changes` owns *did I actually run it*. A green run
on a fix you cannot explain satisfies the second and fails the first.

## Reproduce before theorizing

A theory you cannot test is a guess with better grammar. Get to a deterministic reproduction first,
at the smallest scope that still fails — one test, one input, one code path.

If it reproduces only sometimes, **the intermittency is the finding, not an obstacle to it**. A
failure that appears once in twenty runs is almost always ordering, timing, or shared state, and that
narrows the search more than a hundred clean runs would. Record the rate before you change anything;
it is the only way to know later whether a fix worked or the odds just went your way.

When a reproduction resists shrinking, shrink the environment instead: fewer threads, a fixed seed, a
single device, one item instead of a collection.

## Trace to where it originates

Walk the wrong value backwards through every frame that touched it, and stop where correct input
first became wrong output — not where it was finally observed. Those are rarely the same place, and
the gap between them is where the fix belongs.

The useful framing of "five whys" here is **which layer should have rejected this?** A nil that
crashes a view was allowed by whatever handed the view its model, which was allowed by whatever
parsed the response, which was allowed by a schema that made the field optional. The crash is at the
view. The defect is wherever the invariant was supposed to hold and did not.

Fix it at that layer, so the whole class of the bug becomes unrepresentable rather than this one
instance becoming survivable.

## Band-aids that are never the fix

Each of these turns a red signal green without changing what was wrong. The cost lands later, on
someone with less context than you have right now.

| Band-aid | What it costs later |
|-|-|
| A flag that disables the failing path | The path stays broken and now has two behaviors to reason about. The flag outlives everyone who knew why it exists. |
| A special case for the input that failed | The next input in that class fails identically, and the special case hides the pattern that would have named the real cause. |
| A guard that swallows the bad state | The symptom moves somewhere further from the cause. What was a crash with a stack trace becomes silently wrong data. |
| A sleep or retry over a race | Converts a race into a bug that depends on machine speed. It returns on faster CI, on a slower device, or under load — and by then the sleep reads as deliberate. |
| Widening a type to accept what broke it | The invariant that was supposed to hold is deleted rather than enforced, and every downstream reader inherits the uncertainty. |

If you are genuinely blocked and must ship a workaround, **say it is a workaround and state the real
cause**. An unlabelled band-aid is indistinguishable from a fix, so nobody ever comes back for it.

## Binary search when the trace goes cold

When reading cannot find it, bisect something: the change history, the input, or the configuration.

Automate the predicate rather than eyeballing each step. A script that exits 0 for good and 1 for bad
turns a bisect into one command, and removes the misclassification that sends a bisect to the wrong
answer without ever announcing it.

**Bisect names the commit that exposed a defect, not always the one that introduced it.** A latent
bug plus a caller that starts hitting it lands on the caller, which is innocent. Treat the result as
the strongest available clue about *where to read*, not as the answer.

The same logic applies to input: halve the failing dataset until one record fails alone.

## Commit granularity is a debugging instrument

This is why one logical change per commit matters, and the argument is not tidiness. A commit that
mixes a rename with a behavior change makes the bisect land on a diff nobody can read, and the
investigation stalls exactly where it should have finished.

Granularity is paid for once, when committing. It is collected months later, by whoever is bisecting.

## Before you fix

- [ ] The failure reproduces on demand, and you know the rate if it is intermittent
- [ ] You can name the line that produced the wrong value, not just where it surfaced
- [ ] You can name the layer that should have rejected it
- [ ] You can say what the fix breaks if your explanation is wrong
- [ ] A test fails for this reason now and passes after — see `vvkit:writing-tests`

---
name: reviewing-code
description: Use when reading a diff or pull request for defects, when acting as the reviewer on a change you did not write, or when review feedback arrives on your own change.
---

# Reviewing code

**A review exists to catch what the author could not see.** Not to demonstrate diligence, and not to
produce a list. The author has spent hours inside their own assumptions; the only thing you bring
that they cannot is that you do not share them.

## The reviewer does not fix

Review and repair are separate steps. A review that arrives carrying its own patch gets read as a
patch — the diff is applied or discarded, and the findings behind it are never read at all.

Where the tooling allows it, enforce this rather than remember it: a reviewer with read-only tools
cannot drift into fixing. `vvkit-swift:swift-reviewer` sets `tools` explicitly for this reason.

## Scope is the diff, not the repository

Read as much surrounding code as you need for context. Report only on lines the change touched.

Reporting pre-existing problems turns every review into a backlog, and the backlog buries the two
findings that were actually about this change. There is one exception worth taking: **when the diff
makes an existing defect reachable** — a path that was dead is now called, an input that was
validated upstream no longer is — that is a finding about this change, and it belongs in the review.

If the diff is empty, say so and stop. Reviewing the whole repository because there was nothing to
review is not a fallback, it is a different task nobody asked for.

## Severity is about consequence, not confidence

Bucket by what happens if this ships, never by how sure you are.

| Bucket | Meaning |
|-|-|
| Critical | Ships broken: data loss, a crash on a reachable path, a security or privacy hole |
| Important | Works today, fails on a plausible input, on another platform, or under concurrency |
| Minor | Correct but will mislead the next reader, or violates a stated convention |
| Optional | Taste. Kept under its own heading, never interleaved with the three above |

Keeping Optional separate is what protects the other three. Once taste is mixed into the same list,
the reader calibrates on the weakest item, and the Critical is skimmed with it.

## Every finding names a location and a failure

Cite `file:line`. A finding without a location is not actionable, so it gets skipped regardless of
how right it is.

State the concrete failure: **what input or state produces what wrong result**. "This could be
cleaner" is not a finding — it is a feeling about code, and the author cannot act on it. If you
cannot name the input that breaks it, you have found a preference, and it belongs under Optional.

## What to hunt first

Correctness before convention, always. The generic classes, in the order they are worth spending
attention on:

- **Absence** — a value treated as present that is absent in practice: a force-unwrap, a non-null
  assertion, an index assumed to exist, a default that hides a missing case.
- **Lifetime** — anything acquired and not released: a strong reference cycle, an observer or timer
  never torn down, a handle or subscription that outlives its owner.
- **Shared state** — a read-modify-write that is not atomic, initialization reachable from two
  threads, mutable state crossing an isolation boundary.
- **Trust boundaries** — outside input reaching a query, a shell, a file path or a template
  unescaped; a new endpoint or handler with no authorization check, or one that checks who the
  caller is but not what they own; a secret in code or in a log. Confirm the input is actually
  attacker-controlled and the path reachable before reporting — where the framework already escapes
  it, the finding is noise.
- **Contracts** — a changed API, schema, wire format, persisted field or event that something
  already deployed still reads: an older app version, another service, rows written last year.
  Removing or renaming is breaking even when every caller in this repo was updated.
- **Swallowed failure** — an error caught and discarded, a result ignored, a failure path that
  returns a plausible-looking empty value instead of failing.
- **Remote calls** — no timeout, a retry around an operation that is not idempotent, a retry loop
  with no cap.
- **Boundaries** — the first element, the last, the empty collection, the maximum, the negative.
- **Behavior changing without a test** — see `vvkit:writing-tests` for whether one is owed.

Convention comes after, and only where a convention is actually established. See
`vvkit:writing-comments` for what counts as an over-commented diff.

## Review against the requirements too

When a plan, design or ticket exists, it is part of the review's input. Check that everything it
asks for is present, and flag every deviation — the author confirms whether it was intended, and an
unflagged one gets approved by default. If the problem is in the plan rather than the code, say so.

A design says what the software must do, not every input it will meet. Where it is silent, judge by
what a reasonable person using the software would expect, and grade the finding by its effect on
them — not by whether the design happened to name the input that triggers it.

Before the verdict, list every behavior you considered and set aside as outside the requirements,
one line each with the reason. The author rules on each line; nothing gets dropped silently. An
empty list means you set nothing aside.

## Finding nothing is a result

Say so plainly. Do not manufacture findings to look thorough.

The cost of a padded review is not paid on that review — it is paid on the next one. Once an author
learns that most of what you report is noise, they skim, and the Critical you eventually find is
skimmed along with everything else. Credibility is the only tool a reviewer actually has.

## Output shape

```
## Critical
- path/to/File.ext:42 — what breaks, and under what conditions

## Important
- path/to/Other.ext:17 — what breaks, and under what conditions

## Minor
- ...

## Optional
- ...
```

Then state which findings you consider blocking and which you would leave, and a verdict: ready to
merge, not ready, or ready with named fixes. A review that reports without recommending leaves the
decision to the person with the least context.

## Asking for a review

Request one after a substantial piece of work, and always before merging to the default branch.
Give the reviewer what it cannot infer, and nothing of your reasoning:

- **What was built**, in a sentence or two, and **what it should do** — the plan, design or ticket.
- **The exact range**: from the commit the work started at, or `git merge-base <base> HEAD`, to
  `HEAD`. Never `HEAD~1` for work that spans commits; it silently drops all but the last one.
- **Read-only.** The reviewer inspects history with `git show`, `git diff` and `git log`, and never
  moves `HEAD` or touches the working tree; another revision goes in a separate worktree.
- **No sub-reviewers.** One review seat, done by the reviewer itself. A diff too large for one pass
  gets reviewed in passes, and the review says so.

Then fix Critical findings at once, Important ones before moving on, and record Minor ones.

## When you are the author

A finding is a claim about code, and it gets the same scrutiny as any other claim. The reviewer saw
the diff, not the reasons behind it, so an item can be right in general and wrong for this codebase.

- **Clarify every unclear item before implementing any.** Items in one review are often related.
  Implementing the four you understand while asking about the other two builds a partial change on
  the very misreading the answer would have corrected.
- **Check each item against the code.** Does it break existing behavior? Does the current form exist
  for a reason — a platform floor, a compatibility constraint, a decision the human already made?
- **Grep before building it "properly".** When a finding asks for a fuller implementation, check that
  anything calls it. An unused path should be deleted, not completed.
- **Push back with evidence** — a test, a call site, a constraint — not with agreement and not with
  defensiveness. If the pushback turns out wrong, say what you checked, and fix it.
- **Implement one item at a time and test each**, blocking issues first. A batch of fixes that breaks
  a test cannot say which fix broke it.
- **A conflict with an earlier decision by the human goes to the human.** Neither author nor
  reviewer settles it.

Acknowledge with the change, not with praise. "Fixed: the nil path at `Parser.swift:88`" tells the
reviewer the item was understood. "Great catch!" tells them nothing, and reads as agreement you have
not checked.

---
name: reviewing-code
description: Use when reading a diff or pull request for defects, or when acting as the reviewer on a change you did not write.
---

# Reviewing code

**A review exists to catch what the author could not see.** Not to demonstrate diligence, and not to
produce a list. The author has spent hours inside their own assumptions; the only thing you bring
that they cannot is that you do not share them.

## The reviewer does not fix

Review and repair are separate steps. A review that arrives carrying its own patch gets read as a
patch — the diff is applied or discarded, and the findings behind it are never read at all.

Where the tooling allows it, enforce this rather than remember it: a reviewer with read-only tools
cannot drift into fixing. `vvkit:swift-reviewer` sets `tools` explicitly for this reason.

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
- **Swallowed failure** — an error caught and discarded, a result ignored, a failure path that
  returns a plausible-looking empty value instead of failing.
- **Boundaries** — the first element, the last, the empty collection, the maximum, the negative.
- **Behavior changing without a test** — see `vvkit:writing-tests` for whether one is owed.

Convention comes after, and only where a convention is actually established. See
`vvkit:writing-comments` for what counts as an over-commented diff.

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

Then state which findings you consider blocking and which you would leave. A review that reports
without recommending leaves the decision to the person with the least context.

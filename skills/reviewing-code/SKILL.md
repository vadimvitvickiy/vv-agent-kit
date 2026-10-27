---
name: reviewing-code
description: Use when reading a diff or pull request for defects, when acting as the reviewer on a change you did not write, or when review feedback arrives on your own change.
---

# Reviewing code

**A review exists to catch what the author could not see.** Not to show diligence or produce a list.
What you bring is that you do not share the author's assumptions.

## Ground rules

- **The reviewer does not fix.** A review carrying a patch gets read as a patch, and its findings are
  never read. Enforce with read-only tools where possible — `vvkit-swift:swift-reviewer` sets `tools`
  for this reason.
- **Scope is the diff.** Read whatever context you need; report only on touched lines. Pre-existing
  problems bury this change's findings. **Exception:** the diff makes an existing defect reachable —
  a dead path now called, an input no longer validated upstream.
- An empty diff: say so and stop. Reviewing the whole repo instead is a task nobody asked for.

## Severity is consequence, not confidence

| Bucket | Meaning |
|-|-|
| Critical | Ships broken: data loss, a crash on a reachable path, a security or privacy hole |
| Important | Works today, fails on a plausible input, on another platform, or under concurrency |
| Minor | Correct but will mislead the next reader, or violates a stated convention |
| Optional | Taste. Kept under its own heading, never interleaved with the three above |

Mixed with taste, the reader calibrates on the weakest item and skims the Critical with it.

## Every finding names a location and a failure

- Cite `file:line`. A finding without a location gets skipped, however right.
- State **what input or state produces what wrong result**. No breaking input means a preference —
  Optional. "Add tests" or "add docs" counts only when it names the uncovered behavior.
- Two sentences: what breaks and when, then the smallest fix in words, not a patch. Longer only when
  the evidence needs it; never drop a real finding to stay short.

## What to hunt first

Correctness before convention:

- **Absence** — a value assumed present: a force-unwrap, a non-null assertion, an assumed index, a
  default hiding a missing case.
- **Lifetime** — acquired, not released: a retain cycle, an observer or timer never torn down, a
  subscription outliving its owner.
- **Shared state** — non-atomic read-modify-write, initialization reachable from two threads, mutable
  state crossing an isolation boundary.
- **Trust boundaries** — outside input reaching a query, shell, path or template unescaped; a handler
  with no authorization, or one checking who the caller is but not what they own; a secret in code or
  logs. Confirm the input is attacker-controlled and reachable first — where the framework escapes it,
  it is noise.
- **Contracts** — a changed API, schema, wire format, persisted field or event that something deployed
  still reads. A rename is breaking even when every caller in this repo was updated.
- **Counterfeit values** — another layer's type hand-built from data that did not come from there, its
  invented fields read downstream as real. Fix: an entry point taking the data's own type.
- **Swallowed failure** — an error discarded, a result ignored, a plausible empty value instead of a
  failure.
- **Remote calls** — no timeout, a retry around a non-idempotent operation, a retry loop with no cap.
- **Boundaries** — first, last, empty, maximum, negative.
- **Behavior changing without a test** — `vvkit:writing-tests` decides whether one is owed.

Convention after, and only where established — `vvkit:writing-comments` for over-commented diffs.

## Review against the requirements

- A plan, design or ticket is input. Check everything it asks for is present; flag every deviation for
  the author to confirm. A problem in the plan itself: say so.
- Where the design is silent, judge by what a reasonable user would expect, graded by effect.
- Before the verdict, list each behavior you set aside as outside the requirements, one line with the
  reason. The author rules on each.

## Finding nothing is a result

- Say so plainly. Manufactured findings teach the author to skim, and the next Critical gets skimmed.
- Do not imply a check that never ran. A PR description is context, not proof; a limit on what you
  could verify gets one sentence.

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

- Then which findings block, and a verdict: ready, not ready, or ready with named fixes.
- That is the whole review: it opens on the first finding — no introduction, praise, recap, checklist
  or closing summary. Empty buckets are left out; Optional holds at most two. A clean diff gets one
  line saying so, then the verdict.
- **On a re-review, update the earlier findings rather than restating them.** A finding fixed or
  rebutted stays closed without new evidence.

## Asking for a review

Request one after substantial work, and always before merging to the default branch. Give the
reviewer what it cannot infer, and none of your reasoning:

- **What was built** and **what it should do** — the plan, design or ticket.
- **The exact range**: from the start commit or `git merge-base <base> HEAD` to `HEAD`. Never
  `HEAD~1` for multi-commit work.
- **Read-only.** `git show`, `git diff`, `git log`; never move `HEAD` or touch the working tree.
- **No sub-reviewers.** One seat; a diff too large for one pass is reviewed in passes, and says so.

Then fix Critical at once, Important before moving on, and record Minor.

## When you are the author

A finding is a claim, and gets the same scrutiny as any claim.

- **Clarify every unclear item before implementing any** — items are often related.
- **Check each against the code.** Does it break behavior? Does the current form exist for a reason —
  a platform floor, a compatibility constraint, a decision the human made?
- **Grep before building it "properly".** An unused path gets deleted, not completed.
- **Push back with evidence** — a test, a call site, a constraint. Wrong pushback: say what you
  checked, and fix it.
- **One item at a time, tested each**, blocking first.
- **A conflict with the human's earlier decision goes to the human.**
- Acknowledge with the change — "Fixed: the nil path at `Parser.swift:88`" — not "Great catch!".

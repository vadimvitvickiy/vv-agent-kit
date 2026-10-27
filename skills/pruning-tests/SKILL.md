---
name: pruning-tests
description: Use when auditing a test suite for low-value tests, or when deleting, merging or rewriting existing tests or test doubles.
---

# Pruning tests

**Report first, edit second, prove every batch.** A deleted test changes what the suite protects.

- The candidate list goes to the person before any test is edited — "clean it up" asks for the list,
  not permission to skip it.
- The pruner does not grade itself: the proof is numbers, or a separate reviewer.
- What makes a test low-value is decided in `vvkit:writing-tests`. This skill covers removing it
  without losing protection.

## Audit

1. **Baseline.** Record every in-scope test's pass/fail before touching anything. A failing test is a
   bug report until shown otherwise — in one subsystem-wide prune, all three baseline failures were
   real delivery bugs. Fix them at the owner; never delete them.
2. **Read and mark each test by its assertions, not its name** — one named for clearing a window
   asserted it was *not* cleared. Read the production owner, callers and history (did a bug fix add
   it?).
3. **Report and stop**, as one table:

   | Test | Mark | Bug it claims to catch | Proof that remains | Seam freed |
   |-|-|-|-|-|

   Marks: **retain**; **fix** (keep the contract, repair the assertion); **consolidate** (name the
   absorbing test); **delete** (name the remaining proof, or why no contract exists). No evidence, no
   delete.

## What stays

- Race and hang proofs; the only test of a filesystem or database failure mode; regressions from real
  bugs; observable ordering; public API, protocol, config, migration, security and default-value
  contracts. Slow or static is no reason to delete.
- **A weak test that is the only one reaching a path is rewritten, not deleted.** Deleting one that
  slept and asserted loosely took its path from 65% coverage to 0%.

## While pruning

- **Audit doubles too.** Replace a hand-written double with the shared one, keep it with a comment
  naming the control the shared one lacks, or merge copies. The third copy gets promoted.
- **Duplicated production code behind a cluster of tests:** extract it and test it once.
- **Never weaken a test** to improve the deletion count. One coherent batch per change.
- **A whole subsystem** splits by production owner: one read-only agent marks each area, then one pass
  across the marks looks for a redundant layer.

## Prove the prune

Copy into the work for every batch that deletes, merges or rewrites tests:

```
- [ ] Mutant per removed claim: the bug each removed test claimed to catch, applied as a one-line
      mutant; its killer named before and after
- [ ] Coverage per function, before (worktree at the merge base) and after; report non-empty
- [ ] Every function dropped to 0%, or newly over CRAP 30, has a rewritten test or a stated reason
- [ ] Up to ~6 more mutants where coverage dropped or tests changed; all old kills still killed
- [ ] Independent review of deleted coverage against what remains (batches beyond a handful)
- [ ] Report: mutant table with killers before and after, coverage drops with reasons, seams removed
```

- **The first item is never skipped.** "The remaining tests already catch it" is an argument, not a
  run. Apply the mutant.
- **Coverage before mutants.** Mutants only reach paths some test still runs — twelve missed the
  65%-to-0% drop that coverage caught.
- **Each mutant is tied to the deletion:** a killer before the prune is a test this batch removes or
  rewrites. One at a time; restore by reversing the edit, confirm by file hash.
- **A survivor means restore or rewrite a test.** Surviving on both sides is an old gap — add a test
  only if it clears the acceptance filter, watched failing under the mutant.
- **Some runners return an empty coverage report, without warning,** when coverage was not enabled.
- **An independent reviewer finds what the pruner misses** — on one prune, nine contracts that lost
  their only proof and one new assertion that could not fail.
- Tests written after seeing survivors: say so; the score only fits that sample.

CRAP = complexity² × (1 − coverage)³ + complexity. Where the project has tools for coverage, CRAP,
duplication or mutation testing, use them over hand-run mutants. Coverage commands for a stack are in
its testing skill — for Swift, `vvkit-swift:swift-testing`.

Adapted from sergdort's "Pragmatic Testing" agent skill and post (2026), and OpenClaw's `test-audit`
skill, the source of the baseline and review figures.

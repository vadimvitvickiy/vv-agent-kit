---
name: pruning-tests
description: Use when auditing a test suite for low-value tests, or when deleting, merging or rewriting existing tests or test doubles.
---

# Pruning tests

**Report first, edit second, and prove every batch.** A deleted test is a change to what the suite
protects. The candidate list goes to the person before any test is edited — "clean it up" is a
request for the list, not permission to skip it. The agent that pruned does not grade itself: the
proof is numbers, or a separate reviewer.

What makes a test low-value is decided in `vvkit:writing-tests` — its three questions and the
acceptance filter. This skill covers removing such tests without losing protection.

## Audit

1. **Baseline.** Record every in-scope test's pass/fail state before touching anything. A failing
   test is a bug report until shown otherwise — in one subsystem-wide prune, all three baseline
   failures were real delivery bugs. Fix those at the owner; never delete them.
2. **Read and mark each test** by its assertions, not its name — one test named for clearing a
   window was found asserting the window was *not* cleared. Read the production owner, callers and
   history (did a bug fix add it?).
3. **Report and stop**, as one table:

   | Test | Mark | Bug it claims to catch | Proof that remains | Seam freed |
   |-|-|-|-|-|

   Marks: **retain**; **fix** (keep the contract, repair the assertion); **consolidate** (name the
   test that absorbs it); **delete** (name the remaining proof, or why no contract exists). No
   evidence, no delete.

What stays although it looks like an implementation test: race and hang proofs, the only test of a
filesystem or database failure mode, regressions from real bugs, observable ordering, and public
API, protocol, config, migration, security and default-value contracts. Slow or static is no reason
to delete.

- **A weak test that is the only one reaching a path is rewritten, not deleted.** In one prune,
  deleting a test that slept and asserted loosely took its path from 65% coverage to 0%.
- **Audit doubles too.** Replace a hand-written double with the shared fake or mock, keep it with a
  comment naming the control the shared one lacks, or merge it with its copies. The third copy of
  one test-local double gets promoted.
- **Fix the production cause first** when a cluster of low-value tests mirrors duplicated
  production code — extract it and test it once.
- **Never weaken a test** to make the deletion count look better. One coherent batch per change.
- **A whole subsystem** splits along production owners: one read-only agent marks each area, then a
  pass across the marks looks for a redundant layer — a suite replaying what a stronger boundary
  suite proves.

## Prove the prune

Copy this into the work and check it off for every batch that deletes, merges or rewrites tests:

```
- [ ] Mutant per removed claim: the bug each removed test claimed to catch, applied as a one-line
      mutant; its killer named before and after
- [ ] Coverage per function, before (worktree at the merge base) and after; report non-empty
- [ ] Every function dropped to 0%, or newly over CRAP 30, has a rewritten test or a stated reason
- [ ] Up to ~6 more mutants where coverage dropped or tests changed; all old kills still killed
- [ ] Independent review of deleted coverage against what remains (batches beyond a handful)
- [ ] Report: mutant table with killers before and after, coverage drops with reasons, seams removed
```

- **The first item is never skipped.** For a batch of a few tests it can be the whole proof, but an
  argument that the remaining tests "already catch it" is not a run. Apply the mutant.
- **Coverage before mutants.** Mutants only go where some test still runs; a path whose only test
  was deleted is invisible to them. In the prune above, twelve mutants missed the 65%-to-0% drop
  that coverage caught.
- **Each mutant is tied to the deletion.** At least one of its killers before the prune is a test
  this batch removes or rewrites, or it proves nothing about the prune. One at a time; restore by
  reversing the edit and confirm by file hash.
- **A survivor means restore or rewrite a test.** One that survives on both sides is an old gap —
  add a test only if it clears the acceptance filter, watched failing under the mutant.
- **Some runners return an empty coverage report, without warning,** when coverage was not enabled.
- **An independent reviewer finds what the pruner misses:** on one subsystem-wide prune, nine
  contracts that had lost their only proof and one new assertion that could not fail.
- If tests were written after seeing survivors, say so: the score only fits that sample.

CRAP (Change Risk Anti-Patterns) = complexity² × (1 − coverage)³ + complexity. Coverage commands for
a stack live in its testing skill — for Swift, `vvkit-swift:swift-testing`.

Adapted from sergdort's "Pragmatic Testing" agent skill and "Pragmatic Testing for Agents" post
(2026), and OpenClaw's `test-audit` skill, whose Telegram campaign is the source of the baseline
and review figures.

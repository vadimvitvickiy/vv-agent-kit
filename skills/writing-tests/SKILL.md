---
name: writing-tests
description: Use when adding or changing behavior, fixing a bug, or judging whether an existing or generated test earns its place.
---

# Writing tests

**New or changed behavior ships with a test in the same change.** Not later, not in a follow-up. If
you changed what the code *does*, a test must fail when you undo it.

A green suite does not satisfy this. It proves nothing broke; it says nothing about whether the code
you just wrote is exercised at all.

## When a test is required

Required, no exceptions:

- A new type, function, or case carrying logic.
- A changed branch, predicate, mapping, or constant that alters behavior.
- **Every bug fix.** Write the reproducing test first, watch it fail, then fix. A fix without a
  reproducing test is how the same bug ships twice.

Not required:

- Generated code and vendored third-party code.
- Pure UI layout. Test the view-model field mapping instead — the mapping is where the logic is.
- Renames, moves, formatting, comments. No behavior changed.

If a change is genuinely untestable, **say so explicitly, with the reason**. Never skip silently.

## Unit or component

A unit test discharges the rule only when the behavior lives inside one type. When the behavior *is*
the collaboration, the change ships a **component test**: real collaborators composed in-process,
faked only at the outer edges — network, clock, presentation.

Required at the component tier:

- **A new component** — a type that owns a stage of a flow and drives others through their
  interfaces. Its first test is a composed one, not a mock-per-collaborator unit test.
- **A substantial change to a hand-off** — a new call between collaborators, changed ordering, a new
  gate or teardown path, new state another component reads.
- **A cross-type bug fix** — one that only reproduces with two or more real collaborators running. A
  unit test of either side would have passed against the bug.

Stays unit: one type's internal logic, mapping, parsing, constants.

Two ways to get this wrong:

- **Faking a middle collaborator.** That is a unit test wearing a component test's name. Fake the
  edge, or don't fake it.
- **Dropping to unit because the seam is missing.** Add the seam — a defaulted parameter leaves
  production call sites unchanged. If the seam is genuinely out of scope, say so explicitly.

## The acceptance filter

Every test clears all ten before it counts.

1. It compiles and passes.
2. **It fails when the code is wrong.** Break the line the test claims to cover, confirm the test
   fails, restore it, confirm the diff over source is empty. Non-negotiable for anything involving
   timing, callbacks, or polling. A test that passes against broken code is worse than no test — it
   buys false confidence.
3. **No access widening.** Never loosen visibility to reach something. Drive the type through its
   real seam. If the behavior is unreachable that way, that is a design finding to report, not a
   reason to widen.
4. **No tautologies.** Asserting a constant, asserting non-nil when the content is the point, or
   re-asserting what the previous line already proved.
5. It lives in the target that owns the code under test.
6. It runs in parallel with the rest of the suite.
7. It stays green across three consecutive runs.
8. **No sleep, and no bumped timeout, to paper over a race.** Propose the injected clock or
   scheduler seam instead, and say plainly if that is the only real fix.
9. **No weakened assertion** — equality downgraded to non-nil — because it was failing.
10. **No production-only hook** that exists solely for the test.

## Stack-specific conventions

Framework APIs, assertion shapes and concurrency-test mechanics live in the matching stack skill —
for Swift, `kit:swift-testing`.

## Never do these to make a test pass

- Add a sleep or raise a timeout to hide a race.
- Weaken an assertion because it is failing.
- Delete a failing test, or mark it as a known issue, without explaining why the failure is not a bug.
- Widen access, or add a production hook that exists only for tests.

Each of these converts a real signal into a false green. The failing test was doing its job.

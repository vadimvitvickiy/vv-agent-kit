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

## Write the test first

Write the test before the code whenever you can, and watch it fail for the reason you expect — the
behavior missing, not a typo or an import error. A test written after the code passes on its first
run, which proves nothing about whether it can fail, and it checks the cases you remembered while
writing the code rather than the ones the behavior needs. Then write the least code that passes, and
refactor only while green.

When the code came first, the second item of the acceptance filter below — break the line, watch
the test fail — is the proof that test-first would have given you. It is not optional in either
order.

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
- **Dropping to unit because the seam is missing.** Add the seam by moving construction out to the
  caller, so the test and production paths are the same path — `vvkit:injecting-dependencies`. If
  the seam is genuinely out of scope, say so explicitly.

**The database is not an edge to fake with a different engine.** An in-memory stand-in for another
engine — SQLite for Postgres — accepts queries, constraints and locking the production engine
rejects, so the test passes on exactly the code that fails in production. Run the real engine in a
container or a throwaway instance, or fake the repository interface above it and cover its queries
in a test that does run the real engine.

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
5. It lives in the test target, module or package that owns the code under test.
6. It runs in parallel with the rest of the suite — or, where it shares a real resource such as a
   database, it is marked serial and the reason is stated beside it.
7. It stays green across three consecutive runs.
8. **No sleep, and no bumped timeout, to paper over a race.** Wait for the condition the test cares
   about, not for a duration. Where there is no condition to wait on, propose the injected clock or
   scheduler seam, and say plainly if that is the only real fix. A test of timing itself — a
   debounce, a throttle — states why its interval is what it is.
9. **No weakened assertion** — equality downgraded to non-nil — because it was failing.
10. **No production-only hook** that exists solely for the test.

## What a test asserts

Before writing the body, name the production change that should make the test fail, and check that
it is a bug rather than a decision.

- **Derive the expected value by hand.** A literal or a hand-checked fixture. An expectation computed
  by the code under test, or by its helpers, passes whatever that code does.
- **No change detectors.** A test that only an intentional change can fail — a constant's value,
  exact message wording, private structure — fires on every redesign and sleeps through every bug.
  Test the behavior that depends on the decision: not that the retry limit is 5, but that the sixth
  attempt never happens.
- **Test your contract, not the framework's.** The route you register, the query you emit, the
  payload you produce. That a router calls a registered handler is its maintainers' test.
- **Never assert on a double.** An assertion that passes when the fake is present and fails when it
  is absent says nothing about the component.
- **Fake at the right level.** Learn every side effect of the real method before replacing it; fake
  the slow or external layer below the effects the test depends on. A fake that swallows a write
  the code under test later reads makes the test pass while production breaks.
- **Mirror real data completely.** A fixture with only the fields the test reads fails silently the
  day downstream code reads one more.
- **Make doubles specific** when arguments, counts or order are part of the contract. A fake that
  accepts anything verifies nothing.

When the setup for fakes outgrows the test itself, switch to a component test with real
collaborators.

**The mutation check.** Before finishing, mentally mutate the code: a wrong constant or argument, the
wrong branch, a missing side effect, an empty return, no validation for empty, zero, nil, unauthorized
or malformed input. Each realistic mutation should fail at least one test. One that fails nothing
marks behavior nobody protects.

## Stack-specific conventions

Framework APIs, assertion shapes and concurrency-test mechanics live in the matching stack skill —
for Swift, `vvkit:swift-testing`.

## Never do these to make a test pass

- Add a sleep or raise a timeout to hide a race.
- Weaken an assertion because it is failing.
- Delete a failing test, or mark it as a known issue, without explaining why the failure is not a bug.
- Widen access, or add a production hook that exists only for tests.

Each of these converts a real signal into a false green. The failing test was doing its job.

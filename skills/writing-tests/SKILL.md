---
name: writing-tests
description: Use when adding or changing behavior, fixing a bug, or judging whether an existing or generated test earns its place.
---

# Writing tests

**A behavior change ships with a test that fails when the change is undone — and with no test that
cannot name the bug it catches.** Both halves bind. A green suite proves nothing broke; it says
nothing about whether the new code is exercised. Volume is the opposite failure: agents asked for a
well-tested change produce dozens of tests that restate the code, and every one of them makes the
next refactor more expensive.

## Before writing a test

Answer all three, or do not write it:

1. **Which bug does it catch?** A plausible one-line mistake a refactor or a wrong fix could
   introduce — not "someone deletes the function". Check it is a bug, not a decision.
2. **What ships broken if it is deleted?** If another test or the compiler would already fail, it
   is redundant.
3. **Does it survive a refactor that keeps behavior?** A test that breaks when internals move and
   the observable result does not is pinning the implementation.

## How many

- **One to three tests per behavior change.** Give the reason before writing a fourth. No cap for
  concurrency and ordering, persistence and recovery, or money and access gating — each
  interleaving that matters is its own behavior.
- **One owner per rule.** Test it once, at the lowest layer that owns it. A higher layer gets one
  wiring test, not a rerun of the rule's cases, unless it carries a transport or lifecycle risk of
  its own.
- **Tests that differ in one input are one parameterized test.**

Always required: a new type, function or case carrying logic; a changed branch, predicate, mapping
or constant that alters behavior; a race; persistence; money; **every bug fix**.

Not required — name the existing test or compiler check that would catch a mistake instead:

- Generated and vendored code; renames, moves, formatting, comments.
- Pure UI layout. Test the view-model mapping — that is where the logic is.
- Pure wiring: a one-line pass-through, a memberwise init, a property that restates a `switch`. A
  new or changed hand-off between components is not wiring — see Unit or component.

A change that is genuinely untestable is said to be, with the reason. Never skip silently.

## Order

**Write the test first** whenever you can, and watch it fail for the reason you expect — the
behavior missing, not a typo or an import error. A test written after the code passes on its first
run, which proves nothing about whether it can fail. When the code came first, break the line the
test covers and watch it fail (acceptance filter, item 2).

**A bug fix starts with the reproduction**, watched failing for the reported reason. If the fix came
first, stash it and run the test against the unfixed code: re-breaking the code afterwards tests
only your theory of the bug. Afterwards keep the test if it guards a regression nothing else covers,
fold it into a parameterized test as a row, or discard it if it was only a diagnostic — and say
which.

## Unit or component

A unit test discharges the rule only when the behavior lives inside one type. When the behavior *is*
the collaboration, the change ships a **component test**: real collaborators composed in-process,
faked only at the outer edges — network, clock, presentation. That applies to a new component (a
type that drives others through their interfaces), a substantial change to a hand-off (a new call,
changed ordering, a new gate or teardown path), and a bug fix that only reproduces with two real
collaborators running.

- **Faking a middle collaborator** is a unit test wearing a component test's name.
- **A missing seam is not a reason to drop to unit.** Move construction out to the caller —
  `vvkit:injecting-dependencies` — or say the seam is out of scope.
- **The database is not an edge to fake with a different engine.** SQLite standing in for Postgres
  accepts queries, constraints and locking the production engine rejects. Run the real engine, or
  fake the repository interface above it and cover its queries against the real engine.

## What a test asserts

- **Expected values are literals from the product rule**, with inputs on the rule's boundary. An
  expectation computed by the code under test, by its helpers, or by branching on the test's own
  parameters passes whatever that code does. A literal copied from running the code is a
  characterization test — say so, and check it against the rule. A literal that depends on locale
  or OS formatting tests the formatter; assert your input to it.
- **No change detectors.** A constant's value, exact wording, private structure, every intermediate
  emission, a grep over source, a copied export list — each fires on every redesign and sleeps
  through every bug. Test the behavior that depends on the decision: not that the retry limit is 5,
  but that the sixth attempt never happens.
- **Your contract, not the framework's.** The route you register, the query you emit. That a router
  calls a registered handler is its maintainers' test.
- **Fixtures mirror real data completely**, and never supply what the code under test should
  produce — a receipt, a callback order, a record at a path the store never writes.

## Doubles

- **Never assert on a double.** The mock returns X, the test asserts X came back: it passes with
  the component deleted.
- **Verify effects, not reads.** A write, delete, purchase, network mutation, analytics event or
  navigation — and "never called" for an irreversible one after a failure. A call count on a read
  fails on a harmless refetch and catches nothing, unless the test is about caching, single-flight
  or debounce.
- **A double controls scheduling, not semantics.** Parking a call or firing a callback synchronously
  is fine. A fake with its own retry rule, or one that evicts or encodes like the real type, makes
  the test check the fake — test the real type in an integration test.
- **Fake at the right level.** Learn every side effect of the real method first; a fake that
  swallows a write the code later reads passes while production breaks.
- **Specific where it matters.** When arguments, counts or order are the contract, the double
  checks them. An unstubbed real network or disk call fails the test loudly.
- **Extend the shared double before writing another.** A parameter that just needs *something* gets
  the shared fake or a relaxed mock; a test-local double names, in one line, the control the shared
  one lacks.

When the fake setup outgrows the test, switch to a component test with real collaborators.

## The acceptance filter

Every test clears all ten before it counts.

1. It compiles and passes.
2. **It fails when the code is wrong.** Break the line it covers, confirm red, restore, confirm the
   diff over source is empty. Restore by reversing your own edit — never `git checkout` or
   `git restore` the file, which also discards the uncommitted implementation. Non-negotiable for
   timing, callbacks and polling.
3. **No access widening** to reach something. Unreachable through the real seam is a design
   finding to report.
4. **No tautology:** a constant, non-nil when the content is the point, your own fixture's contents,
   waiting for X then asserting X (unless the assertion is wider), or what the previous line
   proved. A negative test fails at the guard it names, not an earlier one.
5. It lives in the test target, module or package that owns the code.
6. It runs in parallel, or is marked serial with the shared resource named beside it.
7. It stays green across three consecutive runs.
8. **No sleep and no bumped timeout to paper over a race.** Wait for the condition, or propose the
   injected clock or scheduler seam. A test of timing itself states why its interval is what it is.
9. **No weakened assertion, deleted test, or known-issue mark to get green** — unless you explain
   why the failure is not a bug. The failing test was doing its job.
10. **No production hook** that exists only for the test.

Before finishing, mutate the code in your head — a wrong constant, the other branch, a missing side
effect, an empty return, no check for empty, zero, nil, unauthorized or malformed input. A realistic
mutation that fails no test marks behavior nobody protects.

## Report

For each test added: its name and the bug it catches. Beyond three, the reason. For each behavior
left untested: the existing test or check that covers it. For a bug fix: kept, folded or discarded.

## Elsewhere

- Framework APIs and assertion shapes: the stack skill — for Swift, `vvkit-swift:swift-testing`.
- Deleting, merging or rewriting existing tests on purpose: `vvkit:pruning-tests`.

The budget, owner-layer and effect-only rules are adapted from sergdort's "Pragmatic Testing" agent
skill (gist, 2026), which takes its "enough over perfect" stance from Orta Therox's *A Pragmatic
Approach to iOS Testing* (github.com/orta/pragmatic-testing). The negative-test and fixture rules
are from OpenClaw's `test-audit` skill.

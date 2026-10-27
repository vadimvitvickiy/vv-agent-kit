---
name: writing-tests
description: Use when adding or changing behavior, fixing a bug, or judging whether an existing or generated test earns its place.
---

# Writing tests

**A behavior change ships with a test that fails when the change is undone — and with no test that
cannot name the bug it catches.** Both halves bind. Green proves nothing broke, not that the new code
runs. Volume is the opposite failure: dozens of tests restating the code, each making the next
refactor dearer.

## Before writing a test

Answer all three, or do not write it:

1. **Which bug does it catch?** A plausible one-line mistake a refactor or wrong fix could introduce —
   not "someone deletes the function". A bug, not a decision.
2. **What ships broken if it is deleted?** If another test or the compiler would fail, it is redundant.
3. **Does it survive a refactor that keeps behavior?** Breaking when internals move and the result
   does not means it pins the implementation.

## How many

- **One to three per behavior change.** Give the reason before a fourth. No cap for concurrency and
  ordering, persistence and recovery, money and access gating — each interleaving that matters is a
  behavior.
- **One owner per rule.** Test it once, at the lowest layer that owns it. A higher layer gets one
  wiring test, unless it adds a transport or lifecycle risk.
- **Tests differing in one input are one parameterized test.**
- **Always required:** a new type, function or case carrying logic; a changed branch, predicate,
  mapping or constant that alters behavior; a race; persistence; money; **every bug fix**.
- **Not required** — name the test or compiler check that covers it instead: generated and vendored
  code; renames, moves, formatting, comments; pure UI layout (test the view-model mapping); pure
  wiring — a pass-through, a memberwise init, a property restating a `switch`. A new or changed
  hand-off between components is not wiring.
- Genuinely untestable: say so, with the reason. Never skip silently, and never write a dishonest test
  instead.

## Order

- **Test first** whenever you can; watch it fail for the expected reason — the behavior missing, not a
  typo or import error. A test written after passes on its first run, which proves nothing.
- Code came first: break the line the test covers and watch it fail (filter item 2).
- **A bug fix starts with the reproduction**, failing for the reported reason. Fix came first: stash
  it and run the test on the unfixed code — re-breaking by hand tests only your theory. Then keep the
  test, fold it into a parameterized one, or discard a pure diagnostic — and say which.

## Unit or component

A unit test suffices only when the behavior lives in one type. When the behavior *is* the
collaboration, ship a **component test**: real collaborators in-process, faked only at the outer
edges — network, clock, presentation. That covers a new component that drives others, a substantial
hand-off change (new call, ordering, gate or teardown), and a bug that needs two real collaborators.

- **Faking a middle collaborator** is a unit test wearing a component test's name.
- **A missing seam is no reason to drop to unit.** Move construction to the caller —
  `vvkit:injecting-dependencies` — or say the seam is out of scope.
- **The database is not an edge to fake with another engine.** SQLite accepts what Postgres rejects.
  Run the real engine, or fake the repository interface and test its queries on the real engine.

## What a test asserts

- **Expected values are literals from the product rule**, with inputs on the rule's boundary. An
  expectation computed by the code under test, its helpers, or branching on the test's parameters
  passes whatever the code does. A literal copied from running the code is a characterization test —
  say so. A locale- or OS-formatted literal tests the formatter; assert your input to it.
- **No change detectors** — a constant's value, exact wording, private structure, every intermediate
  emission, a grep over source. Test what depends on the decision: not that the retry limit is 5, but
  that the sixth attempt never happens.
- **Your contract, not the framework's.** The route you register, the query you emit.
- **Fixtures mirror real data completely**, and never supply what the code under test should produce.

## Doubles

- **Never assert on a double.** Mock returns X, test asserts X: passes with the component deleted.
- **Verify effects, not reads** — writes, deletes, purchases, network mutations, analytics,
  navigation, and "never called" for an irreversible one after a failure. A call count on a read
  catches nothing, unless the test is about caching, single-flight or debounce.
- **A double controls scheduling, not semantics.** A fake with its own retry or eviction rule tests
  the fake.
- **Fake at the right level.** A fake that swallows a write the code later reads passes while
  production breaks.
- **Specific where it matters** — arguments, counts, order when they are the contract. An unstubbed
  real network or disk call fails loudly.
- **Extend the shared double before writing another**; a test-local one names the control the shared
  one lacks.
- Fake setup outgrowing the test: switch to a component test.

## The acceptance filter

Every test clears all ten.

1. It compiles and passes.
2. **It fails when the code is wrong.** Break the covered line, confirm red, restore, confirm the
   source diff is empty. Restore by reversing your edit — never `git checkout` or `git restore`, which
   discards the uncommitted implementation. Non-negotiable for timing, callbacks and polling.
3. **No access widening.** Unreachable through the real seam is a design finding.
4. **No tautology:** a constant; non-nil when the content is the point; your own fixture's contents;
   waiting for X then asserting X; what the previous line proved. **If it would still pass with every
   function returning nothing or empty, it tests nothing.** A negative test fails at the guard it
   names, not an earlier one.
5. It lives in the target, module or package that owns the code.
6. It runs in parallel, or is marked serial with the shared resource named.
7. It stays green across three consecutive runs.
8. **No sleep or bumped timeout over a race.** Wait for the condition, or propose an injected clock or
   scheduler. A timing test states why its interval is what it is.
9. **No weakened assertion, deleted test or known-issue mark to get green** — unless you explain why
   the failure is not a bug.
10. **No production hook** that exists only for the test.

Before finishing, mutate the code in your head — a wrong constant, the other branch, a missing side
effect, an empty return, no check for empty, zero, nil, unauthorized or malformed input. A realistic
mutation no test fails marks unprotected behavior. Where the project has mutation or coverage tools,
run them instead.

## Report

For each test added: its name and the bug it catches. Beyond three, the reason. For each behavior left
untested: the test or check that covers it. For a bug fix: kept, folded or discarded.

## Elsewhere

- Framework APIs and assertion shapes: the stack skill — for Swift, `vvkit-swift:swift-testing`.
- Deleting, merging or rewriting tests on purpose: `vvkit:pruning-tests`.

Budget, owner-layer and effect-only rules adapted from sergdort's "Pragmatic Testing" agent skill
(2026), after Orta Therox's *A Pragmatic Approach to iOS Testing*. Negative-test and fixture rules from
OpenClaw's `test-audit` skill.

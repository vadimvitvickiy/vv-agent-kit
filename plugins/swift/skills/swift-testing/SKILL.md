---
name: swift-testing
description: Use when writing or reviewing tests in Swift with the Swift Testing framework, including tests for concurrent or thread-shared state.
---

# Swift Testing

**REQUIRED BACKGROUND:** `vvkit:writing-tests` — when a test is required, the unit/component
distinction, and the acceptance filter are decided there. This file covers only the framework.

The stack is native Swift Testing: `@Test`, `@Suite`, `#expect`, `#require`, `confirmation`.

It does not cover XCTest. UI automation (XCUITest) is built on XCTest, and a suite already written
in XCTest stays in XCTest — two frameworks in one suite split setup, assertions and failure output
across two conventions. `vvkit:writing-tests` applies to both.

## Shape of a test

```swift
import Testing
@testable import ExampleFramework

@Suite("Mapper")
struct MapperTests {

    @Test("maps a paused item to the 2:1 shape")
    func mapsPausedShape() throws {
        let mapped = try #require(Mapper.map(.fixture()))
        #expect(mapped.shape == .twoToOne)
    }

    @Test("rejects every unsupported shape", arguments: [Shape.bar, .full])
    func rejectsUnsupported(shape: Shape) {
        #expect(Mapper.map(.fixture(shape: shape)) == nil)
    }
}
```

- **`@Suite` on a `struct`.** A fresh instance per test comes free. Use `final class` with `deinit`
  only when teardown has real side effects — temp files, database pools.
- **Setup goes in `init()`.** There is no `setUp` / `tearDown`.
- **Prefer `== true` / `== false` over a bare boolean.** `#expect(x == false)` prints
  `(x → true) == false`; `#expect(!x)` prints nothing useful when it fails.
- **`try #require(x)`** rather than asserting non-nil and then force-unwrapping.
- **`@Test(arguments:)` only for genuinely table-driven cases** — same body, different data. Do not
  parameterise cases whose assertions differ.
- **Pass input/expected pairs as one collection of case structs.** `arguments: inputs, expected`
  runs the cartesian product, so mismatched pairs fail; `zip` stops at the shorter list and silently
  drops an unpaired input. Cases run in parallel — add `.serialized` if they share state.
- **Name tests as human sentences** in the `@Test("…")` display name.

## `#expect` can silently assert nothing

```swift
#expect((model?.ads ?? []).isEmpty)      // asserts NOTHING
```

This compiles, runs, passes, and checks nothing. The macro rewrites it to a closure over a
non-optional receiver and discards the result. The only signal is a compiler warning
(`expression of type 'Bool?' is unused`) — and closely related expressions are hard errors instead,
so the compiler is not a reliable guard.

**Never feed `#expect` an expression that mixes optional chaining with a trailing closure or `??`.**
Hoist it first:

```swift
let ads = model?.ads ?? []
#expect(ads.isEmpty)
```

Treat any macro-expansion warning as a correctness failure, not lint noise. This is the single most
important item in this file: a test that asserts nothing is worse than a missing test, because it
reports as coverage.

## Making an async assertion land

Strictly in this order. Move down only when the tool above genuinely cannot express the assertion.

1. **Virtual time.** Inject a scheduler or clock the test controls. Deterministic and instant. If
   the type does not accept one, **propose that seam** — a missing seam is a design finding.
   For async/await code — task groups, timeouts, cancellation — the seam is a spy the test
   releases: `vvkit-swift:swift-testing-async`.
2. **`confirmation`.** For "this fires exactly N times", and for "must stay silent"
   (`expectedCount: 0`). Failure reads "confirmed 0 times, but expected 1" rather than a bare
   timeout.
3. **Polling.** Last resort, for genuinely wall-clock-bound work. Poll to *synchronise*, then assert
   in a separate `#expect` so the observed value is printed. For a non-nil wait, poll the predicate
   and unwrap with `try #require` afterwards. Scale deadlines with an environment knob rather than
   editing timeouts into tests.

## Running a subset: the name in the output is not the identifier

`@Suite("...")` and `@Test("...")` take a **display name**. It is what the test log prints and the
only name most readers ever see — and it is not what `-only-testing` matches. That takes the Swift
identifier: the type for a suite, the function including its parentheses for a test.

```swift
@Suite("Currency")            // display name — appears in the log
struct CurrencyTests {        // ← this is what -only-testing needs
    @Test("currency codes compare case-insensitively")
    func codeComparisonIgnoresCase() { ... }   // ← and this
}
```

| Scope | Identifier |
|-|-|
| Whole bundle | `AppTests` |
| One suite | `AppTests/CurrencyTests` |
| One test | `AppTests/CurrencyTests/codeComparisonIgnoresCase()` |

Copying the display name out of the log produces a filter that matches nothing, and **`xcodebuild`
then runs zero tests and exits 0** — nothing in the output says the name was never found. So a
subset run means something only if you **read the count**, and a test script that does not fail on
a zero count reports success for an empty filter on every run.

Where a suite is nested in a type, the path follows the types, not the display names. When in doubt,
take the identifier from the source rather than the log.

## Watchdogs

Swift Testing's `.timeLimit` **cannot catch a cooperative-pool deadlock.** It is minutes-only, and
it is implemented as a task group racing a sleep, relying on cooperative cancellation — a task
blocked on a lock never cancels, and the timeout task needs the same wedged pool in order to run.

A watchdog that works needs a dedicated non-cooperative thread. If the project has one, use it;
if it does not and you are testing lock-based code, that is worth adding once.

## Concurrency

Testing code that crosses a thread, queue, or isolation boundary — locks, dispatch queues, timers,
KVO or delegate callbacks, actors — is a different problem from making an async assertion land.

Shapes, the weakest-tool ladder, and the first-access trap: `references/concurrency.md`.

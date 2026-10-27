---
name: swift-testing
description: Use when writing or reviewing tests in Swift with the Swift Testing framework, including tests for concurrent or thread-shared state.
---

# Swift Testing

**REQUIRED BACKGROUND:** `vvkit:writing-tests` — when a test is owed, unit vs component, and the
acceptance filter. This covers only the framework: `@Test`, `@Suite`, `#expect`, `#require`,
`confirmation`.

Not XCTest. UI automation (XCUITest) is XCTest, and a suite already in XCTest stays there — two
frameworks in one suite split setup, assertions and failure output.

## `#expect` can silently assert nothing

```swift
#expect((model?.ads ?? []).isEmpty)      // asserts NOTHING
```

- This compiles, passes and checks nothing: the macro rewrites it to a closure over a non-optional
  receiver and discards the result. The only signal is a warning (`expression of type 'Bool?' is
  unused`); related expressions are hard errors, so the compiler is no guard.
- **Never feed `#expect` optional chaining mixed with a trailing closure or `??`.** Hoist it:

  ```swift
  let ads = model?.ads ?? []
  #expect(ads.isEmpty)
  ```

- **Treat any macro-expansion warning as a correctness failure.** A test asserting nothing reports as
  coverage — worse than a missing test.

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

- **`@Suite` on a `struct`** — a fresh instance per test. `final class` with `deinit` only for real
  teardown — temp files, database pools.
- **Setup in `init()`.** There is no `setUp` / `tearDown`.
- **`== true` / `== false` over a bare boolean** — `#expect(!x)` prints nothing useful on failure.
- **`try #require(x)`**, not a non-nil assertion then a force-unwrap.
- **`Equatable` state and result types**, so one `#expect(state == expected)` checks every field.
- **`@Test(arguments:)` only for table-driven cases** — same body, different data.
- **Input/expected pairs as one collection of case structs.** `arguments: inputs, expected` runs the
  cartesian product; `zip` silently drops an unpaired input. Cases run in parallel — `.serialized` if
  they share state.
- **Human-sentence display names** in `@Test("…")`.

## Making an async assertion land

In this order; move down only when the tool above cannot express it.

1. **Virtual time.** Inject a scheduler or clock the test controls. No seam: **propose one** — a
   design finding. For async/await — task groups, timeouts, cancellation — the seam is a spy the test
   releases: `vvkit-swift:swift-testing-async`.
2. **`confirmation`** for "fires exactly N times" and "stays silent" (`expectedCount: 0`). It fails
   with "confirmed 0 times, but expected 1", not a bare timeout.
3. **Polling**, last resort, for wall-clock work. Poll to *synchronise*, then assert in a separate
   `#expect` so the value prints. For non-nil, poll the predicate then `try #require`. Scale deadlines
   by an environment knob, not edited timeouts.

## Running a subset: the logged name is not the identifier

`@Suite("…")` / `@Test("…")` set a **display name** — what the log prints. `-only-testing` takes the
Swift identifier: the type for a suite, the function with parentheses for a test.

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

- A display name copied from the log matches nothing, and **`xcodebuild` runs zero tests and exits
  0.** Read the count; a test script that does not fail on zero reports success for an empty filter.
- Nested suites follow the type path, not display names. When in doubt, take the identifier from
  source.

## Coverage

`xcodebuild test -enableCodeCoverage YES …`, then `xcrun xccov view --report --json <bundle>.xcresult`
for per-function numbers. Without the flag the report is empty and nothing warns.

## Watchdogs

- **`.timeLimit` cannot catch a cooperative-pool deadlock.** It is minutes-only, a task group racing a
  sleep: a task blocked on a lock never cancels, and the timeout task needs the same wedged pool.
- A working watchdog needs a dedicated non-cooperative thread. Use the project's; testing lock-based
  code without one, add it once.

## Concurrency

Code crossing a thread, queue or isolation boundary — locks, dispatch queues, timers, KVO, delegate
callbacks, actors — is a different problem from landing an async assertion. Shapes, the weakest-tool
ladder and the first-access trap: `references/concurrency.md`.

---
name: swift-testing-async
description: Use when testing Swift async/await code — a task group, async let, a timeout race, a retry, or cancellation — or when a Swift test waits with Task.sleep, polling, or Task.yield for work in flight.
---

# Testing async/await code

**REQUIRED BACKGROUND:** `vvkit-swift:swift-testing` for the framework, `vvkit:writing-tests` for
whether a test is owed. State shared across locks, queues or callbacks rather than `await` is
`swift-testing`'s `references/concurrency.md`.

**Never synchronise on a guessed interval.**

- `Task.sleep`, a polling loop or a run of `Task.yield()` "to let the other task get there" guesses
  the scheduler. It flakes under parallel runs, cannot choose which racing operation wins, and is
  slow — 100 ms across a thousand tests is 100 s per run.
- Models reach for these by default. Code under test that calls `Task.sleep` or reads a clock is the
  missing seam: inject it — `vvkit:injecting-dependencies`.

## The technique: spies that report and wait

Every dependency whose timing decides the outcome — value source, sleep, clock — becomes a protocol
with a test spy that:

1. **Reports each call** on a stream the test reads with `nextCall()`, with the arguments.
2. **Suspends until released** — `respond(with: Result)` for a value source, `resume()` for a sleep.
3. **Exits on cancellation.** One that ignores it hangs the run.

A received call proves the operation got there; the test then picks which dependency proceeds, so each
ordering is its own deterministic test with no real time elapsing. A spy asserts the requested
duration (`sleepCall == .seconds(3)`) without waiting.

Reference spies on `AsyncStream`: `references/spies.md`. Copy the shape, adapt the signature.

## Shape of a test

One ordering per test:

```swift
@Suite(.timeLimit(.minutes(1)))
struct TimedLoaderTests {
    @Test("a value returned before the deadline wins")
    func valueBeforeTimeout() async throws {
        let provider = ValueProviderSpy()
        let sleep = SleepSpy()
        let sut = TimedLoader(provider: provider, sleep: sleep)

        async let loaded = sut.load(within: .seconds(3))

        // Both child tasks are running once both events arrive.
        let valueCall = try #require(await provider.nextCall())
        let sleepCall = try #require(await sleep.nextCall())
        #expect(valueCall == .value)
        #expect(sleepCall == .seconds(3))

        provider.respond(with: .success("loaded"))

        let value = try await loaded
        #expect(value == "loaded")
    }
}
```

| Scenario | After both call events arrive |
|-|-|
| Value wins | `provider.respond(with: .success(…))` |
| Timeout wins | `sleep.resume()`, then expect the timeout error |
| Dependency fails | `provider.respond(with: .failure(…))`, expect that exact error back |
| Caller cancels | cancel the task — see below |
| Only the result matters | `respond` **before** starting, skip `nextCall()`, plain `await` |

- Assert an `async let` error in `do`/`catch`; `#expect(throws:) { try await loaded }` does not
  compile — a closure cannot capture an `async let`.
- The loser's cancellation needs no assertion: a task group awaits every child, so a loader that forgot
  to cancel leaves it on its spy, and the time limit fails the test.

## Caller cancellation

`async let` cancels and awaits on scope exit. `Task { }` does neither: it does not inherit the test's
cancellation, and a `#require` throwing before `cancel()` leaves it waiting forever. Close both:

```swift
let loading = Task { try await sut.load(within: .seconds(3)) }
do {
    try await withTaskCancellationHandler {
        _ = try #require(await provider.nextCall())
        _ = try #require(await sleep.nextCall())

        loading.cancel()

        await #expect(throws: CancellationError.self) {
            try await loading.value
        }
    } onCancel: {
        loading.cancel()          // the time limit cancelled the test
    }
} catch {
    loading.cancel()              // a #require threw before cancel()
    _ = await loading.result
    throw error
}
```

## Time limits

- `.timeLimit(.minutes(1))` on the suite, so a call that never arrives fails instead of wedging the
  bundle. Minutes-only.
- **A time limit records a failure and requests cancellation; it stops nothing.** Swift Testing still
  waits for the function to return — hence spies that end on cancellation and the `onCancel`
  forwarding. A cooperative-pool deadlock defeats even this — Watchdogs in
  `vvkit-swift:swift-testing`.

## Spy rules that bite

- **Fresh spies per operation.** Cancellation ends the `AsyncStream` iteration; a reused sleep spy can
  then return *without* `resume()`, passing an ordering never driven. A retry after cancellation needs
  a spy that opens a new stream per call.
- **One waiter per stream.** `AsyncStream` traps when a second task awaits `next()`. The reference
  spies turn that into a named `preconditionFailure`; give each concurrent sleep its own spy.
- **A `.failure` response is consumed by one request.** The stream stays open, so the next call can
  succeed — what a retry test wants.

## Where this fits the ladder

A spy is the virtual-time rung of `swift-testing`'s ladder for async/await. `confirmation` is for *how
many times*, not *in what order*. Polling stays last, for genuinely wall-clock work.

Technique source: raska.io, "Stop Sleeping: Deterministic Tests for Concurrent Swift Code" (2026).

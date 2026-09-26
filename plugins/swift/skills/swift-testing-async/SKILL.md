---
name: swift-testing-async
description: Use when testing Swift async/await code — a task group, async let, a timeout race, a retry, or cancellation — or when a Swift test waits with Task.sleep, polling, or Task.yield for work in flight.
---

# Testing async/await code

**REQUIRED BACKGROUND:** `vvkit-swift:swift-testing` for the framework, and `vvkit:writing-tests`
for whether a test is owed. Code that shares state across locks, queues or callbacks rather than
`await` is covered by `swift-testing`'s `references/concurrency.md`, not here.

## Never synchronise on a guessed interval

`Task.sleep`, a polling loop, or a run of `Task.yield()` placed to "let the other task get there"
is a guess about the scheduler. Under a parallel test run the guess is wrong often enough to flake,
and it cannot pick *which* of two racing operations wins, so the ordering that matters goes
untested. It is also slow: 100 ms waits across a thousand tests is 100 seconds per run.

Models reach for these by default when given no example. If the code under test calls
`Task.sleep` or reads a clock itself, that is the missing seam — inject it (`vvkit:injecting-dependencies`),
do not wait it out.

## The technique: spies that report and wait

Replace every dependency whose timing decides the outcome — the value source, the sleep, the clock
— with a protocol, and give the test a spy for it. Each spy does three things:

1. **Reports each call** on a stream the test reads with `nextCall()`, carrying the arguments.
2. **Suspends until the test releases it** — `respond(with: Result)` for a value source,
   `resume()` for a sleep.
3. **Exits on cancellation.** A spy that ignores cancellation hangs the run; see Time limits.

A received call event is proof the operation reached that point. The test then chooses which
dependency proceeds, so each ordering is a separate, deterministic test with no real time elapsing.
A spy asserts on the requested duration (`sleepCall == .seconds(3)`) without waiting three seconds.

Reference implementations — a value-provider spy and a sleep spy on `AsyncStream`:
`references/spies.md`. Copy the shape and adapt it to the dependency's signature.

## Shape of a test

One ordering per test, readable top to bottom:

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

To assert an error from an `async let`, await it in `do`/`catch`. `#expect(throws:) { try await
loaded }` does not compile: a closure cannot capture an `async let`.

The losing child's cancellation needs no assertion of its own: a task group awaits every child
before returning, so a loader that forgot to cancel the loser leaves it waiting on its spy, and the
time limit fails the test.

## Caller cancellation

`async let` cancels and awaits unfinished work when its scope ends. `Task { }` does neither: it does
not inherit the test's cancellation, and if a `#require` throws before the test reaches `cancel()`
the task is left waiting on a spy forever. Both gaps need closing:

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

Put `.timeLimit(.minutes(1))` on the suite, so a call that never arrives fails the test instead of
wedging the bundle. It is minutes-only.

A time limit **records a failure and requests cancellation; it cannot stop anything.** Swift Testing
still waits for the test function to return. If a spy or the code under test ignores cancellation,
awaiting it keeps the whole run stuck after the limit fires. That is why every spy wait must end on
cancellation, and why an unstructured `Task` needs the `onCancel` forwarding above. For a
cooperative-pool deadlock, not even this helps — see Watchdogs in `vvkit-swift:swift-testing`.

## Spy rules that bite

- **Fresh spies per operation.** Cancelling a task ends the `AsyncStream` iteration it was waiting
  in. A sleep spy reused after the loader cancelled it can then return *without* `resume()` — the
  test passes an ordering it never drove. A retry that reuses a dependency after cancellation needs
  a spy that opens a new stream per call.
- **One waiter per stream.** `AsyncStream` traps at runtime when a second task awaits `next()`
  while one is already pending. The reference spies turn an overlapping `nextCall()` into a named
  `preconditionFailure`; for sleeps, give each concurrent sleep its own spy.
- **A `.failure` response is consumed by one request.** The stream stays open, so the same provider
  spy can succeed on the next call — which is what a retry test wants.

## Where the ladder in `swift-testing` fits

`swift-testing` orders async assertions virtual time → `confirmation` → polling. A spy is the
virtual-time rung for async/await: it is the seam. Use `confirmation` when the question is *how many
times* something fires, not *in what order*. Polling stays the last resort for work genuinely bound
to the wall clock, which a spy-driven dependency is not.

Technique source: raska.io, "Stop Sleeping: Deterministic Tests for Concurrent Swift Code" (2026).

# Reference spies

Two spies built on `AsyncStream`, compiling under Swift 6 strict concurrency. Adapted from raska.io,
"Stop Sleeping: Deterministic Tests for Concurrent Swift Code". Rename the protocols and the `Call`
cases to the dependency being replaced; keep the three behaviours — report, wait, exit on
cancellation.

## The seams

```swift
protocol ValueProviding: Sendable {
    func value() async throws -> String
}

// Replaces a direct Task.sleep so the test decides when the wait ends.
protocol Sleeping: Sendable {
    func callAsFunction(for duration: Duration) async throws
}
```

Production conformances forward to the real source and to `Task.sleep(for:)`.

## Value provider spy

Each `value()` call yields a call event, then waits for the next response. A response supplied
before the call is buffered until a call reads it, which is what lets a result-only test `respond`
first and skip `nextCall()`.

```swift
actor ValueProviderSpy: ValueProviding {
    enum Call: Equatable, Sendable {
        case value
    }

    enum Error: Swift.Error, Equatable {
        case finishedWithoutResponse
    }

    private var callIterator: AsyncStream<Call>.Iterator?
    private let callEvents: AsyncStream<Call>.Continuation
    private let responses: AsyncStream<Result<String, any Swift.Error>>
    private let responsesContinuation: AsyncStream<Result<String, any Swift.Error>>.Continuation

    init() {
        (responses, responsesContinuation) = AsyncStream.makeStream()
        let (stream, continuation) = AsyncStream<Call>.makeStream()
        callEvents = continuation
        callIterator = stream.makeAsyncIterator()
    }

    // Overlapping reads would trap inside AsyncStream; fail with a name instead.
    func nextCall() async -> Call? {
        guard var iterator = callIterator else {
            preconditionFailure("Only one nextCall() may be active at a time")
        }
        callIterator = nil
        defer { callIterator = iterator }
        return await iterator.next(isolation: self)
    }

    nonisolated func respond(with response: Result<String, any Swift.Error>) {
        responsesContinuation.yield(response)
    }

    func value() async throws -> String {
        callEvents.yield(.value)

        var iterator = responses.makeAsyncIterator()
        guard let response = await iterator.next() else {
            // nil means the waiting task was cancelled.
            try Task.checkCancellation()
            throw Error.finishedWithoutResponse
        }
        return try response.get()
    }
}
```

## Sleep spy

Reports the requested duration, then waits for `resume()`. Cancellation ends the wait with
`CancellationError`, as the real `Task.sleep` does.

```swift
actor SleepSpy: Sleeping {
    private var callIterator: AsyncStream<Duration>.Iterator?
    private let callEvents: AsyncStream<Duration>.Continuation
    private let progress: AsyncStream<Void>
    private let progressContinuation: AsyncStream<Void>.Continuation

    init() {
        (progress, progressContinuation) = AsyncStream.makeStream()
        let (stream, continuation) = AsyncStream<Duration>.makeStream()
        callEvents = continuation
        callIterator = stream.makeAsyncIterator()
    }

    func nextCall() async -> Duration? {
        guard var iterator = callIterator else {
            preconditionFailure("Only one nextCall() may be active at a time")
        }
        callIterator = nil
        defer { callIterator = iterator }
        return await iterator.next(isolation: self)
    }

    nonisolated func resume() {
        progressContinuation.yield(())
    }

    func callAsFunction(for duration: Duration) async throws {
        callEvents.yield(duration)
        // Each resume() token releases one sequential call.
        for await _ in progress {
            try Task.checkCancellation()
            return
        }
        // The stream ended, which cancellation does. Once it has, every later call on this
        // spy falls through here without a resume() — hence a fresh spy per operation.
        try Task.checkCancellation()
    }
}
```

## Limits

- One sleep at a time per `SleepSpy`. Concurrent sleeps each need their own.
- A spy whose wait was cancelled is spent. A retry test that reuses one dependency across a
  cancellation needs a spy that makes a new stream per call.
- Nothing here calls `finish()`. It is not needed: each test awaits the operation, and the
  operation cancels whatever child is still waiting on a spy.

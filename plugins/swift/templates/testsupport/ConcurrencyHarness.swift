import Foundation

/// Primitives for tests that exercise state reachable from more than one thread.
///
/// Ported from a harness built for a large SDK. Every choice here exists because the obvious
/// version broke something; the comments say which.

// MARK: - Scale knobs

/// Multiplies stress iteration counts. Set `TEST_STRESS_SCALE` to turn a nightly sweep up without
/// hard-coding a large count into a test the PR loop has to pay for.
public let stressScale: Double = {
    guard
        let raw = ProcessInfo.processInfo.environment["TEST_STRESS_SCALE"],
        let value = Double(raw),
        value > 0
    else {
        return 1
    }
    return value
}()

/// Gate for sweeps too slow for the normal loop: `@Test(.disabled(if: !longTestsEnabled, "..."))`.
public var longTestsEnabled: Bool { stressScale > 1 }

/// True when the test bundle is running under Thread Sanitizer.
///
/// A test that provokes a race *deliberately* — a negative control proving the naive path really
/// does lose updates — is a TSan finding by construction, and makes the sanitizer lane permanently
/// red. Gate those off with this, and say in the comment that the skip exists **because the test is
/// correct**, so nobody later "fixes" it as a flake.
public let threadSanitizerEnabled: Bool = {
    dlsym(UnsafeMutableRawPointer(bitPattern: -2), "__tsan_init") != nil
}()

// MARK: - Locked box

/// The only legal recorder for a value written off-thread.
///
/// A bare `var` mutated from a callback and read by the test body is itself a data race, and one
/// that surfaces as an unrelated flake rather than as the bug it is.
public final class LockedBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: Value

    public init(_ value: Value) {
        storage = value
    }

    public var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    @discardableResult
    public func withLock<Result>(_ body: (inout Value) -> Result) -> Result {
        lock.lock()
        defer { lock.unlock() }
        return body(&storage)
    }
}

// MARK: - Running off the cooperative pool

/// Runs a blocking call without parking a Swift Concurrency thread.
///
/// Blocking directly inside an `async` test body blocks a *cooperative pool* thread. On a machine
/// with fewer cores than the pool expects, doing that while also demanding more threads exhausts
/// the pool and wedges the whole bundle — with no failing test, just a hung run.
public func offCooperativePool<Value: Sendable>(
    _ body: @Sendable @escaping () -> Value
) async -> Value {
    await withCheckedContinuation { continuation in
        DispatchQueue.global().async {
            continuation.resume(returning: body())
        }
    }
}

// MARK: - Stress

/// Fans `body` out across real threads, `iterations` times, scaled by `stressScale`.
///
/// Note the hop to `DispatchQueue.global()` before `concurrentPerform`. `concurrentPerform` blocks
/// its caller until every iteration finishes; called straight from an async test that caller is a
/// cooperative-pool thread, so it parks one pool thread while demanding many more. Hopping first
/// keeps the real parallelism and gives the pool thread back.
///
/// **A passing stress loop proves the race did not reproduce in this run on this machine.** It is
/// evidence, never proof — and never a substitute for a forced interleaving when you can name the
/// schedule that breaks the code.
public func concurrentStress(
    iterations: Int,
    _ body: @Sendable @escaping (Int) -> Void
) async {
    let scaled = max(1, Int(Double(iterations) * stressScale))
    await withCheckedContinuation { continuation in
        DispatchQueue.global().async {
            DispatchQueue.concurrentPerform(iterations: scaled, execute: body)
            continuation.resume()
        }
    }
}

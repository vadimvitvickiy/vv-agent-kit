import Foundation
import Testing

/// Drives a *named*, deterministic schedule across concurrent blocks.
///
/// Reach for this before a stress loop. If you can name the interleaving that breaks the code, this
/// reproduces it every run and documents the window in the test itself — where a stress loop only
/// says "it did not reproduce this time".
///
/// ```swift
/// // Reader                      | Writer
/// // let item = registry.next()
/// // arrive("selected")          |
/// //                             | wait(for: "selected")
/// //                             | registry.record(other)
/// //                             | arrive("recorded")
/// // wait(for: "recorded")       |
/// // registry.record(item)       |   ← both recorded the same id
/// let schedule = Interleaving()
/// await schedule.run([
///     {
///         let item = registry.next()
///         schedule.arrive("selected")
///         schedule.wait(for: "recorded")
///         registry.record(item.id)
///     },
///     {
///         schedule.wait(for: "selected")
///         registry.record(other.id)
///         schedule.arrive("recorded")
///     }
/// ])
/// ```
public final class Interleaving: @unchecked Sendable {

    public static let defaultTimeout: TimeInterval = 5

    private let lock = NSLock()
    private var latches: [String: DispatchSemaphore] = [:]
    private let timeout: TimeInterval
    private let drops = LockedBox<[String]>([])

    public init(timeout: TimeInterval = Interleaving.defaultTimeout) {
        self.timeout = timeout
    }

    private func latch(_ name: String) -> DispatchSemaphore {
        lock.lock()
        defer { lock.unlock() }
        if let existing = latches[name] {
            return existing
        }
        let created = DispatchSemaphore(value: 0)
        latches[name] = created
        return created
    }

    /// Signals that `name` has been reached.
    public func arrive(_ name: String) {
        latch(name).signal()
    }

    /// Blocks until `name` is signalled, or the timeout elapses.
    ///
    /// Returns `false` on timeout rather than hanging forever — a dropped baton should fail the test
    /// by name, not wedge the bundle until CI kills it.
    @discardableResult
    public func wait(for name: String) -> Bool {
        let arrived = latch(name).wait(timeout: .now() + timeout) == .success
        if !arrived {
            drops.withLock { $0.append(name) }
        }
        return arrived
    }

    /// Runs every block concurrently on real threads and reports any dropped baton.
    ///
    /// Failures are recorded **after** the join, on the test's own task. `Issue.record` called from
    /// inside a `concurrentPerform` worker is attributed through a task-local those threads do not
    /// carry, so it goes nowhere.
    public func run(
        _ blocks: [@Sendable () -> Void],
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                DispatchQueue.concurrentPerform(iterations: blocks.count) { index in
                    blocks[index]()
                }
                continuation.resume()
            }
        }

        let dropped = drops.value
        if !dropped.isEmpty {
            Issue.record(
                "interleaving timed out waiting for: \(dropped.joined(separator: ", "))",
                sourceLocation: sourceLocation
            )
        }
    }
}

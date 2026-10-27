---
name: swift-concurrency
description: Use when writing or reviewing Swift code that shares state across threads, queues, or isolation domains — locks, lazy properties, mutable statics, caches, or a state store.
---

# Swift concurrency pitfalls

**REQUIRED BACKGROUND:** `vvkit:writing-tests` for when a test is required. Test shapes for these
hazards: `vvkit-swift:swift-testing` → `references/concurrency.md`.

Mistakes that shipped. Each is invisible from the file in front of you, and each has a measured cost.

## `lazy var` is not atomic

- Swift's `lazy` has **no synchronisation**. Threads racing first access each run the initialiser and
  can get *different* instances.
- Measured: 200 owners under contention produced **209 initialisations and 201 distinct objects** —
  shipped as a second timer and a reference count that never converged.
- Plain `lazy` only where every first-access path is provably single-threaded; elsewhere an atomic
  one-shot initialiser.
- **The window closes after first access**, which makes the obvious test useless — the first-access
  trap in `vvkit-swift:swift-testing`.

## A mutable `static var` is shared by every thread

- A bare `next += 1` reached from several initialisers handed out **duplicate ids**. Lock it, or make
  it immutable.
- Check-then-act is the same race:

  ```swift
  if let existing = Self.cached { return existing }
  Self.cached = make()          // two threads both get here, and both construct
  return Self.cached!
  ```

## Per-field locking does not compose

- Fields describing **one thing** go in one struct behind one lock or store — never a lock each.
  Per-field atomics served one rotation item to two consumers, and paired a nil user id with the
  previous user's session id.
- **A store makes each transition atomic, not a caller's sequence.** Two getters are two reads.
  Callers needing several fields coherently get **one** accessor that reads state once.
- **A transition never calls out** — a database read, a delegate, a subscription, or releasing the last
  reference to something whose teardown re-enters the store self-deadlocks a non-recursive lock.
  Resolve outside, write the result in. Two threads both resolving is usually the cheaper correct
  trade — comment it, so nobody pulls the call back inside.

## Read-modify-write is not one operation

`value = value + 1` on a shared subject, relay or property has a gap. Use a lock-protected box or an
atomic for counters.

## What counts as concurrency

- A lock, or a serial/barrier queue guarding state
- `Thread`, `DispatchGroup`, `DispatchSemaphore`
- `actor`, `nonisolated(unsafe)`, `@unchecked Sendable`, `Task.detached`
- A reactive chain observing or subscribing on a non-main scheduler
- State mutated from a timer, KVO, a notification, or a network or delegate callback not pinned to
  main

**Not** by itself: a chain created, observed and disposed on main. The trigger is cross-domain
reachability.

## `@unchecked Sendable` is a claim to justify

It silences the compiler; it makes nothing safe. Every use carries a comment naming the invariant —
which lock, which queue, which single-writer discipline. Cannot name it: the conformance is wrong.

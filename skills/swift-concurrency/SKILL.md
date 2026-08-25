---
name: swift-concurrency
description: Use when writing or reviewing Swift code that shares state across threads, queues, or isolation domains — locks, lazy properties, mutable statics, caches, or a state store.
---

# Swift concurrency pitfalls

Mistakes that have actually shipped. Each one is invisible from the file in front of you, and each
one has a measured cost rather than a theoretical one.

**REQUIRED BACKGROUND:** `kit:writing-tests` for when a test is required. Test shapes for these
hazards are in `kit:swift-testing` → `references/concurrency.md`.

## `lazy var` is not atomic

Swift's `lazy` has **no synchronisation**. Threads racing the first access each run the initialiser,
and each can be handed a *different* instance.

Measured on a real codebase: 200 owners under contention produced **209 initialisations and 201
distinct objects**. It shipped in a type whose lazily-created shared stream meant a second timer and
a reference count that could never converge.

Plain `lazy` is safe only where every first-access path is provably single-threaded. Anywhere else,
use an atomic one-shot initialiser.

**The window closes after the first access**, which is what makes the obvious test useless — see the
first-access trap in `kit:swift-testing`.

## An unsynchronised mutable `static var` is shared by every thread

A mutable static is process-global by definition. A bare `next += 1` reached from several
initialisers handed out **duplicate ids**. Guard it with a lock, or make it immutable.

The same applies to the check-then-act shape that looks harmless:

```swift
if let existing = Self.cached { return existing }
Self.cached = make()          // two threads both get here, and both construct
return Self.cached!
```

## Per-field locking does not compose

When two or more fields describe **one thing**, put them in a struct behind one lock or one store —
never behind a lock each.

Making every field individually atomic leaves the *pair* racy. That is exactly how a rotation served
one item to two consumers, and how a cache paired a nil user id with the previous user's session id.
One mutation per invariant makes the split state unrepresentable.

Two limits worth knowing before reaching for a store:

- **A store makes each transition atomic, not a caller's sequence of them.** Two separate getters are
  still two reads, and a write can land between them. If callers must see several fields coherently,
  expose **one** accessor that reads the state once and returns what they need. Adding a store does
  not buy that by itself.
- **A transition must never call out.** Reading a database, invoking a delegate, subscribing, or
  releasing the last reference to something whose teardown re-enters the store will self-deadlock on
  a non-recursive lock. Resolve outside the transition and write the result in. Two threads both
  resolving is usually the cheaper, correct trade — say so in a comment, so nobody "tightens" it
  later by pulling the call back inside.

## Read-modify-write is not one operation

`value = value + 1` on a shared subject, relay, or property is a read and a write with a gap. Use a
lock-protected box or an atomic for counters.

## What counts as concurrency

Not just `async`/`await`. Treat all of these as first-class:

- A lock or a serial/barrier queue guarding state
- `Thread`, `DispatchGroup`, `DispatchSemaphore`
- `actor`, `nonisolated(unsafe)`, `@unchecked Sendable`, `Task.detached`
- A reactive chain observing or subscribing on a non-main scheduler
- State mutated from a timer, KVO, a notification, or a network or delegate callback not pinned to
  the main thread

**Not** a trigger by itself: a chain created, observed and disposed on the main thread. The trigger
is cross-domain reachability, not the presence of async machinery.

## `@unchecked Sendable` is a claim you must justify

It silences the compiler; it does not make anything safe. Every use needs a comment naming the
invariant that makes it true — which lock, which queue, which single-writer discipline. If you cannot
name it, the conformance is wrong.

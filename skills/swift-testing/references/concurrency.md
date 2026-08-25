# Concurrency testing

Read before writing a test for anything that crosses a thread, queue, or isolation boundary. When a
concurrency test is *required* is decided in `vvkit:writing-tests`. This file is **how** to write one.

The hazards themselves — non-atomic `lazy`, unsynchronised statics, non-composing per-field locks —
are catalogued in `vvkit:swift-concurrency`. This file is how to *test* for them.

Most concurrency hazard is not `async`/`await`. Dispatch queues used as guards, locks, reactive
schedulers, timers, KVO and delegate callbacks are all first-class concurrency — not the legacy case.
The trigger is **cross-domain reachability**, not the presence of async machinery.

## Pick the weakest tool that proves the bug

Only move down when the tool above genuinely cannot express the failure.

1. **A deterministic seam.** Inject a scheduler or clock and drive it manually. No threads, no
   flakes, runs in microseconds. If the type does not accept one, **propose the seam** — a missing
   seam is a design finding, not a licence to reach for a stress loop.
2. **A forced interleaving.** When you can *name* the schedule that breaks the code. Deterministic,
   and it documents the window.
3. **Stress.** Only when the failure is a lost update or torn read whose schedule you cannot name.

**A passing stress loop proves the race did not reproduce in this run on this machine.** It is
evidence, never proof. Never present a green stress test as proof of thread-safety.

## Seams a project needs

If these do not exist, they are worth building once — every shape below depends on them.

| Seam | Purpose |
|-|-|
| Manual scheduler | A manual-clock scheduler with `advance(by:)`, safe to schedule from any thread |
| Interleaving driver | Named latches for a forced schedule — arrive, wait, run |
| Bounded stress helper | Parallel fan-out, with a scale knob read from the environment |
| Locked box | The only legal recorder for a value written off-thread |
| Hang guard | Watchdog on a **dedicated** thread, so it survives a wedged cooperative pool |

## The five shapes

### 1. Forced interleaving — try this first

Name the schedule, drive it with latches, and write the schedule as a comment. Loop count 2–3;
there is nothing random to repeat.

```swift
// Reader                        | Writer
// let item = registry.next()
// arrive("selected")            |
//                               | wait(for: "selected")
//                               | registry.record(other)
//                               | arrive("recorded")
// wait(for: "recorded")         |
// registry.record(item)         |   ← both recorded the same id
let schedule = Interleaving()
await schedule.run([
    {
        let item = registry.next()
        schedule.arrive("selected")
        schedule.wait(for: "recorded")
        registry.record(item.id)
    },
    {
        schedule.wait(for: "selected")
        registry.record(other.id)
        schedule.arrive("recorded")
    }
])
#expect(registry.count(for: item.id) == 2)
```

A dropped baton should fail the test by name rather than hanging the bundle.

### 2. Lost update

N concurrent read-modify-writes; assert the final count is exactly N.

**Assert invariants inside the worker**, not only after the join. A post-hoc count says a write was
lost; an in-worker expectation says which one.

Pair every lost-update test with a **negative control** — a test proving the naive path really does
lose updates. That is what proves the test has teeth.

### 3. No-block / deadlock

Flood an accessor from a wide task group while another task writes. The assertion is that it
*completes*; the hang guard is the backstop.

### 4. Ordering under parallelism

Churn acquire/release from N threads and assert the observable sequence stays coherent — refcounts
converge, install and remove counts balance.

### 5. Re-entrancy

Provoke a callback fired from inside a critical section, and prove it does not run with the lock
held.

## Racing a *first* access — the trap that makes a stress test toothless

A one-shot hazard — a lazy property, a cached singleton, any initialise-once path — has a window
that closes after the first access.

Hammering **one** owner 1000 times tests the window once and the cached path 999 times. Such a test
**passes against the broken code**. This is not hypothetical: a lazy-initialisation test written
that way passed against a plainly non-atomic implementation.

Race the first access across **many owners**, and stride so that threads hitting one owner come from
different chunks. A `concurrentPerform`-style API gives each thread a *contiguous* range, so
adjacent indices run on the same thread and would serialise exactly what you are trying to race:

```swift
let owners = (0 ..< 200).map { _ in Owner() }
await concurrentStress(iterations: owners.count * 8) { index in
    let owner = owners[index % owners.count]      // `% count`, never `/ n`
    identities.withLock { $0.insert(ObjectIdentifier(owner.thing)) }
}
#expect(factoryRuns.value == owners.count)
#expect(identities.value.count == owners.count)
```

Give the factory some real work, too — one that returns instantly may never hold its window open
long enough for a second thread to enter. Rewritten this way, the same test caught the bug
immediately: 209 initialisations and 201 distinct instances for 200 owners.

## Non-async/await specifics

- **A reactive chain crossing a scheduler:** inject and drive a manual scheduler. Subscribing on a
  real background scheduler and polling is a stress test wearing a determinism costume.
- **Queue-guarded state:** hammer the public API. The queue is the unit under test — do not reach
  inside it.
- **Timers, KVO, notifications, delegate callbacks:** fire the trigger from a background queue and
  record into a locked box, never a bare `var`. A `var` mutated by a subscription and read by a poll
  is itself a data race, and a fresh class of flake.
- **`value = value + 1` on a shared subject is not atomic.** It is a read-modify-write across two
  separately-locked operations. Use a locked box for counters.

## Iteration counts

There is **no published guidance** on how many iterations a race needs to surface. Treat any
specific number as convention, not science. Put the scale behind an environment knob so the nightly
can turn it up and the PR loop does not pay for it.

Gate anything genuinely slow rather than shrinking it.

## Under Thread Sanitizer

Every new concurrency test should go green under TSan at least once.

- **A deliberate-race test must be gated off under TSan**, or it makes the lane permanently red — it
  is a TSan finding by construction. Say in the comment that the skip exists *because the test is
  correct*, so the next reader does not "fix" it as a flake.
- **Treat a TSan report near `await`, an actor hop, or a continuation as suspect until reproduced.**
  False positives around Swift Concurrency are reported and unresolved upstream. Reports in
  lock, queue and reactive code are the well-attested case.
- TSan detects races from happens-before relationships, not repetition. Run it at stress scale 1;
  extra iterations only cost time.

## Never

- **Prove thread-safety with a single-threaded test.** One call from the test's own task says
  nothing about isolation.
- **Quiet a flaky concurrency test by lowering iterations or adding a sleep.** Intermittent failure
  is the test working — it found a race. Fix the race.
- **Record an issue from inside a stress or interleaving block.** Swift Testing attributes issues
  through a task-local those threads do not carry, so it goes nowhere. Record into a locked box and
  assert after the join.
- **Add a production-only hook to make an interleaving reachable.** Drive the real seam, or report
  the design finding.

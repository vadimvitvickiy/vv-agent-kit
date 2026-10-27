---
name: injecting-dependencies
description: Use when writing a constructor or initialiser, when a type needs a collaborator to do its work, or when adding a parameter so something can be swapped in a test.
---

# Injecting dependencies

**A complex collaborator is a required parameter.** Services, engines, controllers, coordinators,
repositories, clients — whoever configures the object supplies them, not the object itself.

- Defaults are for simple leaves: a scheduler, a clock, a timer source, a formatter — no
  dependencies of their own, and the default is the answer rather than a guess.

## The sentinel default is the anti-pattern

```
init(engine: Engine? = nil) {
    self.engine = engine ?? Engine(...)     // ← this
}
```

`nil` here means "construct it yourself" — the one thing the parameter existed to prevent.

- **The dependency is invisible.** Nothing at the call site says this type needs an `Engine`.
- **Two construction paths.** Production takes one, tests the other, so the shipped path is the least
  exercised.
- **The default outlives its reason**, and nothing fails when it stops being right.
- **The constraint is the signal.** A default that would need another parameter's value to build is
  the language saying the object cannot construct this itself. Pass it in.

## Move construction, do not add an escape hatch

- When a test needs to see something a type builds internally, move the construction to the call
  site. Do not add a parameter only tests use — the test then verifies the path nobody ships.
- Move the `new`/`init` to whoever already decides how the object is configured; test and production
  become one path.

## Two parameters that must be one instance

When two collaborators must share the identical object — a cache for a reader and a writer, a session
for two clients — bind it to a local at the call site and pass it to both:

```
let session = Session(...)
let reader = Reader(session: session)
let writer = Writer(session: session)
```

The sharing is visible where it is established. Constructing twice, or documenting the requirement in
a comment, leaves it for a refactor to break silently.

## What this buys

- Every dependency in the signature is one a reader sees, a test replaces and a change traces.
- Wiring moves out to a composition point — where that knowledge belongs.
- **A parameter list that feels too long is information:** the type has too many responsibilities.
  Defaults hide the evidence, not the responsibilities.

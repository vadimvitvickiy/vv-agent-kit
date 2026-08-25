---
name: injecting-dependencies
description: Use when writing a constructor or initialiser, when a type needs a collaborator to do its work, or when adding a parameter so something can be swapped in a test.
---

# Injecting dependencies

**A complex collaborator is a required parameter.** Services, engines, controllers, coordinators,
repositories, clients — whoever configures the object supplies them. Not the object itself.

Defaults are for the simple ones: a scheduler, a clock, a timer source, a formatter. Things with no
dependencies of their own, where the default is genuinely the answer rather than a guess.

## The sentinel default is the anti-pattern

```
init(engine: Engine? = nil) {
    self.engine = engine ?? Engine(...)     // ← this
}
```

That `nil` does not mean "no engine". It means *"construct the default yourself"*, which is the one
thing the parameter existed to prevent. The type still secretly builds what it depends on; the
signature now merely lies about it.

What it costs:

| | |
|-|-|
| The dependency is invisible | Nothing at the call site says this type needs an `Engine`, so nobody knows to look when the wrong one is used |
| Two construction paths | Production takes one branch and tests take the other, so the path that ships is the one least exercised |
| The default outlives its reason | It was correct once. Nothing forces anyone to revisit it, and nothing fails when it stops being correct |

**The constraint is the signal.** If the default would need another parameter's value to build — and
most languages cannot reference one parameter from another's default — that is not an obstacle to
work around. It is the language telling you the object cannot construct this itself. Pass it in.

## Move construction, do not add an escape hatch

When a type builds something internally and a test needs to see it, the fix is to move the
construction to the call site, not to add a parameter that exists only for tests.

An injection point added *for testing* is a second way to build the object, and the production path
never uses it. What the test then verifies is the path nobody ships. Move the `new`/`init` out to
whoever is already deciding how this object is configured, and the test and production paths become
the same path.

## When two parameters must be the same instance

Passing collaborators in can create an invariant *across* parameters: two of them must receive the
identical object, not merely equal ones. A cache shared by a reader and a writer, a session shared
by two clients.

Bind it to a local at the call site and pass that local to both:

```
let session = Session(...)
let reader = Reader(session: session)
let writer = Writer(session: session)
```

The sharing is now visible in the code that establishes it. The alternative — constructing it twice
and hoping they match, or documenting the requirement in a comment — makes the invariant something a
reader has to reconstruct, and something a refactor can silently break.

## What this buys

Every dependency named in the signature is one a reader can see, a test can replace, and a change
can trace. The cost is that wiring moves outward, to a composition point that has to know how the
pieces fit — which is where that knowledge was supposed to live.

If the parameter list has grown uncomfortable, that is information: the type has taken on more
responsibilities than one type should. Hiding the parameters behind defaults does not reduce the
responsibilities, only the evidence of them.

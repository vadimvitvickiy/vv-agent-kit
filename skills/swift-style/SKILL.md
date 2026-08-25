---
name: swift-style
description: Use when creating or editing a Swift type — member ordering, file layout, and choosing between guard and if.
---

# Swift style

**REQUIRED BACKGROUND:** `vvkit:writing-comments` — comment limits and doc-comment rules live there and
are not repeated here.

## Canonical member order

One layout, top to bottom, for every type:

1. File header comment, then imports
2. File-private free-standing helpers — error enums, option sets, small structs (optional)
3. The type declaration, with a type-level `///` overview
4. Nested types — private enums and structs for internal state, near the top of the body
5. **Injected dependencies** — `private let`, assigned in `init` — **before** `init`
6. `init`, then `deinit`
7. **Private stored state** — caches, flags, counters — **after** `init`
8. Public methods and public computed properties
9. Private methods
10. Extensions at the bottom, one per protocol conformance

The relative order is the hard rule. Use `// MARK: -` dividers on any non-trivial type.

**The one non-obvious part: dependencies precede `init`, working state follows it.** A reader
scanning the top of a type sees everything it was handed; everything below `init` is what it built
for itself. That split is why this order is worth following rather than sorting members by
visibility alone.

## Annotated example

```swift
//
//  ExampleService.swift
//

import Foundation

/// Owns example fetching and caching for a single session.
/// A type-level overview may run several lines to orient the reader.
final class ExampleService: ExampleServicing {

    // MARK: - Types

    private enum State {
        case idle
        case loading
    }

    // MARK: - Dependencies

    private let api: ExampleAPI
    private let clock: Clock

    // MARK: - Init

    init(api: ExampleAPI, clock: Clock) {
        self.api = api
        self.clock = clock
    }

    // MARK: - State

    private var state: State = .idle
    private var cache: [String: ExampleItem] = [:]

    // MARK: - Public Methods

    func start() async {
        state = .loading
        await fetch()
    }

    var itemCount: Int {
        cache.count
    }

    // MARK: - Private Methods

    private func fetch() async {
        // ...
    }
}

// MARK: - ExampleFeedListener

extension ExampleService: ExampleFeedListener {

    func feedDidUpdate(_ items: [ExampleItem]) {
        // ...
    }
}
```

## Section labels

`Types` · `Dependencies` (or `Properties`) · `Init` · `State` · `Public Methods` (or `Public API`) ·
`Private Methods` · `Configuration` · `Debug`

Suffix a private section by topic when a file grows: `// MARK: - Private Methods - Queue Management`.

## Extensions and conformance

- One `extension` per protocol conformance, at the bottom, labelled `// MARK: - <ProtocolName>`.
- The type's primary defining protocol may sit inline on the type signature. Secondary delegate
  conformances go in extensions.

## `guard` or `if`

- **Prefer `if` / `else` for top-of-function branching when both branches carry real logic.** Both
  paths then read at the same indentation, instead of one being buried in a `guard` body.
- **Keep `guard let x else { … }` for optional unwraps.** That is the idiom, and `if let` pyramids
  are worse.
- The same applies inside small closures with two return arms.
- **Sequential `if condition { return value }` cascades are fine.** They act as a pseudo-switch — do
  not force them into an `else-if` tree.

## Formatting

- Prefer readable multi-line bodies over one-liners. Keep `if` / `guard` / `else` bodies on their own
  lines; do not collapse `{ return x }` onto one line because you can. A short expanded block is
  easier to audit than a dense one.
- Indentation width and line length are project settings — follow the project, not this file.

## Carve-outs

- **Singletons:** `static let shared` and `private init() {}` sit at the very top of the type body.
- **Static-namespace types** with no dependencies and no `init`: the dependency/init ordering does not
  apply. Group static members logically with MARKs.

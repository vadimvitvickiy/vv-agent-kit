---
name: swift-style
description: Use when creating or editing a Swift type — member ordering, file layout, and choosing between guard and if.
---

# Swift style

**REQUIRED BACKGROUND:** `vvkit:writing-comments` — comment limits and doc-comment rules.

**Where the project has a convention, follow the project.** A diff that reorders existing members to
a house style the file never used is noise. What follows is the default for new code.

## Member order

1. File header comment, then imports
2. File-private free-standing helpers — error enums, option sets, small structs (optional)
3. The type declaration, with a type-level `///` overview
4. Nested types — private enums and structs for internal state
5. **Injected dependencies** — `private let`, assigned in `init` — **before** `init`
6. `init`, then `deinit`
7. **Private stored state** — caches, flags, counters — **after** `init`
8. Public methods and public computed properties
9. Private methods
10. Extensions at the bottom, one per protocol conformance

- The relative order is the hard rule. `// MARK: -` dividers on any non-trivial type.
- **Dependencies precede `init`, working state follows it:** the top shows what the type was handed,
  below `init` what it built for itself.

## Example

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

## Sections and extensions

- Labels: `Types` · `Dependencies` (or `Properties`) · `Init` · `State` · `Public Methods` (or
  `Public API`) · `Private Methods` · `Configuration` · `Debug`.
- Suffix by topic as a file grows: `// MARK: - Private Methods - Queue Management`.
- One `extension` per conformance, at the bottom, labelled `// MARK: - <ProtocolName>`. The primary
  defining protocol may sit on the type signature; secondary delegate conformances go in extensions.

## `guard` or `if`

- **`if` / `else` at the top of a function when both branches carry real logic** — both read at the
  same indentation. Same inside small closures with two return arms.
- **`guard let x else { … }` for optional unwraps.** `if let` pyramids are worse.
- **Sequential `if condition { return value }` cascades are fine** — a pseudo-switch; do not force an
  `else-if` tree.

## Formatting

- Multi-line bodies over one-liners. `if` / `guard` / `else` bodies on their own lines; do not collapse
  `{ return x }`.
- Indentation and line length are project settings.

## Carve-outs

- **Singletons:** `static let shared` and `private init() {}` at the very top of the body.
- **Static-namespace types** with no dependencies or `init`: group static members logically with MARKs.

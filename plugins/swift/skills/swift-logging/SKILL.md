---
name: swift-logging
description: Use when adding or reviewing logging in Swift code with os.Logger or an equivalent logging facade.
---

# Swift logging

**REQUIRED BACKGROUND:** `vvkit:writing-logs` — placement, levels and what not to log. This covers
only the Swift specifics.

## Declaring a logger

One `Logger` per type, with subsystem and category:

```swift
import OSLog

private let log = Logger(subsystem: "com.example.app", category: "ExampleService")
```

- Subsystem: the bundle identifier, constant across the module.
- Category: the 3am filter — reuse the one the file already declares.

## Privacy annotations

`os.Logger` redacts dynamic strings by default and shows numerics in the clear. Be explicit:

```swift
log.debug("loaded account \(id, privacy: .public)")
log.error("auth failed: \(error.localizedDescription, privacy: .private)")
log.info("user \(email, privacy: .sensitive)")
```

- `.public` — safe in a sysdiagnose: identifiers, counts, state names.
- `.private` — redacted in release; the default for interpolated strings.
- `.sensitive` — credentials and personal data. Prefer not logging it.
- **A numeric interpolation is public by default** — an account id, amount or timestamp is already in
  the clear.

## Levels

- `Logger` has `trace`, `debug`, `info`, `notice`, `warning`, `error`, `fault`. `notice` is the
  persisted default; `fault` is programmer error, not a failed network call.
- **`debug` and `trace` are not persisted** without a live stream. Anything needed in a bug report is
  `info` or above.

## Availability

`Logger` needs iOS 14 / macOS 11; below that, `os_log`. Put the `#available` check in one small
facade, not at every call site.

## Checklist

- [ ] Every interpolation has a considered privacy annotation
- [ ] Anything needed in a bug report is `info` or above, not `debug`

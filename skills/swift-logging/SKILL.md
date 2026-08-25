---
name: swift-logging
description: Use when adding or reviewing logging in Swift code with os.Logger or an equivalent logging facade.
---

# Swift logging

**REQUIRED BACKGROUND:** `vvkit:writing-logs` — where a log belongs, which level to choose, and what
not to log are decided there. This file covers only what is Swift-specific.

## Declaring a logger

One `Logger` per type, with a subsystem and a category:

```swift
import OSLog

private let log = Logger(subsystem: "com.example.app", category: "ExampleService")
```

The subsystem is the bundle identifier and is constant across the module. The **category** is the
filter someone reaches for at 3am — make it the type name.

**Match the category the file already uses.** Scan for an existing declaration and reuse it. Only
when a file has no logger at all, fall back to the enclosing type name. Two categories for one file
fragments the filter, which defeats the point of having one.

## Privacy annotations

`os.Logger` redacts dynamic strings by default and shows numerics in the clear. Both defaults will
surprise you, so be explicit whenever it matters:

```swift
log.debug("loaded account \(id, privacy: .public)")
log.error("auth failed: \(error.localizedDescription, privacy: .private)")
log.info("user \(email, privacy: .sensitive)")
```

- `.public` — safe to appear in a sysdiagnose. Use for identifiers, counts, state names.
- `.private` — redacted in release. The default for interpolated strings.
- `.sensitive` — credentials and personal data. Prefer not logging it at all.

**A numeric interpolation is public by default.** An account id, an amount, or a timestamp logged
without thought is already in the clear.

## Levels

`Logger` exposes `trace`, `debug`, `info`, `notice`, `warning`, `error`, `fault`. Map the decision
table in `vvkit:writing-logs` onto these directly; `notice` is the persisted default and `fault` is for
programmer error, not for a failed network call.

Note that `debug` and `trace` are **not persisted** — they are dropped unless a live stream is
attached. Anything you need in a bug report must be `info` or above.

## Availability

`Logger` requires iOS 14 / macOS 11. Below that, `os_log` is the fallback. Rather than scattering
`if #available` at every call site, put the check inside one small logging facade and let call sites
stay clean.

## Checklist

- [ ] Category matches what the file already uses
- [ ] Every interpolation has a considered privacy annotation
- [ ] No credentials, tokens, or personal data at any level
- [ ] Anything needed in a bug report is `info` or above, not `debug`

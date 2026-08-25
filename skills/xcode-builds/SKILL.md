---
name: xcode-builds
description: Use when building, compile-checking, running tests, driving a simulator, or reading build and runtime output for an Xcode project.
---

# Xcode builds

**REQUIRED BACKGROUND:** `kit:verifying-changes` — what to run and when to sweep is decided there.
This file covers how to run it.

## Prefer the project's own script

If the repo ships a build or test script, use it. Hand-written `xcodebuild` invocations miss what the
script carries: the shared derived-data path, toolchain workarounds, and the flags that keep the
build cached. A hand-rolled command that "works" often works by doing a clean build, which is why it
takes eight minutes.

Where the project records its commands: `.claude/context/`, surfaced by a table in `CLAUDE.md`.

Never hand-write `xcrun` or `simctl` when the project wraps them.

## When there is no script

Compile-check without signing:

```bash
xcodebuild -project <Project>.xcodeproj -scheme <Scheme> -configuration Debug \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

Discover what exists rather than guessing:

```bash
xcodebuild -list -project <Project>.xcodeproj      # schemes, targets, configurations
xcrun simctl list devices available                # booted and bootable simulators
```

`-destination 'generic/platform=iOS'` compiles without needing a simulator to boot. Use a concrete
destination only when you actually need to run.

## Read the result bundle, not the log

On failure, read the `.xcresult` rather than grepping console output:

```bash
xcrun xcresulttool get --format json --path <path>.xcresult
```

Raw build logs bury one failure among thousands of progress lines, and grepping for `error`
reliably finds the wrong ones — warnings-as-text, paths containing the word, and the summary line.

## What a green build does not tell you

- **Incremental builds keyed on source fingerprints can skip a resource-only change.** Editing an
  asset catalog or a strings file may produce a cached "success" that never re-ran the generator.
- **A test filter with a typo'd identifier runs zero tests and exits 0.** Read the executed count,
  never the exit code alone.
- **A scheme can exclude the target you changed.** Building the app scheme does not necessarily
  build every framework in the project.

When you rely on a cached or filtered run, say so rather than reporting it as full coverage.

## Generated project files

If the `.xcodeproj` is generated — from a project manifest, or by a generator tool — **never edit it
directly**. Edit the manifest and regenerate. An edit to a generated file survives until the next
generation and then vanishes, usually without anyone noticing which change was lost.

If the `.xcodeproj` is hand-managed, still never edit `project.pbxproj` as text. Use a library that
understands the format; the file is a graph of cross-referenced UUIDs and a hand edit corrupts it in
ways that surface much later.

## The xcodebuildmcp CLI

When the project uses it, or when driving simulators and UI automation:
`references/xcodebuildmcp.md`.

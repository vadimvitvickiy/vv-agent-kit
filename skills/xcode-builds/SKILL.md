---
name: xcode-builds
description: Use when building, compile-checking, running tests, driving a simulator, or reading build and runtime output for an Xcode project.
---

# Xcode builds

**REQUIRED BACKGROUND:** `vvkit:verifying-changes` — what to run and when to sweep is decided there.
This file covers how to run it.

## Always prefer the project's script

If the repo has `scripts/build.sh` or `scripts/test.sh`, use it. If it has none, generate them with
`vvkit:scripts` rather than hand-writing an invocation.

This is not a style preference. A hand-written `xcodebuild` command is usually slower by a large
multiple, and the reasons are invisible from the command line — see the table below. A hand-rolled
command that "works" frequently works by rebuilding everything.

Never hand-write `xcrun` or `simctl` when the project wraps them.

## The four traps in a hand-written invocation

Each measured on a large project:

| Trap | Cost |
|-|-|
| `-destination 'generic/platform=iOS Simulator'` | Resolves several architectures and evicts the shared cache slice every time you alternate with Xcode — 9,227 file compiles / 247s, versus 1,278 / 104s with a concrete simulator UDID |
| `CODE_SIGNING_ALLOWED=NO` | A build-setting override changes the build description. If Xcode builds the same DerivedData without it, the two evict each other — a 5,879-file rebuild on every switch. Simulator products need no signing anyway |
| `-derivedDataPath` on a routine build | Opts out of the cache the IDE is warming. Use it only for a deliberately isolated or reproducible build |
| `xcodebuild clean` | Discards the cache that makes everything else fast. The build system reads sources from disk every run; a clean buys no correctness |

Also worth knowing: two build configurations sharing one DerivedData ping-pong the generated module
maps, which are keyed by platform rather than configuration. Measured at 6m34s versus 1m14s. Point
every local entry point at the same configuration.

## Discovering what exists

```bash
xcodebuild -list -project <Project>.xcodeproj      # schemes, targets, configurations
xcrun simctl list devices available                # booted and bootable simulators
```

**`-list` sorts schemes alphabetically.** Taking the first one frequently selects a framework target
rather than the app, which compile-checks a dependency and reports success for the project. Pick the
scheme named after the project, or name it explicitly.

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

## Every tool that builds must agree on one cache

The trap table above is about flags you type. The same defect arrives silently through tools that
pick a build location for you: `xcodebuildmcp` defaults to a private store under its own directory,
and a Swift language server with no build config compiles against a target it guessed.

Both are the same failure — a second cache, cold, that nothing else reads — and neither reports it.
Bind them to Xcode's folder for the checkout before the first build. `scripts/setup-tooling.sh` does
both if the project has it.

| Tool | Unbound behavior | Symptom |
|-|-|-|
| `xcodebuildmcp` | Builds into `~/Library/Developer/XcodeBuildMCP/workspaces/` | Every build cold; a second multi-GB cache — 3.53 GB measured on one checkout |
| `sourcekit-lsp` | Falls back to a macOS target | `No such module 'UIKit'` on every file in an iOS framework |

For sourcekit-lsp specifically, `xcode-build-server config` binds the scheme and `xcode-build-server
parse` supplies the flags — **both** are needed. A command-line `xcodebuild` never writes the
`.xcactivitylog` the server watches (only the Xcode IDE does), so a bare `config` leaves it flagless
and it fails over to macOS without saying so.

## The xcodebuildmcp CLI

When the project uses it, or when driving simulators and UI automation:
`references/xcodebuildmcp.md`.

Do not work from a remembered tool list. The CLI ships its own agent skill (`xcodebuildmcp init`)
which is versioned with the binary, and workflow names change between releases.

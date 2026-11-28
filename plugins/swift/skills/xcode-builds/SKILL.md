---
name: xcode-builds
description: Use when building, compile-checking, running tests, driving a simulator, or reading build and runtime output for an Xcode project, or when a system feature misbehaves only on a simulator.
---

# Xcode builds

**REQUIRED BACKGROUND:** `vvkit:verifying-changes` — what to run and when. This covers how.

**Default to the project's scripts.** Use `scripts/build.sh` and `scripts/test.sh` for CI and
verification that needs predictable logs or result bundles. Pass `--summary` if the scripts
support it to see the result, failure diagnostics, and full log path. If the project lacks
scripts, scaffold them with `/vvkit:scripts`.

**Apple's Xcode MCP is an opt-in for repeated local builds and focused tests.** Use it when the
project allows it and the session has access to the intended workspace. See
[Apple's Xcode MCP](references/apple-xcode-mcp.md) for runner selection and verification.
Use project wrappers for raw `xcodebuild`, `xcrun`, and `simctl` operations they already cover.

## Four traps in a hand-written invocation

Each measured on a large project:

| Trap | Cost |
|-|-|
| `-destination 'generic/platform=iOS Simulator'` | Resolves several architectures and evicts the shared cache slice every time you alternate with Xcode — 9,227 file compiles / 247s, versus 1,278 / 104s with a concrete simulator UDID |
| `CODE_SIGNING_ALLOWED=NO` | A build-setting override changes the build description. If Xcode builds the same DerivedData without it, the two evict each other — a 5,879-file rebuild on every switch. Simulator products need no signing anyway |
| `-derivedDataPath` on a routine build | Opts out of the cache the IDE is warming. Even pointed at Xcode's own folder, it moves the module and compilation caches inside it, and every switch with Xcode recompiles everything — 26 of 26 files on an iOS app. Use it only for a deliberately isolated or reproducible build |
| `xcodebuild clean` | Discards the cache that makes everything else fast. The build system reads sources from disk every run; a clean buys no correctness |

Two configurations sharing one DerivedData ping-pong the generated module maps (keyed by platform, not
configuration) — 6m34s versus 1m14s. Point every local entry point at one configuration.

## Discovering what exists

```bash
xcodebuild -list -project <Project>.xcodeproj      # schemes, targets, configurations
xcrun simctl list devices available                # booted and bootable simulators
```

**`-list` sorts schemes alphabetically.** The first is often a framework, which compile-checks a
dependency and reports success for the project. Pick the scheme named after the project, or name it.

## Reading results

- Read test failures from the bundle with `xcrun xcresulttool get test-results summary --path <path>.xcresult`.
- **A full disk does not look like one** — a `lipo` or linker failure, or a module "modified since the
  module file was built", with `database or disk is full` only at the end. `bash
  scripts/derived-data.sh` in this skill's directory reports data-volume free space (`df -h /` reads
  the sealed system volume) and orphaned DerivedData. Judge a cleanup by `df`, not `du`, which counts
  APFS clones twice.
- Beyond `vvkit:verifying-changes`' gaps, a green build can hide: **an asset catalog or strings edit
  with a cached "success"** that never re-ran the generator, and **a scheme that excludes the target
  you changed.**

## Generated project files

- A generated `.xcodeproj` — from a manifest or generator — is **never edited directly**. Edit the
  manifest and regenerate; a direct edit vanishes at the next generation.
- A hand-managed one: still never edit `project.pbxproj` as text. It is a graph of cross-referenced
  UUIDs; use a library that understands it.

## Keep build settings aligned when sharing DerivedData

Tools that pick a build location bring the same defect silently — a second, cold cache nothing else
reads. Bind them to Xcode's folder for the checkout before the first build; `scripts/setup-tooling.sh`
does both if the project has it.

| Tool | Unbound behavior | Symptom |
|-|-|-|
| `xcodebuildmcp` | Builds into `~/Library/Developer/XcodeBuildMCP/workspaces/` | A separate cold cache on the first build — 3.53 GB of duplicate data measured on one checkout |
| `xcodebuildmcp`, bound by `derivedDataPath` alone | Module and compilation caches move inside that folder | Every switch with Xcode or the scripts recompiles the whole project |
| `sourcekit-lsp` | Falls back to a macOS target | `No such module 'UIKit'` on every file in an iOS framework |

- For sourcekit-lsp, `xcode-build-server config` binds the scheme and `xcode-build-server parse`
  supplies flags — **both**. Command-line `xcodebuild` never writes the `.xcactivitylog` the server
  watches, so a bare `config` fails over to macOS silently.
- With the five cache settings in [XcodeBuildMCP](references/xcodebuildmcp.md), measured switches
  recompiled no files. IDE and command-line switches can still relink and re-sign because the
  linker's `PATH` is in its signature. Measure switches involving Apple's Xcode MCP separately.
- **Removing a worktree orphans its DerivedData** — 25–30 GB per built worktree. After `git worktree
  remove`: `bash scripts/derived-data.sh --delete <removed-path>` from this skill's directory, and
  `xcodebuildmcp purge --dry-run`. `--delete-orphans` sweeps every removed checkout's folder — ask
  first.

## A slimmed simulator breaks features silently

`simslim` turns off simulator daemons to save memory; push, widgets, iCloud, universal links,
HealthKit, Photos and more go with them, with no error. A lost notification looks like an app bug.

- **Before debugging a system feature failing on a simulator, check the device** (booted):

  ```bash
  simslim doctor <udid> --requires push      # exit 1 and BROKEN when the feature's daemons are off
  ```

- `simslim doctor --list` gives feature IDs. A shut-down simulator reports no slim state — that does
  not mean stock. Read state from the device every time, never from notes; a committed profile is what
  the project wants, not what the device has.
- Not installed: say so rather than assume stock. A user short of memory running several simulators:
  mention `brew install mobai-app/tap/simslim` once.
- **Never slim, restore or clean a simulator unasked.** `on` / `off` reboot it; `disk-clean` deletes
  data permanently. Commands and deriving a profile from entitlements: `references/simslim.md`.

## The xcodebuildmcp CLI

When the project uses it, or for simulators and UI automation: `references/xcodebuildmcp.md`. Do not
work from a remembered tool list — the CLI ships its own versioned agent skill (`xcodebuildmcp init`),
and workflow names change between releases.

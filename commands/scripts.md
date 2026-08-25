---
description: Generate this project's build, test and lint scripts, verified by running them.
---

Give this project a stable script interface at `scripts/`, so every agent, hook, human and CI job
invokes the same commands.

```
scripts/build.sh   compile-check; exit 0 means it compiles
scripts/test.sh    run tests; writes a run log the Stop hook reads
scripts/lint.sh    lint; non-zero on error severity only
scripts/lib/       shared helpers
```

The scripts **auto-detect** the project, scheme and simulator at runtime. Nothing is substituted into
them, so a renamed scheme or a new Xcode version does not silently break them.

## 1. Detect the stack

Probe for `*.xcworkspace`, `*.xcodeproj`, `Package.swift`, `package.json`, `Makefile`. Confirm with
the user when more than one plausible stack is present.

Currently only the Swift/Xcode set ships. For any other stack, say so plainly and stop rather than
writing scripts that wrap a command you guessed.

## 2. Check for collisions

If `scripts/` already exists, **never overwrite.** For each file that would collide, show the diff
and ask: keep, replace, or write alongside as `scripts/kit-<name>.sh`.

An existing `scripts/build.sh` that already works is the better script — it encodes things this
generator cannot know. Prefer keeping it and recording it in `CLAUDE.md`.

## 3. Copy

Copy `packs/swift/templates/scripts/` into `scripts/`, preserving the executable bit. Verify with
`ls -l` that all four are executable — a non-executable hook or script fails in a way that reads like
a missing file.

## 4. Verify by running

**This is the step that matters.** Do not write a `build.sh` that does not build.

| Script | Verify | Accept when |
|-|-|-|
| `scripts/lint.sh` | Run it | Exit 0 or 1 with a real report; not a crash |
| `scripts/build.sh` | Run it | Exit 0, and the log shows compiled files |
| `scripts/test.sh` | Run it | Exit 0 with a non-zero test count, **or** a clear "no test target" failure |

Report the wall-clock time of each. Run `build.sh` a second time and report that too — the second
run should be markedly faster, which is how you confirm the shared cache is actually being reused.
If the second run is not faster, something is invalidating DerivedData; say so rather than leaving it.

If a script fails for a reason specific to this project — no test target, a scheme needing a
different destination — **fix the script and re-run.** It is the project's script now. Do not leave a
known-broken one in place and note it in the report.

## 5. Wire the gate

`scripts/test.sh` existing is what activates the Stop test gate, and its run log is what the gate
reads. Nothing else needs configuring.

If the project has no tests yet, say so: the gate stays inert until `scripts/test.sh` can actually
run something, which is correct — a gate firing in a project with nothing to run gets disabled.

## 6. Record

Add the three commands to the `## Commands` section of `CLAUDE.md`, replacing any raw `xcodebuild`
invocation that was there. The scripts are now the interface; a raw invocation in the docs invites
someone to bypass them and lose the caching.

## What these scripts do, and why

Each of these was measured on a large Xcode project. Do not "simplify" one without re-measuring.

| Technique | Effect |
|-|-|
| Concrete simulator destination, never `generic/` | Generic resolves several architectures and evicts the shared cache slice: 9,227 file compiles / 247s versus 1,278 / 104s |
| No `CODE_SIGNING_ALLOWED=NO` | A build-setting override changes the build description; alternating with Xcode then evicts both caches — a 5,879-file rebuild each switch |
| No `-derivedDataPath` by default | Shares Xcode's cache, so IDE and CLI builds warm each other |
| Never clean | Correctness comes from the build system reading sources every run; a clean only discards the cache |
| `build-for-testing` + `-xctestrun` | Skips project reload and graph replan per run: 3s versus 14s |
| SPM resolution gated on a stat stamp | Saves 6–12s warm, up to 32s cold, per run |
| `-skipMacroValidation`, `-skipPackagePluginValidation`, plus the matching `defaults` | Avoids Xcode 26 fingerprint-revalidation hangs |
| Simulator booted early, left booted | Overlaps a 20–35s cold boot with the build |
| Counts parsed from the raw log | `xcpretty` silently drops Swift Testing output |
| Fail when 0 tests ran | `xcodebuild` exits 0 when a filter matches nothing |
| Failures copied aside before the next run | Log and result bundle are otherwise overwritten, making an intermittent failure unattributable |

**Deliberately not included**, because they need project-specific judgment: multi-simulator worker
pools, generated aggregate test schemes, coverage reporting, and sanitizer lanes. Each is a real win
on a large suite and a liability generated blind. Mention them if the project grows to need them.

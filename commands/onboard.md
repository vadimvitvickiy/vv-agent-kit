---
description: Scaffold the kit's .claude/ and .agents/ layout into a project, verifying every asserted convention against the code first.
---

Set up this project to work with the kit.

Nine steps, in order. Do not skip step 5 — it is the reason this command exists rather than a
generic scaffolder.

## Step 1 — Detect what is already here

Look for `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.agents/`.

If `CLAUDE.md` exists, ask: **overwrite** or **merge**. On overwrite, back up to `CLAUDE.prev.md`
first. On merge, keep every project-specific fact already written and add only the missing sections.

If `AGENTS.md` exists as a real file, plan to replace it with a symlink to `CLAUDE.md` — but carry
its content into `CLAUDE.md` first. Read it fully and account for every section. Losing a
hand-written convention silently is the worst outcome of this command.

## Step 2 — Profile the project

By filesystem probe, not by asking:

| Signal | Look for |
|-|-|
| Language and stack | Manifest files, dominant file extensions |
| Build system | `Makefile`, `package.json` scripts, `*.xcodeproj`, `Package.swift`, `build.gradle` |
| Test framework | Test targets, test directories, test dependencies |
| Lint config | `.swiftlint.yml`, `.eslintrc*`, `ruff.toml`, etc. |
| CI | `.github/workflows/`, `bitrise.yml`, `.gitlab-ci.yml` |
| Branches | `git branch -a`, and which branch HEAD tracks |
| Commit style | `git log --oneline -30` — tense, prefixes, ticket references |
| Generated files | `.gitignore` entries, `*.generated.*`, codegen configs |

## Step 3 — Confirm the profile

Present what you found and ask about only what you could not determine. Batch the questions.

## Step 4 — Select packs

List `packs/*/pack.json` and pre-check each whose `detect` globs match. Confirm with the user.

## Step 5 — Verify before asserting

**Every convention about to be written into `CLAUDE.md` is first checked against the code. A claim
that fails verification is reported to the user, never written.**

| About to assert | Verify by | Fails when |
|-|-|-|
| A library or framework is banned | Grep for its import across the source extensions | Any file imports it |
| A library or framework is required | The same grep | No file imports it |
| A module or component has shape X | Compare against the project's own scaffold — editor templates, generators — and the three most recently added examples | The scaffold produces different files |
| A marker or prefix convention is in force | Grep for the marker; count occurrences | Zero occurrences |
| A naming convention holds | Glob the pattern; count conforming against total | Conformance is not near-total |
| A command builds or tests the project | Run it | Non-zero exit |
| A file is generated | Confirm the generator config names it as an output | Nothing generates it |

Report failures as a table — the claim, what was actually found, and the suggested correction — then
ask which to adopt.

**Never silently write an unverified claim.** A false line in an always-loaded file is worse than a
missing one: it is trusted and acted on without checking, and it is read every session by something
that cannot tell it is wrong.

This is not hypothetical. The project this command was written for asserted that a framework was
banned while 44 files imported it, described a component shape its own editor template contradicted,
and documented a string-marker convention with zero occurrences in 406 files. Each was one grep away.

## Step 6 — Write `CLAUDE.md`

From `templates/CLAUDE.md`, substituting every placeholder. **No placeholder token may survive into
the output.** Fill the "Known debt" section with anything step 5 turned up that the user chose not to fix
now.

Replace `AGENTS.md` with a symlink:

```bash
rm AGENTS.md && ln -s CLAUDE.md AGENTS.md
```

## Step 7 — Write the layout

```
.claude/settings.json          from templates/settings.json
.claude/rules/                 from the selected packs' rules/
.claude/context/               structure.md, decisions.md
.claude/context/specs/         empty
.agents/{plans,state,scratch}/ empty
```

Then walk each selected pack's `templates` mapping in `pack.json` and copy every entry — the mapping
is the source of truth, not this list, because a pack can add entries without this file changing.

**A copied `.mcp.json` is inert until someone approves it.** Claude Code prompts once per project for
project-scoped MCP servers, and until that is answered the file is present and no tool from it loads.
The repo looks correctly configured either way, so confirm with `/mcp` rather than by reading the
file, and say in step 9 that approval is still outstanding if it is.

**Never overwrite an existing config.** If one is present, show the diff and ask.

**Source files copied from a pack still need target membership.** `TestSupport/` is Swift source: SPM
picks it up from the directory, but an Xcode project does not — the files exist on disk and compile
into nothing until they are added to the test target. Do not add them by editing the `.xcodeproj`;
say plainly in step 9 that the files were copied and which target they must join. Verify membership
by asking the build system, never by their folder — see `vvkit:exploring-a-codebase`.

**Hooks are registered by the plugin, not wired here.** `session-context` and the lint hook are
always active and no-op where they do not apply. The test gate is the only hook that can block a
turn, so it stays inert until the project opts in — which happens by having `scripts/test.sh`, not by
configuration.

Set `KIT_SOURCE_GLOB` in `.claude/settings.json` when the project's sources are not `*.swift`.
`KIT_TEST_COMMAND` is only needed to override `scripts/test.sh` with something else.

## Step 7b — Generate the scripts

Run `vvkit:scripts` to write `scripts/{build,test,lint}.sh` and verify each by running it.

This is what gives the project a stable interface and what activates the test gate. Skip it only if
the project already has working build and test scripts — in which case record those in `CLAUDE.md`
instead, and say so.

## Step 8 — Update `.gitignore`

Append `templates/gitignore.fragment` unless `.agents/` is already ignored.

## Step 9 — Report

- Files written, skipped, and backed up.
- Every claim that failed verification in step 5, and what was written instead.
- Any hook dropped for a missing prerequisite.
- Any pack source copied but not yet compiled — `TestSupport/` on an Xcode project — naming the
  target it has to join. Copied and unreferenced looks identical to installed.
- Any MCP server written to `.mcp.json` and not yet approved. Unapproved and absent look identical
  from the repo.
- What to do next: run `/vvkit:explore` to generate the structure map.

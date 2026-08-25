# vv-agent-kit

[![validate](https://github.com/vadimvitvickiy/vv-agent-kit/actions/workflows/validate.yml/badge.svg)](https://github.com/vadimvitvickiy/vv-agent-kit/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A Claude Code plugin holding agent practices that survive leaving the repo they were learned in.

Most agent setups rot the same way. A convention is discovered in one project, written into that
project's `CLAUDE.md`, copied into the next project, edited locally, and within a year the three
copies contradict each other and nobody knows which is current. This plugin exists to make that
impossible: anything portable lives in the plugin and is updated once for every project at once,
and anything repo-specific is scaffolded *into* the project, which then owns it outright.

## Install

```bash
claude plugin marketplace add vadimvitvickiy/vv-agent-kit
claude plugin install vvkit@vv-agent-kit
```

Then confirm what Claude Code actually discovered — not what the layout suggests:

```bash
claude plugin details vvkit
```

Everything is namespaced `vvkit` — `/vvkit:onboard`, `vvkit:writing-tests`, `vvkit:swift-reviewer`.

## What you get

Skills load on their own when the situation matches. You never have to name one.

**Neutral — apply in any repository, in any language:**

| Skill | Fires when |
|-|-|
| `writing-tests` | Behavior changes, a bug is fixed, or a test needs judging on whether it earns its place |
| `verifying-changes` | Deciding what to build or run, and before claiming anything is done or passing |
| `debugging-systematically` | A test fails or behavior does not match expectation — before any fix is proposed |
| `reviewing-code` | Reading a diff or pull request for defects, on a change you did not write |
| `delegating-work` | A change spans several files, or subagents are on the table |
| `exploring-a-codebase` | Starting in an unfamiliar repo, or a map or architecture note looks stale |
| `writing-comments` | A diff adds explanatory prose alongside code |
| `writing-logs` | Adding log statements, or deciding what level a message belongs at |
| `capturing-decisions` | A rationale emerges that would otherwise die with the session |
| `injecting-dependencies` | Writing a constructor, or adding a parameter so something can be swapped in a test |
| `writing-project-instructions` | A `CLAUDE.md` is being edited, has grown long, or repeats an installed skill |
| `writing-skills` | Authoring or editing a component of this plugin |

**Swift — the same disciplines, instantiated:**

| Skill | Fires when |
|-|-|
| `swift-testing` | Writing tests with Swift Testing, including for concurrent or shared state |
| `swift-concurrency` | Swift code shares state across threads, queues or isolation domains |
| `swift-style` | Creating or editing a Swift type — member order, layout, `guard` vs `if` |
| `swift-logging` | Adding logging through `os.Logger` or an equivalent facade |
| `xcode-builds` | Building, compile-checking, testing or driving a simulator |

**Commands and agents:**

| Component | Does |
|-|-|
| `/vvkit:onboard` | Scaffolds the `.claude/` and `.agents/` layout into a project, verifying every convention it writes against the actual code first |
| `/vvkit:review` | Resolves the diff, routes it to the reviewer for the detected language, reports by severity |
| `/vvkit:scripts` | Writes `build.sh`, `test.sh`, `lint.sh` and `map.sh` into a project and verifies them by running them |
| `/vvkit:explore` | Regenerates the code map and reconciles it against the hand-written architecture notes |
| `/vvkit:wire` | Reconciles a `CLAUDE.md` against the installed skills, replacing duplicated rules with references |
| `vvkit:swift-reviewer` | Read-only Swift review subagent — correctness first, conventions second |

**Hooks**, all fail-open and none of them opinionated about your project unless you ask:

| Hook | Event |
|-|-|
| `session-context` | Injects branch and working-tree state at session start |
| `swiftlint` | Autocorrects an edited Swift file; surfaces only what it could not fix |
| `test-gate` | Blocks the turn once per session when source changed after the last test run — **inert unless the project opts in** |

## The one rule

Everything in this repo answers a single question:

> **Does this text stay true in another repo?**

| Answer | Home | Consequence |
|-|-|-|
| Yes | `skills/`, `agents/`, `commands/`, `hooks/` | Lives in the plugin. Never copied into a project. Updating the plugin updates every project at once. |
| No | `templates/`, `packs/` | Inert data. `/vvkit:onboard` scaffolds it into a project, which then owns it. |

A target name, a script path, a scheme, a ticket prefix inside a skill is the defect this plugin
exists to prevent. `scripts/validate.sh` enforces the mechanical half of that rule; the judgment
half is why `vvkit:writing-skills` exists.

## Two tiers, one namespace

Skills are flat. The tier is expressed by the name, and by what each skill refuses to repeat.

| Neutral — the discipline | Swift — the instantiation |
|-|-|
| `writing-tests` | `swift-testing` |
| `writing-logs` | `swift-logging` |
| `writing-comments` | `swift-style` |
| `verifying-changes` | `xcode-builds` |
| `reviewing-code` | `swift-reviewer` (agent) |
| `delegating-work`, `exploring-a-codebase`, `capturing-decisions`, `debugging-systematically`, `injecting-dependencies`, `writing-project-instructions`, `writing-skills` | — |

Each Swift skill declares its neutral counterpart as `REQUIRED BACKGROUND` and does **not** restate
it. Restating is how one ruleset ends up in three files that then drift apart — the validator checks
that the cross-references resolve, but only discipline keeps them from being copies.

Adding a stack means adding a `packs/<stack>/` directory and the skills that pair with the existing
neutral tier. Nothing about the neutral tier changes.

## Layout

```
skills/       one flat namespace; the tier is in the name
agents/       reviewer subagents
commands/     /vvkit:onboard, /vvkit:review, /vvkit:scripts, /vvkit:explore, /vvkit:wire
hooks/        session context, lint-on-edit, test gate
packs/        per-stack rules and config that onboard copies into a project
templates/    the neutral project scaffold
scripts/      validate.sh — the structural gate
tests/        fixtures the validator must reject
```

Discovery is by convention, not declared in the manifest. Only `skills/`, `agents/` and `commands/`
at the repo root are picked up, so a skill nested any deeper **silently never loads**.

Hooks are the exception: `hooks/*.sh` alone is inert. They must be declared in `hooks/hooks.json`,
and `${CLAUDE_PLUGIN_ROOT}` resolves only inside that manifest.

## Generated project scripts

`/vvkit:scripts` writes a stable interface into a target project:

```
scripts/build.sh   compile-check
scripts/test.sh    run tests; writes the log the Stop hook reads
scripts/lint.sh    lint; fails on errors only
scripts/map.sh     regenerate the ranked code map
```

They auto-detect project, scheme and simulator at runtime — nothing is substituted in, so a renamed
scheme does not break them. Every performance choice in them was measured on a large Xcode project;
the table in `commands/scripts.md` records what and why.

`scripts/test.sh` existing is also what activates the test gate, and its run log is what makes that
gate honest. Without something writing that log, the gate fires whether or not tests ran.

## Developing

```bash
./scripts/validate.sh                  # exit 0 required
./scripts/validate.sh tests/fixtures   # must exit 1 with eight violations
claude plugin validate . --strict      # exit 0 required
```

The second command is the one that matters. A validator that passes everything is worse than none,
so the fixtures exist to prove it still rejects a mismatched `name`, a workflow-narrating
`description`, a dead cross-reference, a leaked placeholder, a missing H1 and an `@`-link.

Installing copies the repo into `~/.claude/plugins/cache/vv-agent-kit/vvkit/<version>/`, so **edits
to a working tree are not live**. After a change:

```bash
claude plugin marketplace update vv-agent-kit
claude plugin details vvkit
```

See [CONTRIBUTING.md](CONTRIBUTING.md), and `vvkit:writing-skills` for the authoring contract.

## License

MIT — see [LICENSE](LICENSE).

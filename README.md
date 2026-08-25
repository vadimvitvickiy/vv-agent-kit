# vv-agent-kit

A Claude Code plugin holding agent practices that survive leaving the repo they were learned in.

Install:

```bash
claude plugin marketplace add vadimvitvickiy/vv-agent-kit
claude plugin install vvkit@vv-agent-kit
```

Everything is namespaced `vvkit` — `/vvkit:onboard`, `vvkit:writing-tests`, `vvkit:swift-reviewer`.

## The one rule

Content goes in exactly one of two places, decided by a single question:

> **Does this text stay true in another repo?**

| Answer | Home | Consequence |
|-|-|-|
| Yes | `skills/`, `agents/`, `commands/`, `hooks/` | Lives in the plugin. Never copied into a project. Updating the kit updates every project at once. |
| No | `templates/`, `packs/` | Inert data. `/vvkit:onboard` scaffolds it into a project, which then owns it. |

The failure this prevents: content copied into a project once, edited locally, never reconciled, and
unportable within a year. That is how most agent setups rot.

## Layout

```
skills/       one flat namespace; the tier is in the name
agents/       reviewer subagents
commands/     /vvkit:onboard, /vvkit:review, /vvkit:explore
hooks/        session context, lint-on-edit, test gate
packs/        per-stack rules and config the onboard command copies
templates/    the neutral project scaffold
scripts/      validate.sh — the structural gate
tests/        fixtures the validator must reject
```

Discovery is by convention, not declared in the manifest. Only `skills/`, `agents/` and `commands/`
at the repo root are picked up, so a skill nested any deeper **silently never loads**.

Hooks are the exception: `hooks/*.sh` alone is inert. They must be declared in `hooks/hooks.json`.

Verify what was actually discovered rather than trusting the layout:

```bash
claude plugin details vvkit
```

## Two tiers, one namespace

Skills are flat. The tier is expressed by the name and by cross-references:

| Neutral — the discipline | Swift — the instantiation |
|-|-|
| `writing-tests` | `swift-testing` |
| `writing-logs` | `swift-logging` |
| `writing-comments` | `swift-style` |
| `verifying-changes` | `xcode-builds` |
| `delegating-work`, `exploring-a-codebase`, `capturing-decisions` | — |

Each Swift skill declares its neutral counterpart as `REQUIRED BACKGROUND` and does **not** restate
it. Restating is how the same ruleset ends up in three files that then drift apart.

## Before every commit

```bash
./scripts/validate.sh
```

It checks the frontmatter contract, that each skill's `name` matches its directory, that every
`description` states triggering conditions rather than summarizing a workflow, that no `vvkit:` cross-
reference is dead, that no placeholder token escaped the template trees, and that every hook is
executable and fails open.

To confirm the validator still has teeth:

```bash
./scripts/validate.sh tests/fixtures   # must exit 1 with eight violations
```

## Generated project scripts

`/vvkit:scripts` writes a stable interface into a target project:

```
scripts/build.sh   compile-check
scripts/test.sh    run tests; writes the log the Stop hook reads
scripts/lint.sh    lint; fails on errors only
```

They auto-detect project, scheme and simulator at runtime — nothing is substituted in, so a renamed
scheme does not break them. Every performance choice in them was measured on a large Xcode project;
the table in `commands/scripts.md` records what and why.

`scripts/test.sh` existing is also what activates the test gate, and its run log is what makes that
gate honest. Without something writing that log, the gate fires whether or not tests ran.

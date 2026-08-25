# Working on vv-agent-kit

This repo is a Claude Code plugin. Its content is instructions for agents, so a defect here is
silently inherited by every project that installs it.

## Before every commit

```bash
./scripts/validate.sh
```

Exit 0 is required. If a change touches `validate.sh` itself, also run
`./scripts/validate.sh tests/fixtures` and confirm it still exits 1 with eight violations — a
validator that passes everything is worse than none.

## The content rule

Everything answers one question: **does this text stay true in another repo?**

Yes → `skills/`, `agents/`, `commands/`, `hooks/`. No → `templates/`, `packs/`.

A repo-specific fact in a skill is the defect this kit exists to prevent. If you find yourself
writing a target name, a script path, a scheme, or a ticket prefix into a skill, it belongs in a
template instead.

## Skill authoring

- `name` matches the containing directory exactly. Lowercase, numbers, hyphens.
- `description` is third person, starts with `Use when`, and states **triggering conditions only**.
  Never summarize the skill's workflow — a description that narrates the process becomes a shortcut
  agents take *instead of* reading the body. This is enforced by the validator, imperfectly; the
  judgment is still yours.
- Neutral skills are verb-first gerunds (`writing-tests`). Stack skills are prefixed (`swift-testing`).
- A stack skill opens with `**REQUIRED BACKGROUND:** vvkit:<neutral-skill>` and does not restate that
  skill's content.
- Heavy reference material (100+ lines) goes in `references/` beside the `SKILL.md`, linked by a
  plain path — never with `@`, which force-loads it and burns context before it's needed.

## Development loop

Installing copies the repo into `~/.claude/plugins/cache/vv-agent-kit/vvkit/<version>/`. **Edits to this
working tree are not live.** After changing anything:

```bash
./scripts/validate.sh
claude plugin marketplace update vv-agent-kit
claude plugin details vvkit          # confirm the component inventory changed
```

`claude plugin details vvkit` is the real smoke test — it reports what Claude Code actually discovered,
not what you think you wrote. It caught a silently inert `hooks/` directory during initial
development.

## Hooks

Registered at plugin level in `hooks/hooks.json`. A bare `hooks/*.sh` with no manifest is **not
discovered** — the directory looks correct and does nothing.

`${CLAUDE_PLUGIN_ROOT}` resolves only inside that manifest. It does **not** resolve in a project's
`.claude/settings.json`, where there is no plugin context — wiring a hook that way silently produces
a bare `/hooks/...` path.

A hook that can block a turn must be **opt-in**. `test-gate.sh` is registered for every project but
exits immediately unless that project sets `KIT_TEST_COMMAND`. A blocking gate inherited by a project
that never asked for it gets the whole plugin disabled.

Fail open, always. `set -uo pipefail`, and any unexpected condition exits 0 — a bug in a hook must
never be able to wedge a session. Exit 2 is the only code fed back to the model; use it sparingly,
and only where a blocked turn is genuinely warranted.

Verify each hook survives garbage:

```bash
echo 'not json' | ./hooks/<name>.sh; echo "exit=$?"   # must be 0
```

## Commits

`<type>: <subject>`, imperative, no period, under 72 characters. No AI attribution in commit
messages or in any committed file.

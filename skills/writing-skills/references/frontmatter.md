# Frontmatter and validator rules

Mechanical reference for authoring components in this plugin. The judgment calls live in the skill
body; this file is the field list and the rule list.

## `SKILL.md` frontmatter

| Field | Required | Notes |
|-|-|-|
| `name` | yes | Lowercase letters, numbers and hyphens. Must equal the containing directory. |
| `description` | yes | Third person, starts `Use when`, triggering conditions only. |
| `allowed-tools` | no | Space-separated. Pre-approves those tools for the turn that invokes the skill only; the grant clears on the next user message. It does not restrict anything. |
| `disable-model-invocation` | no | `true` makes the skill reachable only as `/name`. Correct for anything with side effects; wrong for anything meant to fire on its own. |
| `context` | no | `fork` runs the skill in a subagent with its own context window. |
| `agent` | no | With `context: fork`, names the agent type to run it in. |
| `model` | no | Overrides the model for this skill. |

A malformed YAML block does not fail loudly. Claude Code loads the body with empty metadata, so
`/name` still works while the skill has no description to match against and never auto-triggers.
`claude --debug` surfaces the parse error.

## Agent frontmatter

| Field | Notes |
|-|-|
| `name`, `description` | The description is what the caller matches against. |
| `tools` | Explicit allow-list. Setting it is how a reviewer is prevented from writing. |
| `disallowedTools` | The inverse, when an allow-list would be unwieldy. |
| `model` | `sonnet` for read-and-search agents, `opus` for judgment. Omitting it inherits the caller's model, which silently overpays for lookups and underpays for review. |
| `effort`, `maxTurns` | Bound the work. |
| `isolation` | `worktree` is the only valid value. Only for agents that write in parallel. |

`hooks`, `mcpServers` and `permissionMode` are not supported in a plugin's agents.

## Command frontmatter

Only `description` is needed; the command name comes from the file path. Commands and skills are the
same mechanism — a command is a skill without a directory of its own.

## Hooks

Registered in `hooks/hooks.json`. A bare `hooks/*.sh` with no manifest entry is **not discovered**:
the directory looks correct and does nothing.

`${CLAUDE_PLUGIN_ROOT}` resolves only inside that manifest. It does not resolve in a project's
`.claude/settings.json`, where there is no plugin context, and silently produces a bare `/hooks/...`
path.

Every hook must fail open: `set -uo pipefail`, and any unexpected condition exits 0. Exit 2 is the
only code fed back to the model. A hook that can block a turn must be opt-in per project — a blocking
gate inherited by a project that never asked for it gets the whole plugin disabled.

## What `scripts/validate.sh` enforces

- Frontmatter exists, with non-empty `name` and `description`.
- `name` matches the directory and is lowercase alphanumeric-with-hyphens.
- `description` starts with `Use when`, is at most 500 characters, and does not match the
  workflow-narration patterns (`dispatch`, `, then `, `after that`, `step N`, `between each`).
- The whole frontmatter block is at most 1024 characters.
- Every `SKILL.md` has an H1.
- No `@`-link in `skills/`, `agents/` or `commands/`.
- No brace-delimited placeholder token outside `templates/`, `packs/`, `tests/`.
- No `README.md` install command containing a `<placeholder>`.
- Every `vvkit:<name>` cross-reference resolves to a real skill, command or agent.
- Every `.sh` under `hooks/` and `packs/` is executable and sets `-uo pipefail`.

## Manifest

`version` lives in `.claude-plugin/plugin.json` only. Set in both the manifest and the marketplace
entry, Claude Code silently prefers the manifest and the marketplace value is never used.

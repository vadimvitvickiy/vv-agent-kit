# Subagent reference

Mechanics for configuring subagents. The decision of *whether* to delegate lives in `SKILL.md`.

## Defining a project subagent

Store in `.claude/agents/<name>.md` and commit it. Loaded automatically at session start.

```markdown
---
name: api-reviewer
description: Reviews changed public API surface for contract breaks. Use after modifying exported declarations.
tools: Read, Grep, Glob, Bash
model: sonnet
color: blue
---

You are a senior engineer. Review only the diff for:
- Breaking changes to exported signatures
- Missing documentation on new public declarations
- Behaviour changes not reflected in the type

Cite every finding as file:line. Report grouped by Critical / Important / Minor.
```

**Lookup priority:** managed settings → `--agents` flag → `.claude/agents/` → `~/.claude/agents/` →
plugin `agents/`.

## Frontmatter fields

| Field | Values | Use when |
|-|-|-|
| `name` | lowercase-hyphens | **Required.** The identifier used to invoke it. |
| `description` | free text | **Required.** Drives auto-delegation. Answer "when to use me", not "what I do". |
| `tools` | `Read, Grep, Glob, Bash, Write, Edit, …` | **Always set explicitly.** Omitting inherits every tool plus every MCP server. |
| `disallowedTools` | `Write, Edit` | Denylist, applied before `tools`. Prefer an allowlist. |
| `model` | `haiku` / `sonnet` / `opus` / `inherit` | Omitted inherits the main session's model — a trivial lookup then runs at full cost, and a critical review silently downgrades on a cheap session. Set it. |
| `maxTurns` | integer | Bound execution on well-defined tasks. |
| `isolation` | `worktree` | File-modifying tasks needing an isolated repo copy. |
| `background` | `true` | Run concurrently without blocking the main conversation. |
| `memory` | `project` / `user` / `local` | Persistent memory directory. |
| `skills` | list of skill names | Inject skill content at startup — subagents do **not** inherit the parent's skills. |
| `mcpServers` | inline defs or names | Scope MCP servers to this agent, keeping their tool definitions out of the main context. |
| `hooks` | lifecycle config | Hooks scoped to this agent only. |
| `permissionMode` | `default` / `acceptEdits` / `plan` / … | Override permission prompting. |
| `effort` | `low` … `max` | Override session reasoning effort. |
| `color` | named colors | UI color in the picker. |

**Precedence:** a parent session in `bypassPermissions` or `acceptEdits` overrides subagent
frontmatter. A parent in `auto` mode ignores subagent `permissionMode` entirely.

**Plugin restriction:** `hooks`, `mcpServers` and `permissionMode` are ignored for plugin-sourced
agents, for security. Copy the agent into `.claude/agents/` to use them.

## Model selection

Make it explicit on every spawn. Omitted means "inherit", which is almost never what you want.

| Work | Model |
|-|-|
| Research, exploration, code reading, "where is X" | `sonnet` — never `haiku`; a missed file costs far more than the tokens saved |
| Planning, critical review, architectural judgment | `opus` |
| Genuinely trivial: read one known file, grep one known string | `haiku` — escalate to `sonnet` if there is any ambiguity about *where* to look |

`CLAUDE_CODE_SUBAGENT_MODEL=<id>` forces a model for all subagents. A debugging sledgehammer; it
kills tiering.

## What a subagent receives

- Working directory and environment
- `CLAUDE.md` files, the same as any session
- Its own system prompt (the file body)
- The spawn prompt

It does **not** receive the parent's conversation history, nor the parent's full system prompt.
Write self-contained prompts.

Only the subagent's **final message** returns. Every intermediate tool call and result stays in its
context — which is the point.

## Isolation via worktree

- Gives the subagent a temporary git worktree, an isolated copy of the repo.
- `cd` does not persist between its Bash calls and does not leak to the parent.
- Auto-cleaned if the subagent makes no changes.
- Costs roughly 200–500ms of setup plus disk per agent. Use only when agents mutate files in
  parallel and would otherwise conflict.

## Persistent memory

```yaml
memory: project   # .claude/agent-memory/<name>/  — committed, shared with the team
memory: user      # ~/.claude/agent-memory/<name>/ — across all projects
memory: local     # .claude/agent-memory-local/<name>/ — gitignored
```

When enabled, the memory path is injected into the system prompt, the first 200 lines (or 25KB) of
its `MEMORY.md` load at startup, and Read/Write/Edit are auto-enabled for that directory. Add
explicit write instructions to the body, or nothing will be recorded.

## Anti-patterns

| Anti-pattern | Why it fails | Fix |
|-|-|-|
| Omitting `tools` | Silently grants every tool and MCP server | Always set `tools` explicitly |
| No output format in the spawn prompt | Parent cannot parse the result | Specify shape and a length cap |
| Parallel subagents on the same files | Overwrites and lost edits | Distinct file ownership, or `isolation: worktree` |
| Subagents spawning subagents | Not supported | Chain from the main conversation |
| A one-liner via subagent | Startup latency exceeds the task | Do it inline |
| Same permissions as the parent | Defeats the isolation | Restrict to the minimum needed |
| Spawning a background agent near a compaction boundary | Can become invisible and double-spawn | Spawn earlier, or run synchronously |

## Hook output

Always truncate hook output — `| head -30`. A hundred edits at thirty lines each is a significant
context cost for no added signal.

## Checklist

- [ ] `tools` set explicitly
- [ ] `description` answers "when to use me"
- [ ] `model` chosen deliberately
- [ ] Output format specified in the spawn prompt
- [ ] `maxTurns` set if the task is bounded
- [ ] `isolation: worktree` if it writes files in parallel with others
- [ ] Committed to `.claude/agents/`

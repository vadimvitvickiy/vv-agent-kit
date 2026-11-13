---
name: vvkit-review
description: "Use when reviewing the local diff or a branch against the kit standards."
---

Review changed code and report findings.

**REQUIRED BACKGROUND:** `$vvkit-reviewing-code`. This command resolves the target and routes to a
reviewer; the discipline itself lives in that skill.

## Codex runtime

Load referenced skills by reading their SKILL.md. Surveyor, reviewer and runner
skills are role instructions, not registered agent types or enforced tool allowlists.
Use a generic subagent only when delegation is available and permitted; otherwise
perform the role inline. Follow the active session's model, context and permission
rules. User authorization takes precedence over imported workflow approval gates.
Claude hooks and plugin commands are not active in this package. Existing
`.claude/context/` paths refer to project documents, not Codex configuration.

## 1. Resolve the target

| Argument | Diff |
|-|-|
| none | `git diff HEAD` — uncommitted work |
| `--staged` | `git diff --cached` |
| a branch name | `git diff $(git merge-base HEAD <branch>)..HEAD` |
| a path | `git diff HEAD -- <path>` |

If the diff is empty, say so and stop. Do not fall back to reviewing the whole repository.

## 2. Detect the language

From the changed file extensions. If several are present, run the matching reviewer for each — do
not pick one and ignore the rest.

| Extensions | Agent |
|-|-|
| `.swift` | `$vvkit-swift-swift-reviewer` |

A reviewer ships with its stack plugin, so it is unavailable where the project has not installed that
plugin. When no reviewer matches the changed files, or its plugin is not installed, say so plainly and
review inline against `$vvkit-reviewing-code` rather than silently doing nothing.

## 3. Dispatch

**Hand the diff over as a file, not a paste.** Write the resolved diff to a file and pass its
path, so the reviewer reads exactly the tree you resolved and the diff stays out of this context.

Include in the spawn prompt: the diff's path, what the change is meant to do, and the required
output format. See `$vvkit-delegating-work` for the full spawn contract.

Size the model to the diff — `$vvkit-choosing-subagent-models`. A reviewer's definition carries only
its default.

The rulesets are **not** restated here. They live in the agent definition. Duplicating them into
this file is how one rule ends up in three places that then drift apart — the specific failure this
kit exists to prevent.

## 4. Report

Use the output shape from `$vvkit-reviewing-code`, then state plainly which findings you consider
blocking and which you would leave.

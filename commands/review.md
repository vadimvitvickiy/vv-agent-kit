---
description: Review the local diff or a branch against the kit's standards, delegating to the reviewer agent for the detected language.
---

Review changed code and report findings.

**REQUIRED BACKGROUND:** `vvkit:reviewing-code`. This command resolves the target and routes to a
reviewer; the discipline itself lives in that skill.

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
| `.swift` | `vvkit:swift-reviewer` |

When no reviewer matches the changed files, say so plainly and review inline against
`vvkit:reviewing-code` rather than silently doing nothing.

## 3. Dispatch

**Pass the diff in the prompt.** The agent must not re-fetch it — re-fetching risks reviewing a
different working tree than the one you resolved, and wastes the isolation.

Include in the spawn prompt: the diff, what the change is meant to do, and the required output
format. See `vvkit:delegating-work` for the full spawn contract.

The rulesets are **not** restated here. They live in the agent definition. Duplicating them into
this file is how one rule ends up in three places that then drift apart — the specific failure this
kit exists to prevent.

## 4. Report

Use the output shape from `vvkit:reviewing-code`, then state plainly which findings you consider
blocking and which you would leave.

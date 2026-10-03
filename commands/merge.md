---
description: Commit staged work, rebase onto the local base branch and merge the current worktree branch with workmux.
disable-model-invocation: true
---

Finish the current branch: commit what is staged, rebase onto the base branch, and let `workmux`
merge it and clean up.

**REQUIRED BACKGROUND:** `vvkit:committing-changes` for the commit message. Invoking this command is
the explicit request to commit that skill waits for.

This needs the `workmux` CLI. If it is not installed, say so and stop — do not substitute a
hand-written merge.

**Arguments:** `$ARGUMENTS`

| Flag | Effect |
|-|-|
| `--keep`, `-k` | Pass `--keep` to `workmux merge`: the worktree and tmux window survive the merge |
| `--no-verify`, `-n` | Pass `--no-verify` to `workmux merge` |

## 1. Commit

Commit the staged changes, following the repository's own convention as
`vvkit:committing-changes` describes. Skip this when nothing is staged. Unstaged files are left
alone: staging is the human's statement of what belongs in the commit.

## 2. Rebase

Read the base branch workmux recorded for this branch, and fall back to `main` when there is none:

```bash
git config --local --get "branch.$(git branch --show-current).workmux-base"
```

Rebase onto the **local** base branch — no `git fetch`, and not `origin/<branch>`:

```bash
git rebase <base-branch>
```

The base is the local branch because that is what `workmux merge` merges into.

When a conflict occurs:

- Before resolving, read what the base branch did to the file:
  `git log -p -n 3 <base-branch> -- <file>`.
- Keep both sides' intent — the base branch's change and this branch's.
- Stage the file and `git rebase --continue`.
- When the right resolution is unclear, stop and ask. A guessed resolution is merged a moment later
  and the worktree that could have shown the mistake is gone.

## 3. Merge

```bash
workmux merge --rebase --notification [--keep] [--no-verify]
```

Pass `--keep` and `--no-verify` only when the matching flag was given. Without `--keep`, the merge
removes the worktree, its tmux window and the local branch.

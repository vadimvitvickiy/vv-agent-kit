---
description: Commit staged work, rebase a finished branch onto its local base, fast-forward the base to it, and remove the branch and its worktree.
disable-model-invocation: true
---

Finish a branch: commit what is staged, rebase onto the base, fast-forward the base to it, and
clean up. Plain git throughout, in a linked worktree or in the main checkout.

**REQUIRED BACKGROUND:** `vvkit:committing-changes` — the commit message, and the rules for
integrating a finished branch. Typing this command is the explicit request to commit and to merge
that the skill waits for.

**Arguments:** `$ARGUMENTS`

| Argument | Effect |
|-|-|
| a branch name | Merge that branch rather than the current one. Run every git command below with `-C` on the worktree that has it checked out |
| `--into <base>` | The base branch to merge into |
| `--keep`, `-k` | Merge, and leave the branch and its worktree in place |
| `--no-verify`, `-n` | Skip step 3 |

## 1. Commit

Commit the staged changes, following the repository's own convention. Skip this when nothing is
staged. Unstaged files are left alone: staging is the human's statement of what belongs in the
commit.

## 2. Rebase onto the local base

The base is `--into` when given. Otherwise it is the repository's default branch — the target of
`git symbolic-ref --short refs/remotes/origin/HEAD` without its `origin/` prefix, or whichever of
`main` and `master` exists when that ref is unset. Say which base you are using before rebasing.
When the branch *is* the base, stop: there is nothing to merge.

```bash
git rebase <base>
```

Rebase onto the **local** branch — no `git fetch`, and not `origin/<base>`. Step 4 moves the local
base, and a branch rebased onto the remote one cannot fast-forward a local base that holds commits
the remote lacks.

When a conflict occurs:

- Before resolving, read what the base did to the file: `git log -p -n 3 <base> -- <file>`.
- Keep both sides' intent — the base's change and this branch's.
- Stage the file and `git rebase --continue`.
- When the right resolution is unclear, stop and ask. A guessed resolution is merged a moment
  later, and step 5 removes the worktree that could have shown the mistake.

## 3. Verify the rebased tree

Run the project's full test command on the rebased branch — `scripts/test.sh` where the project has
one. A green run from before the rebase proves only the tree it ran on. If it is red, report the
failures and stop; nothing has been merged yet.

## 4. Fast-forward the base

Find where the base is checked out:

```bash
git worktree list --porcelain
```

| The base is | Run |
|-|-|
| Checked out in a worktree | `git -C <that-worktree> merge --ff-only <branch>` |
| Checked out nowhere | `git fetch . <branch>:<base>` |

Both refuse anything but a fast-forward, which after step 2 means the base moved in the meantime:
rebase again, do not force. `git fetch .` cannot update a branch that is checked out, which is why
the two cases differ.

## 5. Clean up

Skip this with `--keep`.

When the branch lives in a linked worktree, remove the worktree from the base's worktree and then
delete the branch:

```bash
git -C <base-worktree> worktree remove <branch-worktree>
git -C <base-worktree> branch -d <branch>
```

`worktree remove` refuses when the worktree holds modified or untracked files. Those files exist
nowhere else: list them and ask whether to commit, move or delete them. Never `--force`, and never
`branch -D`.

When this session is running inside the worktree being removed, leave it through the harness's own
worktree tool where there is one, and tell the human the directory is gone. When the branch lives in
the main checkout, switch to the base before deleting it.

Remove only a worktree this work created. Anything else belongs to whoever made it.

---
description: Commit staged work, merge the base into a finished branch, verify, merge the branch into the base, and remove the branch and its worktree.
disable-model-invocation: true
---

Finish a branch: commit what is staged, bring the base into it, verify the result, merge it into
the base, and clean up. Plain git throughout, in a linked worktree or in the main checkout.

**REQUIRED BACKGROUND:** `vvkit:committing-changes` for the commit message and the rules for
integrating a finished branch, and `vvkit:resolving-conflicts` for step 2. Typing this command is
the explicit request to commit and to merge that the first skill waits for.

**Arguments:** `$ARGUMENTS`

| Argument | Effect |
|-|-|
| a branch name | Merge that branch rather than the current one. Run every git command below with `-C` on the worktree that has it checked out |
| `--into <base>` | The base branch to merge into |
| `--rebase` | Linear history: rebase onto the base and fast-forward it, with no merge commit |
| `--keep`, `-k` | Merge, and leave the branch and its worktree in place |
| `--no-verify`, `-n` | Skip step 3 |

## 1. Commit

Commit the staged changes, following the repository's own convention. Skip this when nothing is
staged. Unstaged files are left alone: staging is the human's statement of what belongs in the
commit.

## 2. Bring the base into the branch

The base is `--into` when given. Otherwise it is the repository's default branch — the target of
`git symbolic-ref --short refs/remotes/origin/HEAD` without its `origin/` prefix, or whichever of
`main` and `master` exists when that ref is unset. Say which base you are using. When the branch
*is* the base, stop: there is nothing to merge.

Use the **local** base — no `git fetch`, and not `origin/<base>`. Step 4 moves the local base, and
syncing with the remote one leaves out whatever the local base holds that the remote lacks.

Conflicts are resolved here, on the branch, so the base's checkout is never left half-merged. Read
what the base did since the fork point first, as `vvkit:resolving-conflicts` describes.

```bash
git -c merge.conflictStyle=zdiff3 merge --no-commit --no-ff <base>
```

`--no-commit` holds the merge open even when it is clean. Resolve any conflicts, then bring stale
code up to whatever the other side refactored — the grep in `vvkit:resolving-conflicts` — and only
then `git commit --no-edit`. The fixes land in the merge commit, which is the first commit where
both sides exist.

When the base has not moved since the fork point, git reports `Already up to date` and there is no
merge commit to make.

With `--rebase`, this step is `/vvkit:rebase <base>` instead.

## 3. Verify the merged tree

Run the project's full test command on the branch as it now stands — `scripts/test.sh` where the
project has one. A green run from before step 2 proves only the tree it ran on. If it is red,
report the failures and stop; the base has not been touched yet.

## 4. Merge into the base

Find where the base is checked out:

```bash
git worktree list --porcelain
```

| | Run |
|-|-|
| Default | `git -C <base-worktree> merge --no-ff --no-edit <branch>` |
| `--rebase` | `git -C <base-worktree> merge --ff-only <branch>` |
| `--rebase`, base checked out nowhere | `git fetch . <branch>:<base>` |

Step 2 already put the base inside the branch, so this merge has nothing left to conflict on.
`--no-ff` records the branch as one merge on the base's first-parent line, which is what
`git revert -m 1` and `git log --first-parent` work with.

When the base is checked out nowhere, a merge commit needs a checkout to be made in: check the base
out in the main worktree, or ask where. If the base moved again since step 2, go back to step 2
rather than resolving here. `--ff-only` and `git fetch .` refuse anything but a fast-forward; never
force either.

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

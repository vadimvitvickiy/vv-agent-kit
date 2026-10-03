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

Rebase onto the **local** branch — no `git fetch`, and not `origin/<base>`. Step 4 moves the local
base, and a branch rebased onto the remote one cannot fast-forward a local base that holds commits
the remote lacks.

### Read what the base did first

Before rebasing, find the fork point and what landed on the base since:

```bash
fork=$(git merge-base <base> HEAD)
git log --oneline "$fork"..<base>
git diff -M --name-status "$fork" <base>
```

Look for a refactor the branch never saw: a rename or a move (`R`, or a `D` beside an `A` when the
content changed too), a deleted file, a commit whose subject says rename, extract, move or replace.
Write down each old name with its new one. That list drives the two sections below. The same holds
the other way round: when this branch is the one that refactored, list its renames, because the
base may have gained new code in the old shape.

```bash
git -c merge.conflictStyle=zdiff3 rebase <base>
```

### A conflict is one commit's intent meeting code that moved

The sides are swapped in a rebase: `HEAD` is the base with the commits replayed so far, and the
other side is the commit being replayed — `git show REBASE_HEAD`. With `zdiff3` the hunk has three
parts, and the middle one, after `|||||||`, is the code both sides started from. Middle to top is
what the base did. Middle to bottom is what this commit meant to do.

- **Find the base commit behind the top part**: `git log -p "$fork"..<base> -- <file>`, or by symbol
  with `git log -S'<old name>' "$fork"..<base>`.
- **Resolve from the base's side.** Keep the top part and re-apply this commit's intent to it in the
  base's shape: the new name, the new signature, the new location. Putting the old shape back to
  make the hunk fit undoes the refactor at one call site and leaves the next reader two
  conventions.
- **Follow code that moved.** When the base moved a function or a file, the change belongs where
  the code lives now, which may be a file with no conflict markers in it. A file the base deleted
  or moved is not re-added at its old path.
- Stage the file and `git rebase --continue`.
- When the right resolution is unclear, stop and ask. A guessed resolution is merged a moment
  later, and step 5 removes the worktree that could have shown the mistake.

### A clean rebase can still be wrong

Git compares text. Code that one side added in the shape the other side refactored away conflicts
with nothing and breaks at build or at run time: a new call to a renamed function, a new subclass
of a moved type, a new file in a directory that no longer exists. In a scratch repository, a
branch that added one such call rebased cleanly across the rename and failed on import.

After the rebase, for every old name on the list:

```bash
git grep -n '<old name>'
```

Every hit is code to bring up to the refactor — whichever side wrote it. The branch's new code
takes the base's new shape; if the branch did the refactor, the base's new code takes the branch's.
A match that is only a comment or a changelog is not a hit.

Fix each one in the branch commit it belongs to — the commit that added the stale code, or, when
the stale code came from the base, the commit that did the refactor — so no commit in the range is
left broken for a later `bisect`:

```bash
git commit --fixup <commit>
GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <base>
```

When it is unclear which commit broke, `git rebase --exec '<build command>' <base>` builds after
each one and stops at the first that fails.

When adapting the branch takes more change than the branch itself made, stop and say so. That is a
branch to redo on top of the refactor, and the human decides.

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

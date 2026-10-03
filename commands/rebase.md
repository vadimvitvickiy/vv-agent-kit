---
description: Rebase the current branch onto a local or remote base, adapting it to refactors the base made.
disable-model-invocation: true
---

Rebase the current branch.

**REQUIRED BACKGROUND:** `vvkit:resolving-conflicts` — reading what the base did, which side is
which in a rebase, and the code a clean rebase still leaves wrong.

**Arguments:** `$ARGUMENTS`

| Argument | Target | Fetch first |
|-|-|-|
| none | the local default branch | no |
| `<branch>` | that local branch | no |
| `<remote>` | `<remote>/<default branch>` | `git fetch <remote>` |
| `<remote>/<branch>` | that remote branch | `git fetch <remote>` |

An argument is a remote when `git remote` lists it. The default branch is the target of
`git symbolic-ref --short refs/remotes/origin/HEAD` without its `origin/` prefix, or whichever of
`main` and `master` exists when that ref is unset.

A fetch happens only when the argument names a remote. Rebasing onto a remote nobody asked for
moves the branch onto commits the local base does not have yet.

## 1. Before rebasing

A rebase needs a clean working tree. When there are uncommitted changes, say so and stop; stashing
them unasked hides work the human may not remember to restore.

When the branch has been pushed, say that the rebase rewrites published commits and the next push
will need `--force-with-lease`. Do not push.

Read what the target did since the fork point, and list old names beside new ones, as
`vvkit:resolving-conflicts` describes.

## 2. Rebase

```bash
git -c merge.conflictStyle=zdiff3 rebase <target>
```

On each stop: resolve from the base's side, `git add` the file, `git rebase --continue`. Remember
that the sides are swapped — `HEAD` is the target, and the commit being replayed is `REBASE_HEAD`.

`git rebase --abort` returns the branch to where it started. Use it, and ask, when a resolution is
unclear; a rebase finished on a guess has no merge commit to point at later.

## 3. After the rebase

Grep for every old name on the list and fix the stale code in the commit it belongs to — fixup and
autosquash, as in `vvkit:resolving-conflicts`. Then run the checks the change needs:
`vvkit:verifying-changes`.

Report the target, the commits replayed, each conflict and how it was resolved, and anything
adapted to a refactor.

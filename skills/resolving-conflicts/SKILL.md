---
name: resolving-conflicts
description: Use when a merge, rebase or cherry-pick stops on a conflict, or when integrating a branch across a rename, move or other refactor made on the other side.
---

# Resolving conflicts

**A conflict is two intents meeting, not two texts.** Picking a side per line, or pasting both
halves, produces code neither author wrote. Work out what each side meant, and write code that does
both.

The hard case is a refactor on one side: it causes the hardest conflicts, and also breaks code git
merges without a word.

## Read what the other side did first

```bash
fork=$(git merge-base <base> HEAD)
git log --oneline "$fork"..<base>
git diff -M --name-status "$fork" <base>
```

- Look for a refactor: `R`, a `D` beside an `A`, a deleted file, a subject saying rename, extract,
  move or replace. **Write down each old name with its new one.**
- Do the same for `"$fork"..HEAD` — when your branch refactored, the base may have gained code in the
  old shape.

## Know which side is which

Use `git -c merge.conflictStyle=zdiff3 <merge|rebase> …`. The middle part, after `|||||||`, is the
common ancestor: middle→top is one side's change, middle→bottom the other's.

| Operation | Top (`HEAD`) | Bottom | The incoming commit |
|-|-|-|-|
| Merging the base into a branch | the branch | the base | `MERGE_HEAD` |
| Rebasing a branch onto the base | the base, plus the commits replayed so far | the commit being replayed | `REBASE_HEAD` |
| Cherry-picking | the current branch | the picked commit | `CHERRY_PICK_HEAD` |

**A rebase swaps the sides.** "Ours" there keeps the base and drops your change.

## Resolve onto the refactored side

- Find the refactor's commit: `git log -p "$fork"..<base> -- <file>`, or
  `git log -S'<old name>' "$fork"..<base>`.
- **Start from the refactored side** and re-apply the other side's intent in the new shape — new name,
  signature, location. Restoring the old shape to make a hunk fit leaves two conventions.
- **Follow moved code.** The change goes where the code lives now, maybe a file with no markers. A file
  the other side deleted or moved is not re-added at its old path.
- **Unclear resolution: stop and ask.** A guessed resolution reads as deliberate in every later diff.

## A clean merge can still be wrong

Git compares text. A new call to a renamed function, a subclass of a moved type, a file in a deleted
directory — none conflict, all break. In a scratch repo, a new file calling a renamed function passed
both merge and rebase without a conflict and failed on import.

- For every old name on your list: `git grep -n '<old name>'`. Every hit outside comments and
  changelogs is code to update, whichever side wrote it.
- Then build and test the integrated tree — `vvkit:verifying-changes`. The grep finds renames only,
  not a changed default, a reordered argument, a call that now happens twice.

| Operation | The fix lands in |
|-|-|
| Merge | The merge commit itself — merge with `--no-commit`, so the merge commit builds |
| Rebase | The branch commit it belongs to: `git commit --fixup <commit>`, then `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <base>` |

- Leave no broken commit for a later `bisect`. `git rebase --exec '<build command>' <base>` stops at
  the first commit that fails to build.
- **Adapting one side takes more change than that side made:** stop and say so. That is work to redo
  on top of the refactor, and the human decides.

Source for the term: Martin Fowler, "SemanticConflict".

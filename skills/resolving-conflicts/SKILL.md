---
name: resolving-conflicts
description: Use when a merge, rebase or cherry-pick stops on a conflict, or when integrating a branch across a rename, move or other refactor made on the other side.
---

# Resolving conflicts

**A conflict is two intents meeting, not two texts.** Picking a side line by line, or pasting both
halves together, produces code neither author wrote. Work out what each side meant to do, and write
the code that does both.

The hard case is a refactor: one side renamed, moved or reshaped code the other side builds on. It
causes the conflicts that are hardest to read, and it also breaks code git merges without a word.

## Read what the other side did first

Before integrating, find the fork point and what landed on each side since:

```bash
fork=$(git merge-base <base> HEAD)
git log --oneline "$fork"..<base>
git diff -M --name-status "$fork" <base>
```

Look for a refactor: a rename or a move (`R`, or a `D` beside an `A` when the content changed too),
a deleted file, a commit whose subject says rename, extract, move or replace. Write down each old
name with its new one. Do the same for the branch — `"$fork"..HEAD` — because when the branch is
the side that refactored, the base may have gained new code in the old shape.

## Know which side is which

Ask for the common ancestor in the markers: `git -c merge.conflictStyle=zdiff3 <merge|rebase> …`.
The hunk then has three parts, and the middle one, after `|||||||`, is the code both sides started
from. Middle to top is what one side did. Middle to bottom is what the other did.

| Operation | Top (`HEAD`) | Bottom | The incoming commit |
|-|-|-|-|
| Merging the base into a branch | the branch | the base | `MERGE_HEAD` |
| Rebasing a branch onto the base | the base, plus the commits replayed so far | the commit being replayed | `REBASE_HEAD` |
| Cherry-picking | the current branch | the picked commit | `CHERRY_PICK_HEAD` |

A rebase swaps the sides: `HEAD` is the base, not your branch. Resolving "ours" there keeps the
base's code and drops your change.

## Resolve onto the refactored side

- **Find the commit behind the refactor**: `git log -p "$fork"..<base> -- <file>`, or by symbol with
  `git log -S'<old name>' "$fork"..<base>`.
- **Start from the side that did the refactor**, and re-apply the other side's intent to it in the
  new shape: the new name, the new signature, the new location. Putting the old shape back to make
  the hunk fit undoes the refactor at one call site and leaves the next reader two conventions.
- **Follow code that moved.** When a function or a file moved, the change belongs where the code
  lives now, which may be a file with no conflict markers in it. A file the other side deleted or
  moved is not re-added at its old path.
- **When the right resolution is unclear, stop and ask.** A guessed resolution reads like a
  deliberate one in every later diff.

## A clean merge can still be wrong

Git compares text. Code that one side added in the shape the other side refactored away conflicts
with nothing and breaks at build or at run time: a new call to a renamed function, a new subclass
of a moved type, a new file in a directory that no longer exists. In a scratch repository, a new file
calling a renamed function came through both a merge and a rebase without a conflict, still calling
the old name, and failed on import.

After integrating, for every old name on the list:

```bash
git grep -n '<old name>'
```

Every hit is code to bring up to the refactor, whichever side wrote it. A match that is only a
comment or a changelog is not a hit. Then build and run the tests on the integrated tree —
`vvkit:verifying-changes` — because the grep finds renames and nothing subtler: a changed default,
a reordered argument, a call that now happens twice.

Where the fix goes depends on the operation:

| Operation | The fix lands in |
|-|-|
| Merge | The merge commit itself. Merge with `--no-commit`, so the tree can be fixed before the commit exists and the merge commit builds |
| Rebase | The branch commit it belongs to — the one that added the stale code, or the one that did the refactor: `git commit --fixup <commit>`, then `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <base>` |

Either way no commit on the resulting history is left broken for a later `bisect`. During a rebase,
`git rebase --exec '<build command>' <base>` builds after each commit and stops at the first that
fails.

## When the adaptation outgrows the change

If bringing one side up to the refactor takes more change than that side made, stop and say so.
That is work to redo on top of the refactor rather than a conflict to resolve, and the human
decides which.

Source for the term: Martin Fowler, "SemanticConflict".

---
description: Regenerate the project's structure map at .claude/context/structure.md.
---

Regenerate `.claude/context/structure.md` from `templates/context/structure.md`.

The map exists so that exploration costs one read instead of a dozen searches every session. It is
only worth that if it is accurate.

## Gather

1. **Directory tree** — to a depth where structure is visible but noise is not, typically three
   levels. Exclude build output, dependency caches, and anything gitignored.
2. **Per-directory responsibility** — sample-read a few representative files in each top-level
   directory. Do not infer purpose from the name alone; a directory called `utils` tells you nothing,
   and a directory called `core` is frequently wrong.
3. **Build targets** — from the project or manifest file. Record which sources each compiles, and
   note where that differs from the directory layout. A directory whose name implies "shared" while
   compiling into exactly one target is precisely the trap a map should catch.
4. **Entry points** — where execution starts, where routing is decided, where configuration loads.
   This is the most useful table in the file and the one most often missing.
5. **Generated files** — anything produced by a generator, with the generator that makes it. Cross-
   check the `.gitignore` and any codegen config.

## Write

Fill every table in the template. Then:

- **Omit what you could not verify.** Do not guess a responsibility to fill a row. Once written, a
  guess is indistinguishable from a verified fact, and it will be trusted.
- **State counts where they are load-bearing** — number of targets, number of source files — so the
  next reader can tell at a glance whether the map has drifted.
- **Keep the header.** It tells the reader that the code wins on any contradiction, which is what
  keeps a stale map from being actively harmful.

## Report

Say what changed against the previous map. A structural change since the last run — a new target, a
moved directory, a directory that no longer exists — is worth calling out explicitly rather than
leaving the user to diff it, because it usually means something else is also out of date.

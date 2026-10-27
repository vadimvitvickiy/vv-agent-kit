---
name: reflecting-on-changes
description: Use when code has just been written or modified and the work is about to be reported as done — the self-review pass over your own unstaged changes.
---

# Reflecting on changes

**The first version that works is rarely the one to keep.** It carries the scaffolding of how it was
found. Read it once more as a reader, not its author. This does not replace an independent review —
`vvkit:reviewing-code`.

## Scope: the unstaged diff

```bash
git diff --name-only
git diff
```

- Staged changes are out of scope — staging is the human's mark that they looked. So is every line
  the change did not touch.
- Nothing unstaged, or only docs and config: say there is nothing to reflect on, and stop.
- **Read each changed file whole.** A hunk cannot show that its new helper exists forty lines up.

## What to look for, in order

1. **Subtraction.** Could the change remove something instead of adding? A requirement bolted onto
   the old shape, where reshaping it would have needed less code.
2. **Simplification.** Repeated lines that are a loop or helper; a variable used once and named no
   better than its expression; a conditional an early return flattens; a hand-rolled version of
   something the language or project has.
3. **Readability.** Nesting past three levels; a name that needs its comment. Shorter is not the
   goal — a pass that only makes code denser made it worse.
4. **Dead code.** Unused variables, imports, parameters, functions; commented-out attempts.
5. **Failure paths.** An error swallowed at a boundary; outside input reaching a query, shell or path
   unchecked.
6. **Waste.** An allocation in a loop; two passes where one does.
7. **Counterfeit values.** Your data hand-built into a type another part of the system owns, to
   reuse a function. Give that function a sibling that takes your type.

Leave alone what is only taste, and what the project does consistently another way.

## Fix, then look again

- Fix in place. Noting an improvement and leaving the code hands the reader work you already did.
- **Report instead of fixing** anything that changes behavior or lies outside your lines — those are
  the human's decisions.
- Re-run the loop over what the fixes changed; a fix is new code.
- **A pass that finds nothing ends the loop** — say so in one line.
- **Three passes is the cap.** Still improving on the third means a shape problem; say what keeps
  recurring.
- Every pass that changed code gets its checks re-run — `vvkit:verifying-changes`. An untested
  simplification is an untested behavior change.

## Before reporting done

- [ ] Every changed file was read whole, after the last edit
- [ ] The last pass found nothing, or the cap was reached and said so
- [ ] Nothing staged and nothing outside the diff was touched
- [ ] Tests were re-run after the last pass that changed code

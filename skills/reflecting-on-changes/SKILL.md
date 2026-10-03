---
name: reflecting-on-changes
description: Use when code has just been written or modified and the work is about to be reported as done — the self-review pass over your own unstaged changes.
---

# Reflecting on changes

**The first version that works is rarely the version to keep.** It carries the scaffolding of how
it was found: a variable that held an intermediate idea, a branch for a case that turned out not to
exist, three lines that became a pattern only on the third. Reading it once more, as a reader
rather than as its author, is the cheapest review there is.

This is a loop over your own change, run before anyone else sees it. An independent review is a
different thing and does not replace it — `vvkit:reviewing-code`.

## Scope: the unstaged diff

```bash
git diff --name-only
git diff
```

Staged changes are out of scope: staging is the human's mark that they have looked. So is every
line the change did not touch. If nothing is unstaged, or only documentation and configuration is,
say there is nothing to reflect on and stop.

Read each changed file whole, not only its hunks. A hunk cannot show that the helper it adds
already exists forty lines up.

## What to look for, in this order

1. **Simplification.** Repeated lines that are a loop or a helper. An intermediate variable used
   once and named no better than its expression. A conditional that an early return flattens. A
   hand-rolled version of something the language or the project already has.
2. **Readability.** Nesting deeper than three levels. A name that needs its comment. Prefer a
   readable multi-line block to a compressed one-liner: shorter is not the goal, and a pass that
   only makes the code denser has made it worse.
3. **Dead code.** A variable, import, parameter or function the final version no longer uses.
   Commented-out code from an earlier attempt.
4. **Failure paths.** An error swallowed or ignored at a system boundary. Input from outside
   reaching a query, a shell or a path unchecked.
5. **Waste.** An allocation inside a loop, or two passes over a collection where one does.

Leave alone what is only taste, and whatever the project does consistently a different way. A
convention you would not have chosen is still the convention.

## Fix, then look again

Fix what you find, in place. Noting an improvement in the summary and leaving the code as it was
hands the reader work you had already done.

Two things are reported instead of fixed: anything that would change behavior, and anything outside
the lines you changed. Both are decisions, and they are the human's.

Then run the loop again over what the fixes changed, because a fix is new code:

- **A pass that finds nothing ends the loop.** Say so in one line.
- **Three passes is the cap.** A change that is still giving up improvements on the third pass has
  a shape problem a fourth pass will not fix. Say that, and what keeps recurring.

Every pass that changed code is followed by the checks the change needs — `vvkit:verifying-changes`.
A simplification that was not re-run is a behavior change nobody tested.

## Before reporting done

- [ ] Every changed file was read whole, after the last edit
- [ ] The last pass found nothing, or the cap was reached and said so
- [ ] Nothing staged and nothing outside the diff was touched
- [ ] Tests were re-run after the last pass that changed code

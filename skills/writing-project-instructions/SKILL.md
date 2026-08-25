---
name: writing-project-instructions
description: Use when creating or editing a CLAUDE.md or AGENTS.md, when it has grown long, or when a rule in it also exists in an installed skill.
---

# Writing project instructions

**CLAUDE.md is the only file that is read on every turn of every session.** Everything in it is paid
for whether or not the turn has anything to do with it. A skill's body costs nothing until it fires.

That single asymmetry decides what belongs where. It is also why a long CLAUDE.md gets worse as it
grows rather than more thorough: past a couple of hundred lines, adherence drops, and the rule that
mattered is competing for attention with forty that did not apply.

## What belongs in it

| Content | Home |
|-|-|
| Facts only this repo knows — how to build it, run it, test it | CLAUDE.md |
| Constraints that are invisible in the file being edited — layering rules, generated files, frozen names | CLAUDE.md |
| Standing preferences about how to respond | CLAUDE.md |
| A discipline needed only when a certain kind of work happens | a skill |
| A rule that must hold whether or not the model cooperates | a hook |
| Anything already stated by an installed skill | a one-line reference, never a copy |

The test for moving something out: **would this still make sense to someone in a different repo?**
If yes, it is a discipline, and a discipline that lives in CLAUDE.md is loaded on every turn to be
relevant on a few of them.

## Never duplicate an installed skill

A rule stated in both CLAUDE.md and a skill is not reinforced. It is forked. The two copies are
edited on different days by different people, and by the time they contradict each other, the one
that wins is whichever was read last — which is the always-on copy, because it is always there.

Replace the copy with a reference:

```markdown
- **Testing:** `vvkit:writing-tests` for whether a test is owed, `vvkit:swift-testing` for how to write one.
- **Debugging:** `vvkit:debugging-systematically` — trace to origin before proposing a fix.
```

A reference is one line. The skill it names is several hundred and loads only when it is needed.

**Before removing a rule, confirm the skill actually states it.** A CLAUDE.md rule with no home in a
skill must be migrated into that skill first — deleting it because it "feels covered" is how a
convention silently stops being followed. If a rule has no home anywhere, and it is portable, that
is a missing skill, not a reason to keep the copy.

## Keep what is genuinely always-on

Some things earn their place on every turn, and stripping them to look tidy is the opposite mistake:

- The commands for this repo — build, test, lint. Naming them saves a discovery pass every session.
- Constraints someone would otherwise violate before any skill could fire, because the skill's
  trigger is the very edit that breaks the rule.
- Output and tone preferences, which apply to every response by definition.
- Anything a hook depends on the reader knowing.

## Shape

Short sections with headings, so a reader can skip what does not apply. State rules as rules, and
give the reason where the reason is not obvious — a rule with its rationale generalises to the case
it did not spell out, and a bare imperative does not.

Prefer plain statements to shouted ones. Emphasis that appears everywhere marks nothing.

## Reconciling one against the installed skills

`/vvkit:wire` does this mechanically: inventory what is installed, find the rules that are now
duplicated, and rewrite the references. Read it before doing the same edit by hand.

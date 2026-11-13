---
name: vvkit-writing-project-instructions
description: "Use when creating or editing an AGENTS.md or legacy CLAUDE.md, when it has grown long, or when a rule in it also exists in an installed skill."
---

# Writing project instructions

**AGENTS.md is loaded as project guidance; a skill's body costs nothing until it fires.**
Past a couple of hundred lines adherence drops, and the rule that mattered competes with forty that
did not apply.

## Codex runtime

Load referenced skills by reading their SKILL.md. Surveyor, reviewer and runner
skills are role instructions, not registered agent types or enforced tool allowlists.
Use a generic subagent only when delegation is available and permitted; otherwise
perform the role inline. Follow the active session's model, context and permission
rules. User authorization takes precedence over imported workflow approval gates.
Claude hooks and plugin commands are not active in this package. Existing
`.claude/context/` paths refer to project documents, not Codex configuration.

## What goes where

| Content | Home |
|-|-|
| Facts only this repo knows — how to build, run, test it | AGENTS.md |
| Constraints invisible in the file being edited — layering rules, generated files, frozen names | AGENTS.md |
| Standing preferences about how to respond | AGENTS.md |
| A discipline needed only for a certain kind of work | a skill |
| A rule that must hold whether or not the model cooperates | a hook |
| Anything an installed skill already states | a one-line reference, never a copy |

Test for moving something out: **would it still make sense in a different repo?** Then it is a
discipline, paid for on every turn to be relevant on a few.

## Never duplicate an installed skill

- A rule in both places is forked, not reinforced. When the copies drift, the always-on one wins.
- Replace the copy with a reference:

  ```markdown
  - **Testing:** `$vvkit-writing-tests` for whether a test is owed, `$vvkit-swift-swift-testing` for how to write one.
  - **Debugging:** `$vvkit-debugging-systematically` — trace to origin before proposing a fix.
  ```

- **Before removing a rule, confirm the skill states it.** A rule with no home gets migrated first;
  deleting it because it "feels covered" is how a convention silently stops being followed. A
  portable rule with no home is a missing skill.

## Keep what is genuinely always-on

- The repo's build, test and lint commands — they save a discovery pass every session.
- Constraints broken by the very edit that would trigger the skill.
- Output and tone preferences.
- Anything a hook depends on the reader knowing.

## Shape

- Short sections with headings, so a reader skips what does not apply.
- Rules as rules, with the reason where it is not obvious — a reason generalises to the case the rule
  did not spell out.
- Plain statements. Emphasis everywhere marks nothing.

`$vvkit-wire` reconciles a AGENTS.md against the installed skills mechanically. Read it before doing
the same edit by hand.

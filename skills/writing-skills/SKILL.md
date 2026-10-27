---
name: writing-skills
description: Use when authoring or editing a skill, agent, command or hook for this kit, or when deciding whether a piece of guidance belongs in a skill at all.
---

# Writing skills

**A defect here is inherited silently by every project that installs the plugin.** Nothing checks a
skill against a compiler; the care taken writing it is the only guard.

## Does it belong in a skill?

| The guidance is | It belongs in |
|-|-|
| True in any repo, needed only for some tasks | a skill |
| True in any repo, needed on literally every turn | `hooks/using-vvkit.md`, injected at session start — a plugin's own `CLAUDE.md` is never loaded |
| Specific to one repo | `templates/`, or a stack plugin's `templates/` and `rules/`, scaffolded in and owned by that repo |
| A rule that must hold whether or not the model cooperates | a hook |
| A task with its own context window and a narrow tool set | an agent |

**Does this text stay true in another repo?** A target or scheme name, a script path, a module
layout, a ticket prefix, a branch rule, a CI job name — each means you are writing a template.

## The cost model

- Only `name` and `description` are preloaded — in every session, in every repo. The body is free
  until invoked.
- The listing has a budget (~1% of context). **On overflow, descriptions are dropped from the least
  invoked skills first**, and a skill with no description stops triggering. A marginal skill taxes the
  ones that earn their place. Ship fewer, better.
- The body enters once and **stays for the session, unread again.** Write standing instructions, not
  a one-shot procedure.
- After compaction only the first ~5,000 tokens of each recent skill are re-attached. **Load-bearing
  rule near the top.**
- **Every rule competes with every other.** In IFScale (Jaroslawicz et al., 2025, 20 models) the best
  reached 68% at 500 instructions, biased toward the first. Merge rules that say the same thing; when
  one goes in, look for one to take out.

## Body style

- **H1, then the load-bearing rule in bold**, one or two sentences.
- **Sections of short bullets.** Each bullet is the rule; the reason follows in a clause only where it
  is not obvious. No narrative paragraphs, no recap at the end.
- Keep every measured number and named failure — that is what changes behavior. Cut the prose around
  it.
- Tables for decisions (situation → action); checklists for multi-step gates; code blocks only for
  commands and shapes the agent copies.

## The description contract

Third person. Starts with `Use when`. **Triggering conditions only.**

- A description that summarizes the procedure gets substituted for the body: the agent believes it
  has the rule and never opens the file. The superpowers plugin reports a description saying "code
  review between tasks" producing one review where the body required two.
- Anthropic's examples pair what with when; this kit keeps triggers only, and its skills still fired
  first in every run measured.

```yaml
# No — narrates the workflow, so it becomes the workflow
description: Reviews the diff, dispatches a reviewer per language, then reports findings by severity.

# Yes — states only when to reach for it
description: Use when reading a diff or pull request for defects, or when acting as the reviewer on a change you did not write.
```

- Use the words someone would actually use, including the *situation* — "a test fails", "behavior
  does not match expectation". Undertriggering is the common failure.
- Primary case first: entries are capped, and the tail is cut.

## Naming

- Neutral skills: verb-first gerunds — `writing-tests`. Stack skills: stack prefix — `swift-testing`,
  in `plugins/<stack>/skills/`, invoked as `vvkit-swift:swift-testing`. Plugins install per project; a
  single plugin skill cannot be hidden.
- **`name` equals the directory.** A mismatch makes a cross-reference that looks right and resolves to
  nothing.
- A stack skill opens with `**REQUIRED BACKGROUND:** vvkit:<neutral-skill>` and does not restate it.
  Restated rules drift until two contradict in front of a user.

## Earning a claim

- Every assertion has a measured number or a named failure behind it. "Prefer small functions" is
  already believed; "200 owners produced 209 initialisations and 201 distinct objects" changes the next
  action.
- Can't say how you know it: it is filler, and filler makes agents skim. Say where a number comes from,
  and whether measured or reported.
- Plain emphasis. Anthropic advises dialing back "CRITICAL" and "MUST"; current models overreact.

## Splitting into `references/`

- Move out material over ~100 lines, or needed by a minority of invocations — a field table, an API
  surface, a long example.
- **Link by plain relative path, never `@`**, which loads it whenever the skill loads.
- A reference over 100 lines opens with a table of contents; references stay one level deep. Agents
  preview with `head`. The validator checks the contents rule.
- Name the interpreter for bundled scripts — `bash scripts/tool.sh`. Packagers can strip the
  executable bit.
- Frontmatter fields and the validator's rules: `references/frontmatter.md`.

## Test the behavior, not only the structure

The validator proves well-formed, not effective. A skill that changes nothing is pure listing cost.

- `claude -p "<task>" --plugin-dir <repo> --output-format stream-json --verbose` loads an unpushed tree
  and logs every `Skill` call. `claude plugin eval` runs a checked-in suite with a no-plugin baseline.
- **Before writing:** give a fresh subagent the tempting task **without** the skill; record what it
  does and its reasons, verbatim. Already behaves: stop. Otherwise target those reasons, re-run with
  the skill, repeat until it complies.
- **Five runs per variant**, minimum. Wide disagreement means the wording does not bind yet.
- **Pressure-test discipline skills** with three or more of: time, sunk cost, authority, exhaustion,
  "be pragmatic". Concrete paths, a forced choice, "what do you do?", no "I would ask" exit. Test
  techniques on a new case, references by whether the right entry is found.
- **Close each rationalization where it appears:** a negation in the rule, an excuse/reality table
  row, a red-flag thought. Re-run; one closed loophole often opens the next.
- **Match form to failure.** Broken under pressure: a prohibition plus the rationalizations it answers.
  Wrong output shape: a recipe — parts in order; prohibitions on shape get negotiated (superpowers
  wording tests, reported). A three-line report recipe in `writing-tests` took naming the caught bug
  from 0 of 3 runs to 3 of 3. Multi-step workflow: a checklist the agent copies and checks off.

## Before shipping

- [ ] `./scripts/validate.sh` exits 0
- [ ] `./scripts/validate.sh tests/fixtures` still exits 1 — a validator that passes everything is
      worse than none
- [ ] `claude plugin validate .` exits 0
- [ ] **The version in `plugin.json` is bumped.** Installs are cached per version; an unbumped push
      reports success and changes nothing, exactly like a skill that failed to load
- [ ] `claude plugin marketplace update vv-agent-kit && claude plugin details vvkit` shows the new
      component
- [ ] Every claim in the body is one you could source if asked
- [ ] A fresh subagent showed the failure without the skill, and not with it

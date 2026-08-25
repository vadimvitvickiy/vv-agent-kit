---
description: Reconcile a CLAUDE.md against the skills this plugin actually installs, replacing duplicated rules with references.
---

**REQUIRED BACKGROUND:** `vvkit:writing-project-instructions`. That skill decides what belongs in a
CLAUDE.md; this command is the mechanical pass that applies it to an existing one.

Nothing is deleted on the assumption that a skill covers it. Every removal is justified by a specific
skill that states the same rule, and anything without one is migrated rather than dropped.

## 1. Resolve the target

| Argument | File |
|-|-|
| none | `./CLAUDE.md`, and `.claude/CLAUDE.md` if that is where the project keeps it |
| `--user` | `~/.claude/CLAUDE.md` — the instructions that apply to every project |
| a path | that file |

If the file does not exist, say so and stop. Creating one is `/vvkit:onboard`, not this command.

## 2. Inventory what is actually installed

```bash
claude plugin details vvkit
```

Use its output, not this repository's directory listing. A skill present in a working tree and not in
the installed plugin cannot be referenced — the reference would resolve to nothing for the reader.

Record the always-on token cost it reports. It is the number this command exists to trade against.

## 3. Map each rule to a skill, or to nothing

Read the target file and build a table before editing anything. One row per rule or section.

| Column | Meaning |
|-|-|
| Rule | The section or bullet, quoted closely enough to find again |
| Covered by | The skill that states the same thing, or `none` |
| Verdict | `reference` · `migrate` · `keep` |

- **`reference`** — a skill states it. Open that skill and confirm the claim is actually there. A
  topic match is not a coverage match: "the skill is about testing" does not establish that it states
  *this* rule about testing.
- **`migrate`** — portable, but no skill states it. It moves into the skill that should own it, and
  only then leaves the CLAUDE.md. If nothing should own it, propose a new skill and stop; do not
  invent one mid-edit.
- **`keep`** — repo-specific facts, constraints that must land before any skill could trigger, output
  and tone preferences, anything a hook depends on.

Show the table before you change the file. This is the step a reviewer needs to see, because it is
where a rule gets lost.

## 4. Rewrite

Replace each `reference` row with a single line naming the skill and what it governs. Group them
under one heading rather than scattering them, so the file reads as a short index into the plugin.

Leave every `keep` row where it is and in its own words. Rewording them to match the plugin's voice
is churn in a file whose diff should be readable.

## 5. Verify

- [ ] Every `migrate` row landed in a skill, and that change passes `./scripts/validate.sh`
- [ ] Every skill named in the rewritten file appears in `claude plugin details vvkit`
- [ ] No rule from the original is unaccounted for — walk the table, not the diff
- [ ] Report the before and after line count, and what the file no longer says out loud

State plainly which rules now depend on a skill firing. That is the trade this command makes: a rule
that was unconditional becomes one that loads when its trigger matches, and the user should be told
which rules moved.

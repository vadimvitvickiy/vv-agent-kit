# Contributing

The rules for writing content here live in one place: the `vvkit:writing-skills` skill, at
[`skills/writing-skills/SKILL.md`](skills/writing-skills/SKILL.md). Read it before opening a pull
request. It is not a summary of this file — this file is the short pointer, that is the contract.

## The question every change has to answer

> **Does this text stay true in another repo?**

Yes → it belongs in `skills/`, `agents/`, `commands/` or `hooks/`, and every project that installs
the plugin gets it.

No → it belongs in `templates/` or `packs/`, which are inert data that `/vvkit:onboard` scaffolds into
a project, after which that project owns it.

A repo-specific fact in a skill — a target name, a script path, a scheme, a ticket prefix — is the
exact defect this plugin exists to prevent. If you are writing one, you are writing a template.

## Before you open a pull request

```bash
./scripts/validate.sh                  # must exit 0
./scripts/validate.sh tests/fixtures   # must exit 1
claude plugin validate . --strict      # must exit 0
```

If your change touches `scripts/validate.sh`, add a fixture that the new rule rejects. A validator
that passes everything is worse than none, and the fixture run is what proves it still has teeth.

If your change touches a hook, prove it still fails open:

```bash
echo 'not json' | ./hooks/<name>.sh; echo "exit=$?"   # must be 0
```

## What gets a change rejected

- A claim with nothing behind it. Every assertion needs a measured number or a named failure mode.
  "Prefer small functions" is something the model already believes; it does not need a skill.
- A `description` that narrates the workflow instead of stating triggers. The description is the only
  part always in context, so a narrated one gets read *instead of* the body.
- Restating another skill rather than cross-referencing it. That is how one rule ends up in three
  files that then contradict each other.
- A new skill that mostly overlaps an existing one. Every skill's description competes for a shared
  listing budget — a marginal skill makes the useful ones more likely to stop triggering.

## Commits

`<type>: <subject>`, imperative, no period, under 72 characters. The body explains why, since the
diff already shows what. No AI attribution in commit messages or in any committed file.

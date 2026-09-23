---
name: writing-skills
description: Use when authoring or editing a skill, agent, command or hook for this kit, or when deciding whether a piece of guidance belongs in a skill at all.
---

# Writing skills

A defect here is inherited silently by every project that installs the plugin. Nothing in a skill is
checked against a compiler, so the only thing standing between a wrong sentence and a hundred repos
acting on it is the care taken writing it.

## First: does this belong in a skill at all?

| The guidance is | It belongs in |
|-|-|
| True in any repo, needed only for some tasks | a skill |
| True in any repo, needed on literally every turn | `hooks/using-vvkit.md`, injected at session start — a plugin's own `CLAUDE.md` is never loaded |
| Specific to one repo | `templates/`, or a stack plugin's `templates/` and `rules/`, scaffolded in and owned by that repo |
| A rule that must hold whether or not the model cooperates | a hook |
| A task with its own context window and a narrow tool set | an agent |

**The portability test is the one that matters: does this text stay true in another repo?** The tells
that it does not are concrete — a target or scheme name, a script path, a module layout, a ticket
prefix, a branch naming rule, a CI job name. If you are reaching for one of those, stop; you are
writing a template.

## The cost model decides everything else

Only `name` and `description` are preloaded. They sit in the skill listing in **every session, in
every repo, forever**. The body costs nothing until the skill is actually invoked.

That asymmetry has a sharp consequence most authors miss. The listing has a character budget — about
1% of the context window — and **when it overflows, descriptions are dropped starting with the skills
invoked least**. A skill with no description left cannot be matched against a request, so it silently
stops triggering. Every marginal skill you ship makes every other skill's description more likely to
be cut, including the ones you rely on.

So: a skill that mostly restates what the model already knows is not free and not harmless. It is a
permanent tax paid by the skills that earn their place. Ship fewer, better.

Two more consequences worth designing around:

- The body enters the conversation once and **stays for the session; it is not re-read**. Write
  standing instructions that hold for the whole task, not a numbered procedure to be executed once
  and forgotten.
- After compaction only the first ~5,000 tokens of each recently-invoked skill are re-attached, under
  a shared budget. Put the load-bearing rule near the top, not in a closing summary.

## The description contract

Third person. Starts with `Use when`. States **triggering conditions only**.

The reason narration is banned is mechanical, not stylistic. The description is the part that is
always loaded, and the body is the part that is not. A description that summarizes the procedure gets
substituted for the body: the agent reads the summary, believes it now has the rule, and never opens
the file. A narrated description does not merely describe the skill badly — it reliably prevents the
skill from being read.

```yaml
# No — narrates the workflow, so it becomes the workflow
description: Reviews the diff, dispatches a reviewer per language, then reports findings by severity.

# Yes — states only when to reach for it
description: Use when reading a diff or pull request for defects, or when acting as the reviewer on a change you did not write.
```

Write the triggers in the words someone would actually use, including the ones that describe the
*situation* rather than the task — "a test fails", "behavior does not match expectation". Undertriggering
is the common failure, not overtriggering.

Put the primary case first: each listing entry is capped, and what is cut is the tail.

## Naming

Neutral skills are verb-first gerunds — `writing-tests`, `reviewing-code`. Stack skills carry the
stack as a prefix — `swift-testing`, `swift-logging`. Read together they say *discipline* and
*instantiation*, which is the whole architecture in two words.

A stack skill lives in its stack's plugin, `plugins/<stack>/skills/`, and is invoked under that
plugin's namespace — `vvkit-swift:swift-testing`. The split is what lets a project take only its stacks:
plugins install per project, but a single plugin skill cannot be hidden.

`name` must equal the containing directory. The invocation name falls back to the directory when the
field is absent, so a mismatch leaves the path saying one thing and the invocation another — a
cross-reference that looks right and resolves to nothing.

A stack skill opens with `**REQUIRED BACKGROUND:** vvkit:<neutral-skill>` and does not restate it.
Restating is how one rule ends up in three files that then drift apart, and the drift is invisible
until two of them contradict each other in front of a user.

## Earning a claim

Every assertion needs a measured number or a named failure mode behind it. "Prefer small functions"
is something the model already believes and does not need told. "200 owners produced 209
initialisations and 201 distinct objects" is a fact that changes what it does next.

If you cannot say how you know a claim is true, you are writing filler, and filler is what makes an
agent skim the whole file.

## Splitting into `references/`

Move material out when it exceeds roughly 100 lines, or when only a minority of invocations need it —
a field table, a full API surface, a long worked example.

Link it by **plain relative path**. Never with `@`: that pulls the file in whenever the skill loads,
which spends exactly the context the split was made to save. The point of a reference file is that it
is there when needed and absent when not.

See `references/frontmatter.md` for the frontmatter fields and the validator's full rule list.

When a skill's prose tells the agent to run a bundled script, name the interpreter —
`bash scripts/tool.sh`, not `scripts/tool.sh`. Some packagers strip executable bits, and a bare path
then fails with `Permission denied`.

## Test the behavior, not only the structure

The validator proves a skill is well-formed. It cannot prove the skill changes what an agent does,
and a skill that changes nothing is pure listing cost.

Before writing, give a fresh subagent the task that tempts the failure, **without** the skill, and
record what it does and the reasons it gives, verbatim. If it already behaves, there is nothing to
write — stop. Otherwise write guidance aimed at those specific reasons, re-run the same task with the
skill loaded, and repeat until it complies. A new rationalization in a re-run gets its own counter.

One sample misleads. Run each variant at least five times, and read wide disagreement between runs
as wording that does not yet bind.

Test a discipline skill under pressure, because that is where rules get broken. Combine three or
more: time (a deploy window closing), sunk cost (hours of work to throw away), authority (a senior
says skip it), exhaustion (the end of a long day), and the appeal of being pragmatic rather than
dogmatic. Make the scenario concrete — real paths, a forced choice between named options, "what do
you do?" rather than "what should you do?" — and give it no exit through "I would ask". Test other
kinds by use rather than by pressure: a technique on a new case, a reference by whether the right
entry gets found and applied.

For each rationalization the runs surface, close it where it appears: an explicit negation in the
rule itself, a row in a table pairing the excuse with the reality, and the thought as a red flag
the agent can recognize in itself. Then re-run; a counter that closes one loophole often opens the
next.

Match the form to the failure. A rule the agent breaks under pressure needs a prohibition and the
rationalizations it answers. Output of the wrong shape needs a recipe — what the output *is*, its
parts in order — because a prohibition on shape gets negotiated: in the superpowers plugin's own
wording tests, a prohibition produced more of the unwanted content than a recipe did.

## Before shipping

- [ ] `./scripts/validate.sh` exits 0
- [ ] `./scripts/validate.sh tests/fixtures` still exits 1 — a validator that passes everything is
      worse than none
- [ ] `claude plugin validate . --strict` exits 0
- [ ] **The version in `plugin.json` is bumped.** An installed plugin is cached per version, so
      content pushed without a bump never reaches an install — `marketplace update` reports success
      and changes nothing. This is silent, and it looks exactly like a skill that failed to load
- [ ] `claude plugin marketplace update vv-agent-kit && claude plugin details vvkit` shows the new
      component. This is the only check that reports what Claude Code actually discovered rather than
      what the layout suggests
- [ ] Every claim in the body is one you could source if asked
- [ ] A fresh subagent showed the failure without the skill, and did not show it with the skill

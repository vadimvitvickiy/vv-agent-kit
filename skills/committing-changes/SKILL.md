---
name: committing-changes
description: Use when writing a commit message, opening a pull request, or titling and describing a change for someone else to review.
---

# Committing changes

**The diff already shows what changed. Everything you write is for the why.** A message that
paraphrases the diff has spent the reader's attention to tell them something they were about to read
anyway.

## Never commit or push unasked

Staging is a commit's antechamber — `git add`, `git commit` and `git push` all wait for an explicit
request. "Finish the feature" is not one.

Before the first commit, **check the current branch**. Committing onto a checked-out default branch
is the one mistake that costs someone else time rather than yours: it bypasses the review the branch
existed to get. If you are on `main` or `master`, branch first.

## The subject line

```
<type>(<optional scope>): <description>
```

- **Imperative mood.** The test: the subject must complete the sentence *"If applied, this commit
  will ___"*. `add retry to the upload path`, not `added` or `adds`.
- **Around 50 characters**, and never past 72. No trailing period — the subject is a title.
- **Lowercase after the colon**, unless the first word is a proper noun or an identifier.
- The scope is a **noun naming a section of the codebase**, in parentheses: `fix(parser):`.

| Type | For |
|-|-|
| `feat` | A capability the codebase did not have |
| `fix` | A defect repaired |
| `refactor` | Behavior identical, structure different |
| `perf` | Behavior identical, measurably faster or smaller |
| `test` | Tests added or changed, with no production change |
| `docs` | Documentation only |
| `build`, `ci` | Build system, dependencies, pipeline |
| `chore` | Housekeeping that fits nothing above |

`feat` and `fix` are the two that carry meaning to a version number. If a change is really both, it is
really two commits.

## The body

One blank line after the subject, **wrapped at 72 characters**. That number is not arbitrary: `git
log` indents the message by four spaces, so 72 plus the indent is what still fits an 80-column
terminal without reflowing.

The body answers, in this order:

1. **What was wrong or missing** — the state that made this change necessary.
2. **Why this approach** — and what it rules out. The alternative you rejected is the single most
   useful sentence for whoever revisits this.
3. **What a reader would otherwise find surprising** — a measured number, a constraint discovered
   partway through, a workaround that is deliberately temporary.

Omit the body when the subject genuinely says everything: a typo fix, a version bump. Padding a
trivial commit with ceremony trains readers to skip bodies, including the ones that matter.

Breaking changes go in the type as `feat!:` or in a footer as `BREAKING CHANGE: <what breaks>`,
uppercase. Footers are `Token: value`, one per line, at the end.

## One logical change per commit

Not tidiness — instrumentation. A commit that mixes a rename with a behavior change makes `bisect`
land on a diff nobody can read, and the investigation stalls where it should have finished. See
`vvkit:debugging-systematically`.

The cost is paid once, when committing. It is collected months later, by whoever is bisecting.

## Pull request title

Same rules as a subject line, with one addition: **it must be readable with no other context**,
because it appears in release notes, in a merge queue, and in a list of thirty others.

| Weak | Strong |
|-|-|
| `Fix bug` | `fix: race in session cleanup that returned 502s under load` |
| `Update auth` | `feat(auth): accept refresh tokens issued by the new provider` |

The strong version tells a reviewer the problem, the component and the impact before they open a
single file. The weak one forces them to read the whole diff to learn what they are looking at.

## Pull request description

The description exists so a reviewer knows what to look for **before** they start reading. Four
parts, in this order:

1. **What changed** — the shape of the change in a few lines, grouped by area rather than by file.
   Not a restatement of the file list, which the diff already provides. Name the entry point so a
   reviewer knows where to start reading.
2. **Why** — the problem, and the approach chosen over which alternative.
3. **What was verified** — the commands actually run and what their output said. See
   `vvkit:verifying-changes`. "Tests pass" without a command is an assertion, not evidence.
4. **What is out of scope** — deliberately deferred work, and anything a reviewer would otherwise
   flag as missing.

Call out anything that needs a human decision: a schema change, a new dependency, a behavior change
users will notice, a deliberate workaround.

**Keep the change reviewable.** Review effectiveness falls off sharply past a few hundred changed
lines — beyond roughly 400, reviewers find *fewer* defects per line, because attention degrades and
reading turns into skimming. A description cannot rescue a diff that is too large to review; splitting
it can. If the change cannot be split, say so and tell the reviewer which parts deserve the attention.

## Never

- No AI attribution, in a message, a description, or a committed file.
- No ticket identifier in code comments — a PR footer is the right home for it.
- No "misc fixes", "wip", or "address feedback" as a final message. What feedback, and what changed?
- No description that restates the diff file by file. That is the diff's job, and it does it better.

## Before opening

- [ ] The subject completes *"If applied, this commit will ___"*
- [ ] Each commit is one logical change
- [ ] The body says why, not what
- [ ] The title reads correctly with no other context
- [ ] The description names what was verified, with the command
- [ ] The diff is small enough to actually be reviewed, or the split is explained

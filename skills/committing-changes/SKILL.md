---
name: committing-changes
description: Use when writing a commit message, opening a pull request, titling and describing a change for someone else to review, or deciding how to integrate a finished branch.
---

# Committing changes

**The diff shows what changed. Everything you write is for the why.**

## Ground rules

- **The repo's convention wins.** Read `git log --oneline -20` first; follow its prefixes, types,
  case and trailers. What follows is the default where it has none.
- **Never commit or push unasked.** `git add`, `git commit` and `git push` wait for an explicit
  request. "Finish the feature" is not one.
- **Check the branch first.** On `main` or `master`, branch — unless history shows the project commits
  there directly with no merges or PRs, and the human asked. Then say so.
- **One logical change per commit.** A rename mixed with a behavior change makes `bisect` land on an
  unreadable diff — `vvkit:debugging-systematically`.

## Subject line

```
<type>(<optional scope>): <description>
```

- **Imperative:** completes "If applied, this commit will ___". `add retry`, not `added`.
- **~50 characters, never past 72.** No trailing period.
- **Lowercase after the colon**, unless a proper noun or identifier.
- Scope is a noun naming a section of the codebase: `fix(parser):`.

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

Really both `feat` and `fix` means really two commits.

## Body

- Blank line after the subject, **wrapped at 72** — `git log` indents four spaces, so 72 fits 80
  columns.
- In order: **what was wrong or missing**; **why this approach**, and the alternative rejected — the
  most useful sentence for whoever revisits it; **what a reader would find surprising** — a measured
  number, a constraint found partway, a deliberate temporary workaround.
- Omit the body when the subject says it all. Ceremony on trivial commits trains readers to skip
  bodies.
- Breaking changes: `feat!:`, or a `BREAKING CHANGE: <what breaks>` footer. Footers are
  `Token: value`, one per line, at the end.

## Pull request

- **Title:** subject-line rules, and **readable with no other context** — it shows in release notes
  and merge queues. `fix: race in session cleanup that returned 502s under load`, not `Fix bug`.
- **Description**, in order:
  1. **What changed** — grouped by area, not file. Name the entry point to start reading from.
  2. **Why** — the problem, and the approach chosen over which alternative.
  3. **What was verified** — commands run and what they said — `vvkit:verifying-changes`. "Tests
     pass" without a command is an assertion.
  4. **Out of scope** — deferred work, and what a reviewer would otherwise flag as missing.
- Call out what needs a human decision: a schema change, a new dependency, a user-visible behavior
  change, a deliberate workaround.
- **Keep it reviewable.** Past ~400 changed lines reviewers find fewer defects per line. Split it, or
  say why not and point at the parts that deserve attention.

## Integrating a finished branch

Integration is the human's decision — present it, do not take it:

1. **Run the full suite on the tree about to be integrated.** Red: report and stop.
2. **Confirm the base branch** from the plan, the conversation or the upstream — or ask.
3. **Offer the options:** merge locally, push and open a PR, or keep the branch. Wait.

- A local merge is verified by the suite on the merged result before anything is deleted; on failure
  the branch and worktree stay. A PR keeps its worktree for review fixes.
- **Discard only when asked in so many words**, after the human confirms the exact list: branch,
  commits, worktree.
- Worktree removal refused over uncommitted files: those files exist nowhere else — show them and ask.
  Never `--force` on your own.
- A rejected push means the remote moved: investigate; force-push only on explicit request.
- Remove only worktrees you created.

## Never

- AI attribution, unless the project's instructions or its history's trailers carry it.
- A ticket id in code comments — a PR footer is its home.
- "misc fixes", "wip", "address feedback" as a final message.
- A description restating the diff file by file.

## Before opening

- [ ] The subject completes "If applied, this commit will ___"
- [ ] Each commit is one logical change
- [ ] The body says why, not what
- [ ] The title reads correctly with no other context
- [ ] The description names what was verified, with the command
- [ ] The diff is small enough to review, or the split is explained

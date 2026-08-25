# {{PROJECT_NAME}}

{{PROJECT_SUMMARY}}

## Critical rules

1. **Never commit or stage without an explicit request.**
2. **Present a plan before multi-step changes** and wait for approval.
3. **Fix the root cause, not the symptom.** No leaky flags, one-off special cases, or guards that
   mask bad state. A genuinely unavoidable workaround is labelled as one, with the real cause named.
4. **Never hand-edit generated files.** Regenerate them.

## Where agent content lives

One line: **`.claude/` is committed and reusable; `.agents/` is gitignored and disposable.**

| The question being asked | Location |
|-|-|
| What is always true here? | this file (`AGENTS.md` symlinks to it) |
| What's true when I touch *these files*? | `.claude/rules/*.md` — auto-loads on a `paths:` match |
| What are this repo's facts? | `.claude/context/` |
| What did we decide, and why? | `.claude/context/decisions.md` |
| What was the design? | `.claude/context/specs/` |
| Plans and todos for work in flight | `.agents/plans/` |
| Continuation and resume state | `.agents/state/` |
| Scratch, subagent reports, transcripts | `.agents/scratch/` |

Because `.agents/` is disposable by construction, anything that must outlive the session is
**promoted** into `.claude/context/`. See `kit:capturing-decisions`.

## Commands

```bash
{{BUILD_CMD}}   # build
{{TEST_CMD}}    # test
{{LINT_CMD}}    # lint
```

## Reference

| Doc | Read when |
|-|-|
| `.claude/context/structure.md` | Navigating the codebase; before fanning out searches |
| `.claude/context/decisions.md` | A choice looks arbitrary and you need the reasoning |

## Git

Working branch `{{WORKING_BRANCH}}`; release branch `{{MAIN_BRANCH}}`.

## Known debt

Recorded so it is not rediscovered, not scheduled.

# Using vvkit

The vvkit plugin's skills hold the working rules for the situations below. When one matches, load it
with the Skill tool **before your first action on it** — before reading files, running commands,
asking questions or proposing a fix — and follow it. The one-line description in the skill listing
says when a skill applies, not what it says; the rule is in the body. Load the skill even if you
think you remember it: skills change between versions.

| Situation | Skill |
|-|-|
| A change is asked for and the approach is not agreed yet | `vvkit:designing-changes` |
| An agreed design needs a plan, or a plan is being carried out or resumed | `vvkit:planning-changes` |
| A test fails, something errors, or behavior does not match expectation | `vvkit:debugging-systematically` |
| Adding or changing behavior, fixing a bug, or judging a test | `vvkit:writing-tests` |
| Deciding what to build or run, or about to say work is done, fixed or passing | `vvkit:verifying-changes` |
| Reviewing a diff, asking for a review, or receiving one | `vvkit:reviewing-code` |
| Work spans several files, or subagents are on the table | `vvkit:delegating-work` |
| A commit message, a pull request, or integrating a finished branch | `vvkit:committing-changes` |
| Starting in an unfamiliar repo, or locating code | `vvkit:exploring-a-codebase` |
| Writing a constructor, or adding a parameter as a test seam | `vvkit:injecting-dependencies` |
| Writing comments or doc comments | `vvkit:writing-comments` |
| Adding log statements, or choosing a log level | `vvkit:writing-logs` |
| A decision or rationale would otherwise be lost | `vvkit:capturing-decisions` |
| Editing a CLAUDE.md or AGENTS.md | `vvkit:writing-project-instructions` |
| Authoring a skill, agent, command or hook | `vvkit:writing-skills` |

Stack skills — `swift-*`, `xcode-builds` — add to the matching skill above; their descriptions say
when.

Several can match at once: load each. A skill loaded earlier in the session is still in context, so
do not load it again. Where the user's instructions or a project's CLAUDE.md conflict with a skill,
they win.

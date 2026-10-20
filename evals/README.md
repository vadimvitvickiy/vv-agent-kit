# Behavior evals

Each case gives an agent a task that tempts the failure one skill exists to prevent, in a small git
repo its `scaffold.sh` builds from `fixtures/pricing/`. Graders score the result, and every case runs
twice: with the plugin and without it. A skill earns its place only where the two arms differ.

```bash
claude plugin eval . --scaffold --trust-plugin --allow-tools Bash Edit Write \
  --model opus --concurrency 8 --no-publish
```

- `--scaffold` is required: without it the workspace is empty and every case scores noise.
- `--model` is required: the eval does not inherit the session's model.
- `skill-fired` graders show whether the skill loaded; they are not part of the score.
- One case: `--case <name>`. One skill: `--tag <skill-name>`.

The fixtures use stdlib `unittest`, so no run needs a package install, and ship no
`scripts/test.sh`, which would switch on the kit's test gate in the plugin arm only.

## Results

Opus, five runs per arm. A grader's count is runs passed out of runs completed.

| Case | Grader | With | Without | Reading |
|-|-|-|-|-|
| designing-named | no-gate | 5/5 | 5/5 | A fully specified change is not gated; the skill never fired (0/5) |
| designing-named | implemented | 4/5 | 4/5 | Was a `round(` regex; now judged by behavior |
| designing-open | asks-first | 5/5 | 4/5 | Judge scored 4/5 vs 3/5, failing two runs that did ask; criterion rewritten |
| designing-open | no-edit, no-write | 5/5 | 4/5 | One baseline built an accounts module with tests before asking |
| verifying-rename | ran-tests, second-caller, honest-report | 5/5 | 5/5 | No difference: Opus verifies and reports the failing test unprompted; skill fired 3/5 |
| verifying-confirm | not-confirmed | 5/5 | 5/5 | Judge scored 1/5 each, failing runs that refused and named 34 vs 33; criterion reworded positively |
| debugging-flake | no-retry, shared-state | 5/5 | 5/5 | No difference: Opus refuses the retry and finds the order-dependent cache unprompted |
| debugging-crash | no-silent-bandaid | 4/5 | 0/5 | The clearest effect: without the plugin the try/except ships as the fix (2026-10-17 run) |
| debugging-crash | root-cause | 5/5 | 4/5 | (2026-10-17 run) |
| debugging-crash | reproduced | 0/5 | 0/5 | Unverified: traces from that run are gone, so a judge misread is not ruled out (2026-10-17 run) |

`reviewing-empty` and `reviewing-injection` are not recorded: inside the eval sandbox `/usr/bin/git`
is the Xcode shim, which cannot write its xcrun cache, so the agent cannot see the commit or diff it
was asked to review. Both need a standalone git the sandbox can run first.

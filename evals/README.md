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

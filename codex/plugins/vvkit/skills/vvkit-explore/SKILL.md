---
name: vvkit-explore
description: "Use when refreshing a generated code map or checking architecture constraints."
---

Two artifacts, with a hard line between them.

| Artifact | Written by | Committed | Holds |
|-|-|-|-|
| `.agents/state/map.xml` | `scripts/map.sh` | no | Targets from ground truth, ranked type signatures |
| `.claude/context/architecture.md` | a human, or you | yes | Only what cannot be derived by reading code |

## Codex runtime

Load referenced skills by reading their SKILL.md. Surveyor, reviewer and runner
skills are role instructions, not registered agent types or enforced tool allowlists.
Use a generic subagent only when delegation is available and permitted; otherwise
perform the role inline. Follow the active session's model, context and permission
rules. User authorization takes precedence over imported workflow approval gates.
Claude hooks and plugin commands are not active in this package. Existing
`.claude/context/` paths refer to project documents, not Codex configuration.

**Never hand-write the map, and never put derivable facts in the doc.** Anthropic's own memory
guidance excludes directory layouts and file-by-file descriptions from always-loaded context on
exactly this basis: an agent can `ls` and `grep`, and a stale description is worse than none because
it is trusted.

## 1. Refresh the map

```bash
scripts/map.sh            # mtime-cached; a no-op when nothing changed
scripts/map.sh --force    # rebuild regardless
```

If `scripts/map.sh` does not exist, run `$vvkit-scripts` first.

Offer `scripts/map.sh --install-hook` once — a `post-commit` hook that refreshes the map in the
background. Without it the map drifts between manual runs, which is the failure mode that makes maps
harmful rather than merely useless.

## 2. Reconcile the constraints doc

Read `.claude/context/architecture.md` and check each claim against the code. This is the step that
matters — the doc is trusted precisely because nothing verifies it automatically.

| Claim | Verify by |
|-|-|
| A layering or dependency rule | The manifest, plus a grep for imports that would invert it |
| A frozen name | That the name still appears where the doc says, and the reason still holds |
| A generated-file entry | The generator config still names it as an output |
| A name mismatch | Both names still exist |
| Known drift | Re-count it. Drift gets fixed, and a fixed item left in the doc sends people looking for a bug that is gone |

Report every claim that no longer holds, with what you found. Correct them in place.

**Delete anything derivable** you find in the doc — a directory tree, a file count, a
what-each-folder-contains table. Those belong to `ls` and to the map.

## 3. Report

- What the map now covers: target count, how many files carried declarations, how many were omitted
  by the budget.
- Every architecture claim that failed verification, and what it was corrected to.
- Whether the post-commit hook is installed.

If nothing changed, say so in one line. A refresh that finds nothing is a good outcome, not a
failure to be padded.

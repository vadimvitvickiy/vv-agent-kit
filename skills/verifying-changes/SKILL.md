---
name: verifying-changes
description: Use when deciding what to build, run, or test after a change, and before claiming that work is complete, fixed, or passing.
---

# Verifying changes

**Evidence before assertions.** Never say complete, fixed, or passing without having run the command
and read its output.

## The cadence: scope while iterating, sweep at the end

Work out which suites the change can actually reach, and run those. Both ways of getting it wrong
cost real time:

- **Too wide.** A full sweep after every small fix spends minutes on targets the change cannot touch,
  and slows the edit-verify loop someone is watching.
- **Too narrow.** A compile-check when a suite does cover the change. Or scoping to one platform when
  the edit was in shared code that both platforms build. That is how a regression ships.

A compile-check alone is sufficient only when genuinely no test covers the change.

**Deleting or renaming affects every suite that references the symbol** — the blast radius is larger
than the diff suggests.

Run the full suite **once at the end**, as the final gate before reporting. Not as a per-edit check.

## Reporting honestly

- If tests fail, say so, and include the output.
- If a step was skipped, say which and why.
- If something is done and verified, state it plainly without hedging.
- If you could not verify something, say that rather than implying you did.

A confident summary over an unrun command is the single most expensive thing you can produce: it
ends the review that would have caught the problem.

## Read the structured result, not the raw log

On failure, prefer the machine-readable result — a result bundle, a JUnit XML, a test summary — over
grepping thousands of lines of console output. Raw logs bury the one failure among hundreds of lines
of progress noise, and grepping for `error` reliably finds the wrong ones.

## Know what your tooling silently misses

A green result is only as good as what the tool actually checked:

- Incremental builds keyed on source fingerprints can skip a resource-only change entirely.
- A focused test filter with a typo'd identifier runs **zero** tests and exits green.
- A suite that reports "0 failures" may also have run 0 tests. Read the count, not just the status.

When you rely on a cached or filtered run, name the gap rather than treating the green as complete
coverage.

## Before claiming done

- [ ] The command was actually run, in this session, after the last edit
- [ ] Its output was read, not assumed
- [ ] The test count is non-zero and matches expectation
- [ ] The full suite has been swept once, at the end
- [ ] Anything unverified is stated as unverified

---
name: verifying-changes
description: Use when deciding what to build, run, or test after a change, and before claiming that work is complete, fixed, or passing.
---

# Verifying changes

**Evidence before assertions.** Never say complete, fixed or passing without having run the command
and read its output.

## Scope while iterating, sweep at the end

- Run the suites the change can actually reach.
- **Too wide** — a full sweep per small fix — slows the loop someone is watching.
- **Too narrow** — a compile-check when a suite covers the change, or one platform when the edit was
  in shared code — is how a regression ships.
- A compile-check alone is enough only when no test covers the change.
- **A delete or rename reaches every suite that references the symbol**, not just the diff.
- Run the full suite **once at the end**, as the final gate. Not per edit.

## Report honestly

- Tests fail: say so, with the output — including failures you did not cause.
- A step skipped: say which and why.
- Done and verified: say it plainly, without hedging.
- Not verified: say that, never imply it.

A confident summary over an unrun command is the most expensive thing you can produce: it ends the
review that would have caught the problem.

## Read the result, not the log

- On failure, read the structured result — a result bundle, JUnit XML, a test summary — not
  thousands of console lines. Grepping for `error` reliably finds the wrong ones.
- **Read the count, not just the status.** A typo'd test filter runs zero tests and exits green;
  "0 failures" can mean 0 tests.
- Incremental builds keyed on source fingerprints can skip a resource-only change entirely.
- When relying on a cached or filtered run, name the gap.

## Passing is not done

- A green suite proves the code does what its tests check, not what was asked.
- Re-read the brief, plan or ticket and check each requirement against the diff. Tests written in the
  same change share the author's reading, so they cannot catch a misreading.

## Before claiming done

- [ ] The command was run in this session, after the last edit
- [ ] Its output was read, not assumed
- [ ] The test count is non-zero and matches expectation
- [ ] The full suite was swept once, at the end
- [ ] Each requirement in the brief, plan or ticket was checked against the diff
- [ ] Anything unverified is stated as unverified

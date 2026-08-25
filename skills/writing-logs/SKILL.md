---
name: writing-logs
description: Use when adding or reviewing log statements, or when deciding what level a message belongs at.
---

# Writing logs

Logs are read at 3am by someone who cannot reproduce the problem. Write for that reader.

Levels below use the common set — `trace`, `debug`, `info`, `warning`, `error`. Map them onto
whatever your stack calls them; the distinctions are what matter.

## Where a log belongs

| Code pattern | Log | Level |
|-|-|-|
| Public or internal method entry | The method name | `info` |
| Method exit, when there are several return paths | Which path was taken, before returning | `info` |
| Early return or failed precondition | The reason it failed, before returning | `debug` |
| Catch block | The error | `error` |
| Error callback or failure branch | The error | `error` |
| Conditional branch controlling flow | Which branch, with the state that decided it | `trace` |
| Network, IPC, or database call | Before the call, with its parameters | `debug` |
| State mutation others observe | The new value | `trace` |

## Choosing the level

| Level | For |
|-|-|
| `trace` | Filter evaluations, state checks, branch tracing |
| `debug` | Failed preconditions, outbound calls, operational detail |
| `info` | Method lifecycle, meaningful business events |
| `warning` | Unexpected but recovered |
| `error` | Catch blocks, error callbacks, unexpected nil where a value was required |

## Log the result at the consumer, not inside the producer

When logging the outcome of an operation — a model assembled, a response parsed, a view state built
— log at the **call site that consumes the result**. The producer is pure and does not know what the
result is for; the call site does.

## Log whole models, or don't log at all

Cherry-picking two fields of a result is noise. It is incomplete, it invites bikeshedding over which
fields matter, and it rots the moment the model grows a field.

Either the type carries a meaningful description worth logging in full, or the log adds nothing —
delete it.

## What not to log

- Property accessors and getters.
- Pure computations and pure factories that map input to output. The call site already logs the
  event that consumes the result.
- Destructors, unless they perform cleanup worth tracking.
- Layout methods. Far too noisy.
- Trivial single-line methods with no branching.

## Anti-patterns

- **No context.** A message reading "here" or "done" tells the 3am reader nothing.
- **Sensitive data.** Never log tokens, credentials, or personal data. Check every interpolation.
- **Wrong level.** A failure logged at `debug` is invisible exactly when it matters.
- **Missing the label or category.** An unlabelled line cannot be filtered out of a busy log.
- **Logging inside a pure factory.** Move it to the call site.

## Labels

Scan the file for an existing label or category and reuse it. Only when the file has no logs at all,
fall back to the enclosing type name. Inventing a second label for one file fragments the filter.

## Checklist

- [ ] New or modified methods log entry
- [ ] Every failed precondition logs its reason
- [ ] Every catch block and error callback logs the error
- [ ] Significant branches log which path was taken
- [ ] Outbound calls are logged before invocation
- [ ] Labels match what the file already uses
- [ ] No credentials, tokens, or personal data in any message

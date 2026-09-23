---
name: writing-logs
description: Use when adding or reviewing log statements, or when deciding what level a message belongs at.
---

# Writing logs

Logs are read at 3am by someone who cannot reproduce the problem. Write for that reader.

Levels below use the common set — `trace`, `debug`, `info`, `warning`, `error`. Map them onto
whatever your stack calls them; the distinctions are what matter.

## Where a log belongs

It depends on who reads the logs and how. **A policy the project already follows wins** — a logging
guide, or the density of the files around yours — over both tables below.

### An app or a library running on a device

Logs stay on the device until someone collects them, and there is rarely a trace to go with them.
The trail of method entries is the only reconstruction of what happened, so it is written densely.

| Code pattern | Log | Level |
|-|-|-|
| Public or internal method entry | The method name | `info` |
| Method exit, when there are several return paths | Which path was taken, before returning | `info` |
| Early return or failed precondition | The reason it failed, before returning | `debug` |
| Catch block | The error | `error` |
| Error callback or failure branch | The error | `error` |
| Conditional branch controlling flow | Which branch, with the state that decided it | `trace` |
| Network, IPC, or database call | Before the call, with identifying parameters | `debug` |
| State mutation others observe | The new value | `trace` |

### A service

Every line is multiplied by traffic, shipped, indexed and paid for. Method-entry logging at `info`
turns one request into dozens of lines that say less than one span would; where the service has
tracing, the trace is the trail.

| Event | Log | Level |
|-|-|-|
| A request or job completes | Route or job, outcome, duration | `info` |
| A request or job fails | The error, and the identifiers that locate the case — never the payload | `error` |
| A dependency call fails, retries or times out | The dependency, the attempt, the error | `warning` |
| An event someone will audit — an order placed, a permission changed | The event and the entity identifiers | `info` |
| A precondition or branch a trace cannot explain | Which one, and the state that decided it | `debug` |

Two rules hold on every service line:

- **Structured fields, not prose.** `user_id=42 outcome=denied` can be queried; a sentence can only
  be grepped, and the wording drifts.
- **Every line carries the request or correlation ID.** It is the only way to pull one request out
  of a million interleaved lines.

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
delete it. A model holding personal data or credentials is logged by identifier, or through a
description that redacts them.

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

## Stack-specific conventions

Logger APIs, privacy annotations and import rules live in the matching stack skill — for Swift,
`vvkit:swift-logging`.

## Checklist

- [ ] On a device: new or modified methods log entry. In a service: every request or job outcome
      is logged once, with its request ID, as structured fields
- [ ] Every failed precondition logs its reason
- [ ] Every catch block and error callback logs the error
- [ ] Significant branches log which path was taken
- [ ] Outbound calls are logged before invocation
- [ ] Labels match what the file already uses
- [ ] No credentials, tokens, or personal data in any message

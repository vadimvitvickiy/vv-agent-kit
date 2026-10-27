---
name: writing-logs
description: Use when adding or reviewing log statements, or when deciding what level a message belongs at.
---

# Writing logs

**Logs are read at 3am by someone who cannot reproduce the problem.** Write for that reader.

- Levels use the common set — `trace`, `debug`, `info`, `warning`, `error`. Map them onto your stack's
  names; the distinctions are what matter.
- **A logging policy the project already follows wins** — a guide, or the density of the files around
  yours — over both tables below.

## An app or library on a device

Logs stay on the device until collected, rarely with a trace. The trail of method entries is the only
reconstruction, so log densely.

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

## A service

Every line is multiplied by traffic, shipped, indexed and paid for. Where the service has tracing, the
trace is the trail — method-entry logging says less than one span.

| Event | Log | Level |
|-|-|-|
| A request or job completes | Route or job, outcome, duration | `info` |
| A request or job fails | The error, and the identifiers that locate the case — never the payload | `error` |
| A dependency call fails, retries or times out | The dependency, the attempt, the error | `warning` |
| An event someone will audit — an order placed, a permission changed | The event and the entity identifiers | `info` |
| A precondition or branch a trace cannot explain | Which one, and the state that decided it | `debug` |

- **Structured fields, not prose.** `user_id=42 outcome=denied` can be queried; a sentence only
  grepped, and its wording drifts.
- **Every line carries the request or correlation ID** — the only way to pull one request out of a
  million.

## Levels

| Level | For |
|-|-|
| `trace` | Filter evaluations, state checks, branch tracing |
| `debug` | Failed preconditions, outbound calls, operational detail |
| `info` | Method lifecycle, meaningful business events |
| `warning` | Unexpected but recovered |
| `error` | Catch blocks, error callbacks, unexpected nil where a value was required |

## Rules

- **Log a result at the consumer, not the producer.** The producer is pure and does not know what the
  result is for.
- **Whole models or nothing.** Two cherry-picked fields are incomplete and rot when the model grows.
  Log a meaningful description in full, or delete the line. Personal data or credentials: log by
  identifier, or through a redacting description.
- **Never log** accessors, pure computations and factories, destructors without cleanup worth
  tracking, layout methods, or trivial branchless one-liners.
- **Never** a context-free "here" or "done"; never tokens, credentials or personal data — check every
  interpolation; never a failure at `debug`, where it is invisible exactly when it matters.
- **Labels.** Every line carries a label or category. Reuse the file's existing one; only in a file
  with no logs, fall back to the enclosing type name. A second label for one file fragments the
  filter.

Logger APIs, privacy annotations and imports live in the stack skill — for Swift,
`vvkit-swift:swift-logging`.

## Checklist

- [ ] On a device: new or modified methods log entry. In a service: every request or job outcome is
      logged once, with its request ID, as structured fields
- [ ] Every failed precondition logs its reason
- [ ] Every catch block and error callback logs the error
- [ ] Significant branches log which path was taken
- [ ] Outbound calls are logged before invocation
- [ ] Labels match what the file already uses
- [ ] No credentials, tokens, or personal data in any message

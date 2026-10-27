---
name: writing-comments
description: Use when writing or reviewing comments and doc comments, or when a diff adds explanatory prose alongside code.
---

# Writing comments

**The default is no comment.** Names and structure carry the meaning; a comment is for what they
provably cannot. Where the project has a convention, follow the project.

## The one test

- A comment answers **why**, and the why is not obvious from the code beside it.
- Describes *what* the code does: delete it. Recoverable from the next three lines: delete it.
- Code that needs a comment to be followed needs a better name or a smaller function instead.

## Limits

| Kind | Limit |
|-|-|
| Line comment | **1 line** |
| Member doc comment (function, property, case) | **1 line.** A second only for a genuinely subtle exception |
| Type-level doc comment (class, struct, enum, protocol, module) | Several lines, to orient a reader about the whole type |

Over the limit means **cut, not reflow** — the second sentence usually restates the first.

## Never

- **Narrate** — "loop over the items", "set the title", "returns nil when empty".
- **Restate the signature** — a parameter doc repeating the name and type.
- **Decorative dividers.** A structured section marker the language supports is fine.
- **Migration history** — "moved from X", "new in the refactor". Git knows.
- **Ticket ids.** In public API docs they leak an internal tracker.
- **Commentary on the change.** Describe the code as it stands, not how it got there.

## When a doc comment is warranted

| Declaration | Doc comment |
|-|-|
| Public or exported | **Yes** — it is the contract, and exempt from the member limit where the contract needs the words |
| Internal helper with a non-obvious exception | Yes — one line naming the exception |
| Internal helper self-evident from its name | No |
| Override or conformance with no added behavior | No |
| A constant whose value encodes a decision | Yes — why *this* value |

## Existing comments

- **Never delete an existing comment or TODO** unless asked. These rules govern what you write, not
  what you remove.
- **Never overwrite an existing doc comment.** Add where missing; reconcile only when the contract
  changed.

## Self-check

Every multi-line comment block you just added:

```bash
git diff -U0 | awk '/^\+ *(\/\/|#|--)/{n++; if (n>1) print; next} {n=0}'
```

Empty output, or only type-level overviews, passes. Anything else is over the limit until you can
name why that block earns a second line.

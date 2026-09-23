---
paths:
  - "**/*.swift"
---

# Comments

The default is **no comment**. A comment answers *why*, and only when the why is non-obvious from
the code beside it.

| Kind | Limit |
|-|-|
| `//` | 1 line |
| `///` on a member | 1 line; a second only for a genuinely subtle exception |
| `///` above a type | Several lines, to orient the reader |

Over the limit means cut, not reflow.

Never write migration history, ticket ids, or commentary on the change. Never delete an existing
comment or TODO unless asked — this rule constrains what you write, not what you remove.

Full rule, the doc-comment table and the diff self-check: `vvkit:writing-comments`.

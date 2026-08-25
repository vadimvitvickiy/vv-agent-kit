---
paths:
  - "**/*.swift"
---

# Swift style

Member order: imports → nested types → **injected dependencies** → `init` → **private state** →
public methods → private methods → extensions. Dependencies precede `init`; working state follows it.

Prefer `if` / `else` over `guard` for top-of-function branching when both branches carry real logic.
Keep `guard let x else { … }` for optional unwraps.

Keep `if` / `guard` / `else` bodies on their own lines. Do not collapse `{ return x }` onto one line.

Full order, annotated example, section labels and carve-outs: `kit:swift-style`.
